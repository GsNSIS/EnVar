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

Test-Plugin
  Compiles and runs the test installer

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
    Write-Host "Cleanup build..."

    if (Test-Path -Path "$PSScriptRoot\..\Lib") {
        Remove-Item -Path "$PSScriptRoot\..\Lib" -Force -Recurse
    }

    if (Test-Path -Path "$PSScriptRoot\..\Obj") {
        Remove-Item -Path "$PSScriptRoot\..\Obj" -Force -Recurse
    }
}

function Update-Build
{
    Write-Host "Update build..."

    $BuildResults = @()
    $Configurations = "Release", "Release Unicode"
    $Platforms = "x86", "x64"

    foreach ($Configuration in $Configurations) {
        foreach ($Platform in $Platforms) {
            if (($Configuration -notmatch "Unicode") -and ($Platform -eq "x64")) {
                Continue
            }

            Write-Host " - Creating $Configuration for $Platform " -NoNewline
            $BuildResult = Invoke-MsBuild "$PSScriptRoot\..\EnVar.sln" -MsBuildParameters "/p:Configuration=`"$Configuration`" /p:Platform=`"$Platform`""

            if ($BuildResult.BuildSucceeded) {
                Write-Host "succeeded"
            } else {
                Write-Host "failed"
            }

            $BuildResults += $BuildResult
        }
    }

    #return $BuildResults
}

function New-Build
{
    Remove-Build
    Update-Build
}

function Remove-Distribution
{
    Write-Host "Cleanup distribution..."

    if (Test-Path -Path "$PSScriptRoot\..\Data\EnVar-Plugin.zip") {
        Remove-Item -Path "$PSScriptRoot\..\Data\EnVar-Plugin.zip" -Force
    }

    if (Test-Path -Path "$PSScriptRoot\..\Dist") {
        Remove-Item -Path "$PSScriptRoot\..\Dist" -Force -Recurse
    }
}

function Update-Distribution
{
    Write-Host "Copy source files..."
    New-Item -ItemType "directory" -Path "$PSScriptRoot\..\Dist\Contrib\EnVar" -Force | Out-Null
    Copy-Item -Path "$PSScriptRoot\..\Src", "$PSScriptRoot\..\EnVar.*" -Destination "$PSScriptRoot\..\Dist\Contrib\EnVar\" -Force -Recurse
    
    Write-Host "Copy doc files..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Docs\EnVar" -Force | Out-Null
    Copy-Item -Path "$PSScriptRoot\..\LICENSE", "$PSScriptRoot\..\README.md" -Destination "$PSScriptRoot\..\Dist\Docs\EnVar\" -Force
    
    Write-Host "Copy example files..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Examples\EnVar" -Force | Out-Null
    Copy-Item "$PSScriptRoot\..\Docs\example.nsi" -Destination "$PSScriptRoot\..\Dist\Examples\EnVar\" -Force
    
    Write-Host "Copy dll files..."
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
    Write-Host "Compress distribution..."
    New-Item -ItemType "directory" "$PSScriptRoot\..\Data" -Force | Out-Null
    Compress-Archive -Path "$PSScriptRoot\..\Dist\*" -DestinationPath "$PSScriptRoot\..\Data\EnVar-Plugin.zip" -Force
}

function Deploy-Plugin
{
    Write-Host "Deploy plugin..."

    Copy-Item "$PSScriptRoot\..\Lib\Win32\Release\EnVar.dll" -Destination "${Env:ProgramFiles(x86)}\NSIS\Plugins\x86-ansi\" -Force
    Copy-Item "$PSScriptRoot\..\Lib\Win32\Release Unicode\EnVar.dll" -Destination "${Env:ProgramFiles(x86)}\NSIS\Plugins\x86-unicode\" -Force
    #Copy-Item "$PSScriptRoot\..\Lib\x64\Release Unicode\EnVar.dll" -Destination "${Env:ProgramFiles(x86)}\NSIS\Plugins\amd64-unicode\" -Force
}

function Build-PluginTest
{
    Write-Host "Build PluginTest installer..."

    if (Test-Path -Path "$PSScriptRoot\..\Tests\PluginTest.exe") {
        Remove-Item -Path "$PSScriptRoot\..\Tests\PluginTest.exe" -Force
    }

    #$Env:NSISDIR = "$PSScriptRoot\..\Dist"
    $build = Start-Process -FilePath "${Env:ProgramFiles(x86)}\NSIS\makensis.exe" -ArgumentList "$PSScriptRoot\..\Tests\PluginTest.nsi" -Wait -PassThru

    if ($build.ExitCode -eq 0) {
        Write-Host "Build succeeded"
    } else {
        $ExitCode = $build.ExitCode
        Throw "Build failed with $ExitCode"
    }
}
function Start-PluginTest
{
    Write-Host "Test plugin..."

    $result = Start-Process -FilePath "$PSScriptRoot\..\Tests\PluginTest.exe" -ArgumentList "/S" -Wait -PassThru

    if ($result.ExitCode -eq 0) {
        Write-Host "Tests succeeded"
    } else {
        $ExitCode = $result.ExitCode
        Throw "Tests failed with $ExitCode"
    }
}

function Test-Plugin
{
    Deploy-Plugin
    Build-PluginTest
    Start-PluginTest
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
    Test-Plugin
} else {
    $StepFailure = $false
    
    # Execute the steps in the user given order
    foreach ($SingleStep in $Step) {
        switch ($Step)
        {
            {"Remove-Build" -match $_} {
                Remove-Build
            }
            {"Update-Build" -match $_} {
                Update-Build
            }
            {"New-Build" -match $_} {
                New-Build
            }
            {"Remove-Distribution" -match $_} {
                Remove-Distribution
            }
            {"Update-Distribution" -match $_} {
                Update-Distribution
            }
            {"New-Distribution" -match $_} {
                New-Distribution
            }
            {"Compress-Distribution" -match $_} {
                Compress-Distribution
            }
            {"Deploy-Plugin" -match $_} {
                Deploy-Plugin
            }
            {"Build-PluginTest" -match $_} {
                Build-PluginTest
            }
            {"Start-PluginTest" -match $_} {
                Start-PluginTest
            }
            {"Test-Plugin" -match $_} {
                Test-Plugin
            }
            Default {
                $StepFailure = true
                Write-Host ("Step '" + $_ + "' is unknown!")
            }
        }
    }
    
    # Show usage if invalid step was provided
    if ($StepFailure) {
        Write-Usage
    }
}
