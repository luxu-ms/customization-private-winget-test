param (
    [Parameter()]
    [string]$LocalRepoURL
)

$CustomizationScriptsDir = "C:\DevBoxCustomizations"
$RunAsUserAppendScript = "runAsUser-append.ps1"
$RunAsUserScriptPath = "$($CustomizationScriptsDir)\$($RunAsUserAppendScript)"
if(!(Test-Path -Path $CustomizationScriptsDir)){
    New-Item $CustomizationScriptsDir -type directory
}
Add-Content -Path $RunAsUserScriptPath -Value "
winget source remove -n winget
winget source remove -n msstore
winget source add -n WinGetRest $LocalRepoURL -t Microsoft.Rest
"