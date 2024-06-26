<#
.SYNOPSIS
Downloads YAML files from the Azure Sentinel GitHub repository, converts them to JSON, and saves them locally in their original folder structure.

.DESCRIPTION
This script downloads analytic rule YAML files from the Azure Sentinel GitHub repository, converts them to JSON using the SentinelARConverter module, and saves the converted files to a specified directory.

.PARAMETER RepoUrl
The URL of the GitHub repository to clone or pull updates from.

.PARAMETER SourceRoot
The local path where the repository content will be stored.

.PARAMETER DestinationRoot
The local path where the converted JSON files will be saved.

.PARAMETER NoARfolders
Shows all folders which do not contain any Analytic Rules by adding -NoARfolders

.EXAMPLE
.\Convert-YamlToJson.ps1 -RepoUrl "https://github.com/Azure/Azure-Sentinel" -SourceRoot "C:\temp\Azure-sentinel\Solutions" -DestinationRoot "C:\Convertedrules"
#>

param (
    [string]$RepoUrl = "https://github.com/Azure/Azure-Sentinel",
    [string]$SourceRoot = "$($pwd.Path)\temp\Azure-sentinel\Solutions",
    [string]$DestinationRoot,
    [switch]$NoARfolders
)

# Get the current date
$currentDate = (Get-Date).ToString("dd-MM-yyyy")

# Set the DestinationRoot to include the current date in the folder name
$DestinationRoot = "$($pwd.Path)\Converted_rules_$currentDate"

# Display ASCII Art Header
$asciiArt = @"
 __  __               _____    _____           __     __             __  __   _                 _______    ____                  _    _____    ____    _   _ 
|  \/  |     /\      / ____|  / ____|          \ \   / /     /\     |  \/  | | |               |__   __|  / __ \                | |  / ____|  / __ \  | \ | |
| \  / |    /  \    | (___   | (___    ______   \ \_/ /     /  \    | \  / | | |       ______     | |    | |  | |  ______       | | | (___   | |  | | |  \| |
| |\/| |   / /\ \    \___ \   \___ \  |______|   \   /     / /\ \   | |\/| | | |      |______|    | |    | |  | | |______|  _   | |  \___ \  | |  | | | . ` |
| |  | |  / ____ \   ____) |  ____) |             | |     / ____ \  | |  | | | |____              | |    | |__| |          | |__| |  ____) | | |__| | | |\  |
|_|  |_| /_/    \_\ |_____/  |_____/              |_|    /_/    \_\ |_|  |_| |______|             |_|     \____/            \____/  |_____/   \____/  |_| \_|
"@

Write-Host $asciiArt -ForegroundColor Cyan

# Check if Git is installed
try {
    $gitVersion = git --version
    if ($gitVersion) {
        Write-Host "Git is already installed. Version: $gitVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "Git is not installed. Please install Git before proceeding" -ForegroundColor Red
    Exit
}

# Check if SentinelARConverter module is installed
if (-not (Get-Module -ListAvailable -Name SentinelARConverter)) {
    $userResponse = Read-Host "SentinelARConverter is not installed. Do you want to install it? (Y/N)"
    if ($userResponse -eq 'y' -or $userResponse -eq 'Y') {
        Write-Host "Installing SentinelARConverter module from the PowerShell Gallery..." -ForegroundColor Yellow
        try {
            Install-Module -Name SentinelARConverter -Force -ErrorAction Stop
            Import-Module SentinelARConverter
        } catch {
            Write-Host "Failed to install SentinelARConverter module. Reason: $_ " -ForegroundColor Red
            Exit
        }
    } else {
        Write-Host "Module required to proceed. Exiting script." -ForegroundColor Red
        Exit
    }
} else {
    Write-Host "SentinelARConverter module is already installed." -ForegroundColor Green
}

# Variables
$gitRoot = "$($pwd.Path)\temp\Azure-sentinel"
$successfulYamlToJsonConversions = 0
$failedConversions = 0

# Prepare environment
if (Test-Path $SourceRoot) {
    Write-Host "Repository already exists. Pulling latest changes..." -ForegroundColor Green
    git -C $gitRoot pull --quiet
} else {
    Write-Host "Cloning repository and converting analytic rules...Have some coffee!" -ForegroundColor Green
    git clone $RepoUrl --quiet --depth 1 --filter=blob:none --sparse $gitRoot
}

# Switch to the repository folder
Push-Location $gitRoot

# Set up sparse checkout for the specified folders
$SubFolders = @("Solutions")

# Count total files to process for progress bar
$totalFiles = 0
foreach ($Folder in $SubFolders) {
    git sparse-checkout set $Folder
    $fullPath = Join-Path -Path $gitRoot -ChildPath $Folder
    $solutions = Get-ChildItem -Directory -Path $fullPath
    foreach ($solution in $solutions) {
        $folderPath = if ($Folder -eq 'Solutions') {
            Join-Path -Path $fullPath -ChildPath "$($solution.Name)\Analytic Rules"
        } else {
            Join-Path -Path $fullPath -ChildPath $solution.Name
        }
        if (Test-Path $folderPath) {
            $yamlFileNames = Get-ChildItem -Path $folderPath -Filter "*.yaml" -Recurse | ForEach-Object { $_.FullName }
            $totalFiles += $yamlFileNames.Count
        }
    }
}

# Process the files and update progress
$filesProcessed = 0
foreach ($Folder in $SubFolders) {
    git sparse-checkout set $Folder
    $fullPath = Join-Path -Path $gitRoot -ChildPath $Folder
    $solutions = Get-ChildItem -Directory -Path $fullPath
    foreach ($solution in $solutions) {
        $folderPath = if ($Folder -eq 'Solutions') {
            Join-Path -Path $fullPath -ChildPath "$($solution.Name)\Analytic Rules"
        } else {
            Join-Path -Path $fullPath -ChildPath $solution.Name
        }
        if (-not (Test-Path $folderPath)) {
            if ($NoARfolders) {
            Write-Host -ForegroundColor Yellow "No analytic rules found for $($solution.Name)"
            }
            continue
        }
        $yamlFileNames = Get-ChildItem -Path $folderPath -Filter "*.yaml" -Recurse | ForEach-Object { $_.FullName }
        foreach ($item in $yamlFileNames) {
            try {
                $filesProcessed++
                $progressPercent = [math]::Round(($filesProcessed / $totalFiles) * 100)
                Write-Progress -Activity "Converting YAML to JSON" -Status "Processing file $filesProcessed of $totalFiles" -PercentComplete $progressPercent

                $relativeFolderPath = (Split-Path $item).Substring($fullPath.Length)
                $destinationFolderPath = Join-Path -Path $DestinationRoot -ChildPath $relativeFolderPath
                $destinationFileName = [System.IO.Path]::ChangeExtension((Split-Path $item -Leaf), ".json")
                $destinationFilePath = Join-Path -Path $destinationFolderPath -ChildPath $destinationFileName

                if (-not (Test-Path $destinationFolderPath)) {
                    New-Item -ItemType Directory -Path $destinationFolderPath -Force | Out-Null
                }
                Get-Content -Path $item | Convert-SentinelARYamlToArm -OutFile $destinationFilePath
                $successfulYamlToJsonConversions++
            } catch {
                $failedConversions++
                
            }
        }
    }
}

# Summarize conversions
Write-Host ""
Write-Host "Conversion Summary:" -ForegroundColor Cyan
Write-Host "Successfully converted YAML to JSON: $successfulYamlToJsonConversions" -ForegroundColor Green
Write-Host "Failed conversions: $failedConversions" -ForegroundColor Red

Pop-Location
