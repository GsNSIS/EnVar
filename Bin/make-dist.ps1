Write-Output "Cleanup distribution..."
Remove-Item -Path "$PSScriptRoot\..\Dist" -Force -Recurse

Write-Output "Copy source files..."
New-Item -ItemType "directory" -Path "$PSScriptRoot\..\Dist\Contrib\EnVar" | Out-Null
Copy-Item -Path "$PSScriptRoot\..\Src" -Destination "$PSScriptRoot\..\Dist\Contrib\EnVar\" -Force -Recurse
Copy-Item "$PSScriptRoot\..\EnVar.*" -Destination "$PSScriptRoot\..\Dist\Contrib\EnVar\" -Force

Write-Output "Copy doc files..."
New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Docs\EnVar" | Out-Null
Copy-Item "$PSScriptRoot\..\LICENSE" -Destination "$PSScriptRoot\..\Dist\Docs\EnVar\" -Force
Copy-Item "$PSScriptRoot\..\README.md" -Destination "$PSScriptRoot\..\Dist\Docs\EnVar\" -Force

Write-Output "Copy doc files..."
New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Examples\EnVar" | Out-Null
Copy-Item "$PSScriptRoot\..\Docs\example.nsi" -Destination "$PSScriptRoot\..\Dist\Examples\EnVar\" -Force

Write-Output "Copy dll files..."
New-Item -ItemType "directory" "$PSScriptRoot\..\Dist\Plugins\amd64-unicode", "$PSScriptRoot\..\Dist\Plugins\x86-ansi", "$PSScriptRoot\..\Dist\Plugins\x86-unicode" | Out-Null
Copy-Item "$PSScriptRoot\..\Lib\Win32\Release\EnVar.dll" -Destination "$PSScriptRoot\..\Dist\Plugins\x86-ansi\" -Force
Copy-Item "$PSScriptRoot\..\Lib\Win32\Release Unicode\EnVar.dll" -Destination "$PSScriptRoot\..\Dist\Plugins\x86-unicode\" -Force
Copy-Item "$PSScriptRoot\..\Lib\x64\Release Unicode\EnVar.dll" -Destination "$PSScriptRoot\..\Dist\Plugins\amd64-unicode\" -Force

Write-Output "Compress distribution..."
Compress-Archive -Path "$PSScriptRoot\..\Dist\*" -DestinationPath "$PSScriptRoot\..\Dist\EnVar-Plugin.zip"

#Write-Output "Cleanup distribution..."
#Remove-Item -Path "$PSScriptRoot\..\Dist\*" -Force -Recurse -Exclude "EnVar-Plugin.zip"

Write-Output "Distribution created!"
