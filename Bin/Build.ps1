#Requires -Version 3.0
#Requires -Modules Invoke-MsBuild

<#
.SYNOPSIS
Build script for EnVar Plugin for NSIS.

.DESCRIPTION
This script helps to build the plugin and it's distribution

.PARAMETER Step
Optional. Defines one or more build steps to perform.

Remove-Build
  Remove the build folders Lib and Obj

Update-Build
  Compile the plugin

New-Build
  Execute Remove-Build and Update-Build

Remove-Distribution
  Remove Data\EnVar-Plugin.zip and the folder Dist

Update-Distribution
  Copy the files for the distribution to the folder Dist

New-Distribution
  Execute Remove-Distribution and Update-Distribution

Compress-Distribution
  Compress the folder Dist to Data\EnVar-Plugin.zip

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
Bin\Build

Build the plugin and create the distribution.

.EXAMPLE
Bin\Build New-Build

Clean the build folders and compile the plugin.

.EXAMPLE
Bin\Build Compress-Distribution

Create EnVar-Plugin.zip from the Dist folder.

.EXAMPLE
Bin\Build Update-Build, New-Distribution, Compress-Distribution

Compile the plugin, update the Dist folder and create EnVar-Plugin.zip from the 
Dist folder.

.LINK
Project home: https://github.com/GsNSIS/EnVar

#>

Param(
    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$true,
        Position=0
    )]
    [string[]]
    $Step
)

function Remove-Build
{
    Write-Output "Cleanup build..."

    if (Test-Path -Path "$PSScriptRoot\..\Lib") {
        Remove-Item -Path "$PSScriptRoot\..\Lib" -Force -Recurse
    }

    if (Test-Path -Path "$PSScriptRoot\..\Obj") {
        Remove-Item -Path "$PSScriptRoot\..\Obj" -Force -Recurse
    }
}

function Update-Build
{
    Write-Output "Update build..."

    $BuildResults = @()
    $Configurations = "Release", "Release Unicode"
    $Platforms = "x86", "x64"

    foreach ($Configuration in $Configurations) {
        foreach ($Platform in $Platforms) {
            if (($Configuration -notmatch "Unicode") -and ($Platform -eq "x64")) {
                Continue
            }

            Write-Output "- Creating $Configuration for $Platform"
            Write-Output ""
            $BuildResults += Invoke-MsBuild "$PSScriptRoot\..\EnVar.sln" -MsBuildParameters "/p:Configuration=`"$Configuration`" /p:Platform=`"$Platform`""
            Write-Output ""
        }
    }

    return $BuildResults
}

function New-Build
{
    Remove-Build
    Update-Build
}

function Remove-Distribution
{
    Write-Output "Cleanup distribution..."
    if (Test-Path -Path "$PSScriptRoot\..\Data\EnVar-Plugin.zip") {
        Remove-Item -Path "$PSScriptRoot\..\Data\EnVar-Plugin.zip" -Force
    }
    if (Test-Path -Path "$PSScriptRoot\..\Dist") {
        Remove-Item -Path "$PSScriptRoot\..\Dist" -Force -Recurse
    }
}

function Update-Distribution
{
    Write-Output "Copy source files..."
    New-Item -ItemType "directory" -Path "$PSScriptRoot\..\Dist\Contrib\EnVar" -Force | Out-Null
    Copy-Item -Path "$PSScriptRoot\..\Src", "$PSScriptRoot\..\EnVar.*" -Destination "$PSScriptRoot\..\Dist\Contrib\EnVar\" -Force -Recurse
    
    Write-Output "Copy doc files..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Docs\EnVar" -Force | Out-Null
    Copy-Item -Path "$PSScriptRoot\..\LICENSE", "$PSScriptRoot\..\README.md" -Destination "$PSScriptRoot\..\Dist\Docs\EnVar\" -Force
    
    Write-Output "Copy example files..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Examples\EnVar" -Force | Out-Null
    Copy-Item "$PSScriptRoot\..\Docs\example.nsi" -Destination "$PSScriptRoot\..\Dist\Examples\EnVar\" -Force
    
    Write-Output "Copy dll files..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Plugins\amd64-unicode", "$PSScriptRoot\..\Dist\Plugins\x86-ansi", "$PSScriptRoot\..\Dist\Plugins\x86-unicode" -Force | Out-Null
    Copy-Item "$PSScriptRoot\..\Lib\Win32\Release\EnVar.dll" -Destination "$PSScriptRoot\..\Dist\Plugins\x86-ansi\" -Force
    Copy-Item "$PSScriptRoot\..\Lib\Win32\Release Unicode\EnVar.dll" -Destination "$PSScriptRoot\..\Dist\Plugins\x86-unicode\" -Force
    Copy-Item "$PSScriptRoot\..\Lib\x64\Release Unicode\EnVar.dll" -Destination "$PSScriptRoot\..\Dist\Plugins\amd64-unicode\" -Force
}

function New-Distribution
{
    Remove-Distribution
    Update-Distribution
}

function Compress-Distribution
{
    Write-Output "Compress distribution..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Data" -Force | Out-Null
    Compress-Archive -Path "$PSScriptRoot\..\Dist\*" -DestinationPath "$PSScriptRoot\..\Data\EnVar-Plugin.zip" -Force
}

function Write-Usage {
    Get-Help $MyInvocation.PSCommandPath -Full
}


#----------------------------------------------------------------------------
# Build Entry Point
#----------------------------------------------------------------------------

#Import-Module "$PSScriptRoot\BuildUtility"

if ($Step.Count -eq 0) {
    # Perform default build steps
    New-Build
    New-Distribution
    Compress-Distribution
} else {
    $StepMatch = $false
    
    # Execute the steps in the user given order
    foreach ($SingleStep in $Step) {
        switch ($Step)
        {
            {"Remove-Build" -match $_} {
                $StepMatch = $true
                Remove-Build
            }
            {"Update-Build" -match $_} {
                $StepMatch = $true
                Update-Build
            }
            {"New-Build" -match $_} {
                $StepMatch = $true
                New-Build
            }
            {"Remove-Distribution" -match $_} {
                $StepMatch = $true
                Remove-Distribution
            }
            {"Update-Distribution" -match $_} {
                $StepMatch = $true
                Update-Distribution
            }
            {"New-Distribution" -match $_} {
                $StepMatch = $true
                New-Distribution
            }
            {"Compress-Distribution" -match $_} {
                $StepMatch = $true
                Compress-Distribution
            }
            Default {
                Write-Output ("Step '" + $_ + "' is unknown!")
            }
        }
    }
    
    # Show usage if no valid step was provided
    if (!$StepMatch) {
        Write-Usage
    }
}
