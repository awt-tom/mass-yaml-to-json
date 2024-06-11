
---

# Convert-YamlToJson.ps1 Script Documentation

## Why this script

Throughout the years I have learned alot from the Security community and love to give something back to the community! 

I can see that many organizations leveled up and done this all through pipelines where others are willing to start, but do not always know where to start. 
With this script I hope I can encourage many more people to start automate their Sentinel Analytic rule management and being able to import many more detection rules in order to find incidents within their environments.

## Overview

This PowerShell script automates the process of downloading YAML files from the Azure Sentinel GitHub repository which contain analytic rules, converting them to JSON format, and saving them locally in their original folder structure. This way the rules can straightup be used to import in Microsoft Sentinel.
Adding the rules to for example Azure Devops makes it possible to deploy all the analytic rules at once.

Huge credit to [Fabian Bader](https://github.com/f-bader) for creating the powershell module SentinelARConverter which is being used in the script.

## Synopsis

**Standard run**
```powershell
.\Convert-YamlToJson.ps1
```
**Show folders without Analytic Rules inside them**
```powershell
.\Convert-YamlToJson.ps1 -NoARfolders
```
**Define other locations (Make sure to have the correct path/repo)**
```powershell
.\Convert-YamlToJson.ps1 -RepoUrl "https://github.com/Azure/Azure-Sentinel" -SourceRoot "C:\temp\Azure-sentinel\Solutions" -DestinationRoot "C:\Convertedrules"
```

## Description

The script performs the following tasks:

1. **Clones or updates** the specified Azure Sentinel GitHub repository.
2. **Converts YAML files** related to analytic rules into JSON format.
3. **Saves the JSON files** to a specified local directory, maintaining the original folder structure.

Optionally, the script can display folders that do not contain any analytic rules.

## Parameters

- **`-RepoUrl`**: The URL of the GitHub repository to clone or pull updates from.
  - Type: `string`
  - Default: `"https://github.com/Azure/Azure-Sentinel"`

- **`-SourceRoot`**: The local path where the repository content will be stored.
  - Type: `string`
  - Default: `"$($pwd.Path)\temp\Azure-sentinel\Solutions"`

- **`-DestinationRoot`**: The local path where the converted JSON files will be saved.
  - Type: `string`
  - Default: Current working directory appended with `Converted_rules_<current_date>`

- **`-NoARfolders`**: Shows all folders that do not contain any Analytic Rules.
  - Type: `switch`

## Example

```powershell
.\Convert-YamlToJson.ps1 -RepoUrl "https://github.com/Azure/Azure-Sentinel" -SourceRoot "C:\temp\Azure-sentinel\Solutions" -DestinationRoot "C:\Convertedrules"
```

## Prerequisites

- **Git**: Ensure that Git is installed and available in the system path.
- **PowerShell Execution Policy**: The execution policy must allow running scripts. Use `Set-ExecutionPolicy` if necessary.
- **SentinelARConverter Module**: This script requires the `SentinelARConverter` module from the PowerShell Gallery. The script will attempt to install it if it is not found.

### Installing Git

1. Download Git from [git-scm.com](https://git-scm.com/).
2. Follow the installation instructions specific to your operating system.
3. Ensure that Git is working. Restart your terminal to apply


## Supported Terminals

The script can be run in various PowerShell-enabled environments, including:

- **Windows PowerShell**: The default PowerShell environment in Windows.
- **Windows Terminal**: A modern terminal application from Microsoft that supports multiple tabs and customizable profiles.
- **Visual Studio Code**: A powerful source code editor that can run PowerShell scripts using the integrated terminal or the PowerShell extension.
- **PowerShell ISE (Integrated Scripting Environment)**: A graphical host for PowerShell that is included with Windows.

## Script Details

### ASCII Art Header

Displays a stylized title in the terminal for visual emphasis.

### Git Check and Installation

Checks if Git is installed. If not, prompts the user to install Git.

### SentinelARConverter Module Check and Installation

Checks if the `SentinelARConverter` module is installed. If not, prompts the user to install it from the PowerShell Gallery.

### Cloning or Updating the Repository

- If the repository already exists at the specified source root, it pulls the latest changes.
- If the repository does not exist, it clones the repository.

### Converting YAML to JSON

- Iterates through the repository folders.
- Converts YAML files to JSON format using `Convert-SentinelARYamlToArm`.
- Saves the JSON files to the specified destination root, creating necessary directories as needed.

### Logging and Progress

- Displays a progress bar during the conversion process.
- Optionally shows folders that do not contain any analytic rules.

### Summarizing Results

- Prints a summary of successful and failed conversions to the terminal.

## Let me know!

Found anything that is wrong, an improvement or did you manage to grab a whole bunch of Analytic Rules? Let me know!


