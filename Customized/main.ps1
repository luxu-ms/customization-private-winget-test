param (
    [Parameter()]
    [string]$LocalRepoURL,
    [Parameter()]
    [string]$RunAsUser
)

if($RunAsUser -eq "true") {
    $CustomizationScriptsDir = "C:\DevBoxCustomizations"
    $RunAsUserScript = "runAsUser.ps1"
    $RunAsUserScriptPath = "$($CustomizationScriptsDir)\$($RunAsUserScript)"
    if(!(Test-Path -Path $CustomizationScriptsDir)){
        New-Item $CustomizationScriptsDir -type directory
    }
    Add-Content -Path $RunAsUserScriptPath -Value "Repair-WinGetPackageManager -Latest
    Remove-WinGetSource winget
    Remove-WinGetSource msstore
    Add-WinGetSource -Name WinGetRest -Argument $LocalRepoURL -Type Microsoft.Rest"
    
}else{
    Repair-WinGetPackageManager -Latest
    Remove-WinGetSource winget
    Remove-WinGetSource msstore
    Add-WinGetSource -Name WinGetRest -Argument $LocalRepoURL -Type Microsoft.Rest
}