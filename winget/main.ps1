param (
    [Parameter()]
    [string]$ConfigurationFile,
    [Parameter()]
    [string]$DownloadUrl,
    [Parameter()]
    [string]$RunAsUser,
    [Parameter()]
    [string]$Package,
    [Parameter()]
    [string]$Override
)

$CustomizationScriptsDir = "C:\DevBoxCustomizations"
$LockFile = "lockfile"
$RunAsUserScript = "runAsUser.ps1"
$RunAsUserAppendScript = "runAsUser-append.ps1"
$CleanupScript = "cleanup.ps1"
$RunAsUserTask = "DevBoxCustomizations"
$CleanupTask = "DevBoxCustomizationsCleanup"

if (!(Test-Path -PathType Container $CustomizationScriptsDir)) {
    New-Item -Path $CustomizationScriptsDir -ItemType Directory
}

Copy-Item "./$($RunAsUserScript)" -Destination $CustomizationScriptsDir
$RunAsUserAppendScriptPath = "$($CustomizationScriptsDir)\$($RunAsUserAppendScript)"
$RunAsUserScriptPath = "$($CustomizationScriptsDir)\$($RunAsUserScript)"
if(Test-Path -Path $RunAsUserAppendScriptPath){
    $From = Get-Content -Path $RunAsUserAppendScriptPath
    Add-Content -Path $RunAsUserScriptPath -Value $From
}

Copy-Item "./$($CleanupScript)" -Destination $CustomizationScriptsDir

function SetupScheduledTasks {

    New-Item -Path "$($CustomizationScriptsDir)\$($LockFile)" -ItemType File

    # Reference: https://learn.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-objects
    $ShedService = New-Object -comobject "Schedule.Service"
    $ShedService.Connect()

    # Schedule the cleanup script to run every minute as SYSTEM
    $Task = $ShedService.NewTask(0)
    $Task.RegistrationInfo.Description = "Dev Box Customizations Cleanup"
    $Task.Settings.Enabled = $true
    $Task.Settings.AllowDemandStart = $false

    $Trigger = $Task.Triggers.Create(9)
    $Trigger.Enabled = $true
    $Trigger.Repetition.Interval="PT1M"

    $Action = $Task.Actions.Create(0)
    $Action.Path = "PowerShell.exe"
    $Action.Arguments = "Set-ExecutionPolicy Bypass -Scope Process -Force; $($CustomizationScriptsDir)\$($CleanupScript)"

    $TaskFolder = $ShedService.GetFolder("\")
    $TaskFolder.RegisterTaskDefinition("$($CleanupTask)", $Task , 6, "NT AUTHORITY\SYSTEM", $null, 5)

    # Schedule the script to be run in the user context on login
    $Task = $ShedService.NewTask(0)
    $Task.RegistrationInfo.Description = "Dev Box Customizations"
    $Task.Settings.Enabled = $true
    $Task.Settings.AllowDemandStart = $false
    $Task.Principal.RunLevel = 1

    $Trigger = $Task.Triggers.Create(9)
    $Trigger.Enabled = $true

    $Action = $Task.Actions.Create(0)
    $Action.Path = "C:\Program Files\PowerShell\7\pwsh.exe"
    $Action.Arguments = "-MTA -Command $RunAsUserScriptPath"

    $TaskFolder = $ShedService.GetFolder("\")
    $TaskFolder.RegisterTaskDefinition("$($RunAsUserTask)", $Task , 6, "Users", $null, 4)
}

function getInstallCommand($package, $override) {
    $installCommand = ""
    if ($package) {
        $installCommand = "winget install $($package)"
        if(-not ([string]::IsNullOrEmpty($override))) {
            $installCommand += " --override '$override'"
        }
    }

    return $installCommand
}

$installCommand = getInstallCommand($Package, $Override)

if (($RunAsUser -eq "true") -and ($installCommand -ne "")) {
    Add-Content -Path $RunAsUserScriptPath -Value $installCommand
}

# TODO only need to setup scheduled tasks if running as user
if (!(Test-Path -PathType Leaf "$($CustomizationScriptsDir)\$($LockFile)")) {
    SetupScheduledTasks
}
