#Requires -Version 3.0
#Requires -Modules Invoke-MsBuild

<#
.SYNOPSIS
Build script for EnVar Plugin for NSIS.

.DESCRIPTION
Brief description of script

.PARAMETER Step
Brief description of parameter input required. Repeat this attribute if required

.INPUTS
None.

.OUTPUTS
None.

.NOTES
Version:        1.0
Author:         Simon Gilli
Creation Date:  28.11.2019
Purpose/Change: Initial script development
  
.EXAMPLE
            {"Build-Plugin" -match $_} {
                $StepMatch = $true
                Build-Plugin
            }
            {"Remove-Distribution" -match $_} {
                $StepMatch = $true
                Remove-Distribution
            }
            {"Initialize-Distribution" -match $_} {
                $StepMatch = $true
                Initialize-Distribution
            }
            {"Compress-Distribution" -match $_} {
                $StepMatch = $true
                Compress-Distribution
            }
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

    $Configurations = "Release", "Release Unicode"
    $Platforms = "x86", "x64"

    foreach ($Configuration in $Configurations) {
        foreach ($Platform in $Platforms) {
            if (($Configuration -notmatch "Unicode") -and ($Platform -eq "x64")) {
                Continue
            }

            Write-Output "- Creating $Configuration for $Platform"
            Write-Output ""
            Invoke-MsBuild "$PSScriptRoot\..\EnVar.sln" -MsBuildParameters "/p:Configuration=`"$Configuration`" /p:Platform=`"$Platform`""
            Write-Output ""
        }
    }
}

function New-Build
{
    Remove-Build
    Update-Build
}

function Remove-Distribution
{
    Write-Output "Cleanup distribution..."
    if (Test-Path -Path "$PSScriptRoot\..\Dist") {
        Remove-Item -Path "$PSScriptRoot\..\Dist" -Force -Recurse
    }
}

function Update-Distribution
{
    Write-Output "Copy source files..."
    New-Item -ItemType "directory" -Path "$PSScriptRoot\..\Dist\Contrib\EnVar" -Force | Out-Null
    Copy-Item -Path "$PSScriptRoot\..\Src", "$PSScriptRoot\..\EnVar.*" -Destination "$PSScriptRoot\..\Dist\Contrib\EnVar\" -Force -Recurse
    #Copy-Item "$PSScriptRoot\..\EnVar.*" -Destination "$PSScriptRoot\..\Dist\Contrib\EnVar\" -Force
    
    Write-Output "Copy doc files..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Docs\EnVar" -Force | Out-Null
    Copy-Item -Path "$PSScriptRoot\..\LICENSE", "$PSScriptRoot\..\README.md" -Destination "$PSScriptRoot\..\Dist\Docs\EnVar\" -Force
    #Copy-Item "$PSScriptRoot\..\README.md" -Destination "$PSScriptRoot\..\Dist\Docs\EnVar\" -Force
    
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
