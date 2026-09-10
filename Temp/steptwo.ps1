        # WinSux - Optimisation Windows par ELIAS
        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = "Optimisation par ELIAS (Administrateur)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host
        Write-Host "========================================"
        Write-Host "   Optimisation par ELIAS"
        Write-Host "========================================`n"


        # FUNCTION RUN AS TRUSTED INSTALLER
        function Run-Trusted([String]$command) {
        try {
    	Stop-Service -Name TrustedInstaller -Force -ErrorAction Stop -WarningAction Stop
  		}
  		catch {
    	taskkill /im trustedinstaller.exe /f >$null
  		}
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'"
        $DefaultBinPath = $service.PathName
  		$trustedInstallerPath = "$env:SystemRoot\servicing\TrustedInstaller.exe"
  		if ($DefaultBinPath -ne $trustedInstallerPath) {
    	$DefaultBinPath = $trustedInstallerPath
  		}
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
        $base64Command = [Convert]::ToBase64String($bytes)
        sc.exe config TrustedInstaller binPath= "cmd.exe /c powershell.exe -encodedcommand $base64Command" | Out-Null
        sc.exe start TrustedInstaller | Out-Null
        sc.exe config TrustedInstaller binpath= "`"$DefaultBinPath`"" | Out-Null
        try {
    	Stop-Service -Name TrustedInstaller -Force -ErrorAction Stop -WarningAction Stop
  		}
  		catch {
    	taskkill /im trustedinstaller.exe /f >$null
  		}
        }
		Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Suppression des applications heritees" -PercentComplete 25
		Write-Host "Suppression des applications heritees`n"
		## appwiz.cpl

# uninstall brlapi
cmd /c "sc stop `"brlapi`" >nul 2>&1"
cmd /c "sc delete `"brlapi`" >nul 2>&1"
cmd /c "takeown /f `"$env:SystemRoot\brltty`" /r /d y >nul 2>&1"
cmd /c "icacls `"$env:SystemRoot\brltty`" /grant *S-1-5-32-544:F /t >nul 2>&1"
Remove-Item "$env:SystemRoot\brltty" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# uninstall microsoft gameinput
$findmicrosoftgameinput = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$microsoftgameinput = Get-ItemProperty $findmicrosoftgameinput -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*Microsoft GameInput*" }
if ($microsoftgameinput) {
$guid = $microsoftgameinput.PSChildName
Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow
}

# stop onedrive running
Stop-Process -Force -Name OneDrive -ErrorAction SilentlyContinue | Out-Null

# uninstall onedrive
cmd /c "C:\Windows\System32\OneDriveSetup.exe -uninstall >nul 2>&1"
# uninstall office 365 onedrive
Get-ChildItem -Path "C:\Program Files*\Microsoft OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive" -Filter "OneDriveSetup.exe" -Recurse -ErrorAction SilentlyContinue |
ForEach-Object { Start-Process -Wait $_.FullName -ArgumentList "/uninstall /allusers" -WindowStyle Hidden -ErrorAction SilentlyContinue }
# windows 10 uninstall onedrive
cmd /c "C:\Windows\SysWOW64\OneDriveSetup.exe -uninstall >nul 2>&1"
# windows 10 remove onedrive scheduled tasks
Get-ScheduledTask | Where-Object {$_.Taskname -match 'OneDrive'} | Unregister-ScheduledTask -Confirm:$false

# uninstall remote desktop connection
try {
Start-Process "mstsc" -ArgumentList "/Uninstall" -ErrorAction SilentlyContinue
} catch { }
# silent window for remote desktop connection
$processExists = Get-Process -Name mstsc -ErrorAction SilentlyContinue
if ($processExists) {
$running = $true
$timeout = 0
do {
$mstscProcess = Get-Process -Name mstsc -ErrorAction SilentlyContinue
if ($mstscProcess -and $mstscProcess.MainWindowHandle -ne 0) {
Stop-Process -Force -Name mstsc -ErrorAction SilentlyContinue | Out-Null
$running = $false
}
Start-Sleep -Milliseconds 100
$timeout++
if ($timeout -gt 100) {
Stop-Process -Name mstsc -Force -ErrorAction SilentlyContinue
$running = $false
}
} while ($running)
}
Start-Sleep -Seconds 1

# windows 10 uninstall old snipping tool
try {
Start-Process "C:\Windows\System32\SnippingTool.exe" -ArgumentList "/Uninstall" -ErrorAction SilentlyContinue
} catch { }
# silent window for uninstall old snipping tool
$processExists = Get-Process -Name SnippingTool -ErrorAction SilentlyContinue
if ($processExists) {
$running = $true
$timeout = 0
do {
$snipProcess = Get-Process -Name SnippingTool -ErrorAction SilentlyContinue
if ($snipProcess -and $snipProcess.MainWindowHandle -ne 0) {
Stop-Process -Force -Name SnippingTool -ErrorAction SilentlyContinue | Out-Null
$running = $false
}
Start-Sleep -Milliseconds 100
$timeout++
if ($timeout -gt 100) {
Stop-Process -Name SnippingTool -Force -ErrorAction SilentlyContinue
$running = $false
}
} while ($running)
}
Start-Sleep -Seconds 1

# windows 10 uninstall update for windows 10 for x64-based systems
$findupdateforwindows = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$updateforwindows = Get-ItemProperty $findupdateforwindows -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*Update for x64-based Windows Systems*" }
if ($updateforwindows) {
$guid = $updateforwindows.PSChildName
Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow
}

# windows 10 uninstall microsoft update health tools
$findupdatehealthtools = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$updatehealthtools = Get-ItemProperty $findupdatehealthtools -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*Microsoft Update Health Tools*" }
if ($updatehealthtools) {
$guid = $updatehealthtools.PSChildName
Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow
}
cmd /c "reg delete `"HKLM\SYSTEM\ControlSet001\Services\uhssvc`" /f >nul 2>&1"
Unregister-ScheduledTask -TaskName PLUGScheduler -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

# remove 3rd party startup apps
        ## taskmgr /0 /startup
        ## ms-settings:startupapps
cmd /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunNotification`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunNotification`" /f >nul 2>&1"
cmd /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce`" /f >nul 2>&1"
cmd /c "reg delete `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`" /f >nul 2>&1"
Remove-Item -Recurse -Force "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Recurse -Force "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

# remove 3rd party scheduled tasks
        ## taskschd.msc
		## regedit HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree
		## C:\Windows\System32\Tasks
$treePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree"
Get-ChildItem $treePath | Where-Object { $_.PSChildName -ne "Microsoft" } | ForEach-Object {
Run-Trusted "Remove-Item '$($_.PSPath)' -Recurse -Force"
}

$tasksPath = "$env:SystemRoot\System32\Tasks"
Get-ChildItem $tasksPath | Where-Object { $_.Name -ne "Microsoft" } | ForEach-Object {
Remove-Item $_.FullName -Recurse -Force
}

		Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Parametres Windows" -PercentComplete 31
		Write-Host "Parametres Windows`n"
		## regedit
		## control
        ## ms-settings:
        ## ms-settings:privacy
		## ms-settings:backup
		
# fix 1 for turn off privacy & security app permissions
# stop cam service and remove the database
Stop-Service -Name 'camsvc' -Force -ErrorAction SilentlyContinue
$capabilityconsentstoragedb = "Remove-item `"$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*`" -Force"
Run-Trusted -command $capabilityconsentstoragedb

# fix for disable windows backup
cmd /c "reg add `"HKLM\SYSTEM\ControlSet001\Services\CDPUserSvc`" /v `"Start`" /t REG_DWORD /d `"4`" /f >nul 2>&1"

# import steptwo reg file
Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$env:SystemRoot\Temp\reg.reg`"" -WindowStyle Hidden

# undo the forced 100% dpi scaling left behind by earlier versions of this pack.
# dropping the lines from reg.reg only stops them being written again - a machine that already ran an
# older version keeps LogPixels=96 forever and stays stuck at 100% scaling, so delete the values outright
# and let windows go back to the scaling it recommends for the detected panel
cmd /c "reg delete `"HKCU\Control Panel\Desktop`" /v `"LogPixels`" /f >nul 2>&1"
cmd /c "reg delete `"HKCU\Control Panel\Desktop`" /v `"Win8DpiScaling`" /f >nul 2>&1"
cmd /c "reg delete `"HKCU\SOFTWARE\Microsoft\Windows\DWM`" /v `"UseDpiScaling`" /f >nul 2>&1"

# same problem for UserPreferencesMask: an older run wrote it as REG_EXPAND_SZ, and regedit will not
# change the type of an existing value on import - it has to be deleted first so reg.reg can recreate
# it as REG_BINARY. this runs before the import above on the next pass; delete and re-import now
$upmKey = "HKCU:\Control Panel\Desktop"
try {
if ((Get-Item $upmKey).GetValueKind('UserPreferencesMask') -ne 'Binary') {
cmd /c "reg delete `"HKCU\Control Panel\Desktop`" /v `"UserPreferencesMask`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Control Panel\Desktop`" /v `"UserPreferencesMask`" /t REG_BINARY /d `"9012038010000000`" /f >nul 2>&1"
}
} catch { }

# disable gamebarpresencewriter.exe
Run-Trusted -command "reg add `"HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter`" /v `"ActivationType`" /t REG_DWORD /d `"0`" /f"

# fix 2 for turn off privacy & security app permissions
# stop cam service and remove the database
Stop-Service -Name 'camsvc' -Force -ErrorAction SilentlyContinue
$capabilityconsentstoragedb = "Remove-item `"$env:ProgramData\Microsoft\Windows\CapabilityAccessManager\CapabilityConsentStorage.db*`" -Force"
Run-Trusted -command $capabilityconsentstoragedb

# disable memorycompression
        ## powershell -noexit -command "get-mmagent"
Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue | Out-Null
# page combining costs cpu cycles scanning for identical pages, pointless on a machine with spare ram
Disable-MMAgent -PageCombining -ErrorAction SilentlyContinue | Out-Null

# disable bitlocker
        ## control /name microsoft.bitlockerdriveencryption
try {
Get-BitLockerVolume |
Where-Object {
$_.ProtectionStatus -eq "On" -or $_.VolumeStatus -ne "FullyDecrypted"
} |
ForEach-Object {
Disable-BitLocker -MountPoint $_.MountPoint -ErrorAction SilentlyContinue | Out-Null
}
} catch { }

# smartscreen for microsoft edge - needs normal boot as admin
cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge\SmartScreenEnabled`" /ve /t REG_DWORD /d `"0`" /f >nul 2>&1"

# smartscreen for microsoft store apps - needs normal boot as admin
cmd /c "reg add `"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost`" /v `"EnableWebContentEvaluation`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable scheduled tasks - needs normal boot as admin
        ## powershell -noexit -command "get-scheduledtask | where-object {$_.taskname -like '*defender*' -or $_.taskname -like '*exploitguard*'} | format-table taskname, state -autosize"
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Disable 2>$null | Out-Null
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable 2>$null | Out-Null
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable 2>$null | Out-Null
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable 2>$null | Out-Null
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable 2>$null | Out-Null

# disable defragment and optimize your drives scheduled task
        ## powershell -noexit -command "get-scheduledtask -taskname "scheduleddefrag" | select-object taskname, state"
        ## dfrgui
Get-ScheduledTask | Where-Object {$_.TaskName -match 'ScheduledDefrag'} | Disable-ScheduledTask | Out-Null

# disable all network adapters except ipv4
        ## powershell -noexit -command "get-netadapterbinding | select-object name, displayname, componentid, enabled | format-table -autosize"
        ## ncpa.cpl
$adapterstodisable = @('ms_lldp', 'ms_lltdio', 'ms_implat', 'ms_rspndr', 'ms_tcpip6', 'ms_server', 'ms_msclient', 'ms_pacer')
foreach ($adapterbinding in $adapterstodisable) {
Disable-NetAdapterBinding -Name "*" -ComponentID $adapterbinding -ErrorAction SilentlyContinue
}

# pause updates
        ## ms-settings:windowsupdate
$pause = (Get-Date).AddDays(365)
$today = Get-Date
$today = $today.ToUniversalTime().ToString( "yyyy-MM-ddTHH:mm:ssZ" )
$pause = $pause.ToUniversalTime().ToString( "yyyy-MM-ddTHH:mm:ssZ" )
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pause -Force >$null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -Value $pause -Force >$null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value $today -Force >$null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesEndTime" -Value $pause -Force >$null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesStartTime" -Value $today -Force >$null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesStartTime" -Value $today -Force >$null

# block all windows driver updates
        ## ms-settings:windowsupdate
reg add "HKLM\Software\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendGenericDriverNotFoundToWER" /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Settings" /v "DisableSendRequestAdditionalSoftwareToWER" /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAllowOptionalContent" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "AllowTemporaryEnterpriseFeatureControl" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /t REG_DWORD /d 0 /f | Out-Null

# disable if you've been away, when should windows require you to sign in again?
        ## ms-settings:signinoptions
powercfg /setdcvalueindex scheme_current sub_none consolelock 0 2>$null
powercfg /setacvalueindex scheme_current sub_none consolelock 0 2>$null

# disable set priority notifications
        ## ms-settings:notifications

# create reg file
$disableprioritynotificationsregcontent = @"
Windows Registry Editor Version 5.00

; disable set priority notifications
"@
$disableprioritynotificationsguid = Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current" -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -match '^\{[a-f0-9-]+\}\$' } |
ForEach-Object { ($_.PSChildName -split '\$')[0] } |
Select-Object -Unique
foreach ($guid in $disableprioritynotificationsguid) {
$disableprioritynotificationsregcontent += "`n`n[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\$guid`$windows.data.donotdisturb.quiethoursprofile`$quiethoursprofilelist\windows.data.donotdisturb.quiethoursprofile`$microsoft.quiethoursprofile.priorityonly]`n"
$disableprioritynotificationsregcontent += '"Data"=hex(3):43,42,01,00,0A,02,01,00,2A,06,DF,B8,B4,CC,06,2A,2B,0E,D0,03,\' + "`n"
$disableprioritynotificationsregcontent += '  43,42,01,00,C2,0A,01,CD,14,06,02,05,00,00,01,01,02,00,03,01,04,00,CC,32,12,\' + "`n"
$disableprioritynotificationsregcontent += '  05,28,4D,00,69,00,63,00,72,00,6F,00,73,00,6F,00,66,00,74,00,2E,00,53,00,63,\' + "`n"
$disableprioritynotificationsregcontent += '  00,72,00,65,00,65,00,6E,00,53,00,6B,00,65,00,74,00,63,00,68,00,5F,00,38,00,\' + "`n"
$disableprioritynotificationsregcontent += '  77,00,65,00,6B,00,79,00,62,00,33,00,64,00,38,00,62,00,62,00,77,00,65,00,21,\' + "`n"
$disableprioritynotificationsregcontent += '  00,41,00,70,00,70,00,29,4D,00,69,00,63,00,72,00,6F,00,73,00,6F,00,66,00,74,\' + "`n"
$disableprioritynotificationsregcontent += '  00,2E,00,57,00,69,00,6E,00,64,00,6F,00,77,00,73,00,41,00,6C,00,61,00,72,00,\' + "`n"
$disableprioritynotificationsregcontent += '  6D,00,73,00,5F,00,38,00,77,00,65,00,6B,00,79,00,62,00,33,00,64,00,38,00,62,\' + "`n"
$disableprioritynotificationsregcontent += '  00,62,00,77,00,65,00,21,00,41,00,70,00,70,00,31,4D,00,69,00,63,00,72,00,6F,\' + "`n"
$disableprioritynotificationsregcontent += '  00,73,00,6F,00,66,00,74,00,2E,00,58,00,62,00,6F,00,78,00,41,00,70,00,70,00,\' + "`n"
$disableprioritynotificationsregcontent += '  5F,00,38,00,77,00,65,00,6B,00,79,00,62,00,33,00,64,00,38,00,62,00,62,00,77,\' + "`n"
$disableprioritynotificationsregcontent += '  00,65,00,21,00,4D,00,69,00,63,00,72,00,6F,00,73,00,6F,00,66,00,74,00,2E,00,\' + "`n"
$disableprioritynotificationsregcontent += '  58,00,62,00,6F,00,78,00,41,00,70,00,70,00,2D,4D,00,69,00,63,00,72,00,6F,00,\' + "`n"
$disableprioritynotificationsregcontent += '  73,00,6F,00,66,00,74,00,2E,00,58,00,62,00,6F,00,78,00,47,00,61,00,6D,00,69,\' + "`n"
$disableprioritynotificationsregcontent += '  00,6E,00,67,00,4F,00,76,00,65,00,72,00,6C,00,61,00,79,00,5F,00,38,00,77,00,\' + "`n"
$disableprioritynotificationsregcontent += '  65,00,6B,00,79,00,62,00,33,00,64,00,38,00,62,00,62,00,77,00,65,00,21,00,41,\' + "`n"
$disableprioritynotificationsregcontent += '  00,70,00,70,00,29,57,00,69,00,6E,00,64,00,6F,00,77,00,73,00,2E,00,53,00,79,\' + "`n"
$disableprioritynotificationsregcontent += '  00,73,00,74,00,65,00,6D,00,2E,00,4E,00,65,00,61,00,72,00,53,00,68,00,61,00,\' + "`n"
$disableprioritynotificationsregcontent += '  72,00,65,00,45,00,78,00,70,00,65,00,72,00,69,00,65,00,6E,00,63,00,65,00,52,\' + "`n"
$disableprioritynotificationsregcontent += '  00,65,00,63,00,65,00,69,00,76,00,65,00,00,00,00,00'
}
$disableprioritynotificationsregfile = "$env:SystemRoot\Temp\disablesetprioritynotifications.reg"
$disableprioritynotificationsregcontent | Out-File -FilePath $disableprioritynotificationsregfile -Encoding ASCII

# import reg file
Start-Process -Wait "regedit.exe" -ArgumentList "/S `"$disableprioritynotificationsregfile`"" -WindowStyle Hidden

# disable app actions
        ## ms-settings:appactions
# stop c:\windows\systemapps\microsoftwindows.client.cbs_cw5n1h2txyewy running
$stop = "AppActions", "CrossDeviceResume", "DesktopStickerEditorWin32Exe", "DiscoveryHubApp", "FESearchHost", "SearchHost", "SoftLandingTask", "TextInputHost", "VisualAssistExe", "WebExperienceHostApp", "WindowsBackupClient", "WindowsMigration"
$stop | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 2

# create reg file
$appactions = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Settings\LocalState\DisabledApps]
"Microsoft.Paint_8wekyb3d8bbwe"=hex(5f5e10b):01,61,ed,11,34,f7,9f,dc,01
"Microsoft.Windows.Photos_8wekyb3d8bbwe"=hex(5f5e10b):01,61,ed,11,34,f7,9f,dc,01
"MicrosoftWindows.Client.CBS_cw5n1h2txyewy"=hex(5f5e10b):01,61,ed,11,34,f7,9f,dc,01
'@
Set-Content -Path "$env:SystemRoot\Temp\appactions.reg" -Value $appactions -Force
$settingsdat = "$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat"
$regfileappactions = "$env:SystemRoot\Temp\appactions.reg"

# load hive
reg load "HKLM\Settings" $settingsdat >$null 2>&1

# import reg file
if ($LASTEXITCODE -eq 0) {
reg import $regfileappactions >$null 2>&1

# unload hive
[gc]::Collect()
Start-Sleep -Seconds 2
reg unload "HKLM\Settings" >$null 2>&1
}

# disable network adapter powersaving & wake on all connected devices
$basePath = "HKLM:\System\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
$adapterKeys = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue
foreach ($key in $adapterKeys) {
if ($key.PSChildName -match '^\d{4}$') {
$regPath = $key.Name
# disable adapter powersaving & wake
cmd /c "reg add `"$regPath`" /v `"PnPCapabilities`" /t REG_DWORD /d `"24`" /f >nul 2>&1"
# disable advanced energy efficient ethernet
cmd /c "reg add `"$regPath`" /v `"AdvancedEEE`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# disable energy-efficient ethernet
cmd /c "reg add `"$regPath`" /v `"*EEE`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"EEELinkAdvertisement`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# system idle power saver
cmd /c "reg add `"$regPath`" /v `"SipsEnabled`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# ultra low power mode
cmd /c "reg add `"$regPath`" /v `"ULPMode`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# disable gigabit lite
cmd /c "reg add `"$regPath`" /v `"GigaLite`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# disable green ethernet
cmd /c "reg add `"$regPath`" /v `"EnableGreenEthernet`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# disable power saving mode
cmd /c "reg add `"$regPath`" /v `"PowerSavingMode`" /t REG_SZ /d `"0`" /f >nul 2>&1"
# disable all wake
cmd /c "reg add `"$regPath`" /v `"S5WakeOnLan`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"*WakeOnMagicPacket`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"*ModernStandbyWoLMagicPacket`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"*WakeOnPattern`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"WakeOnLink`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"*ModernStandbyWoLMagicPacket`" /t REG_SZ /d `"0`" /f >nul 2>&1"
}
}

# disable acpi power savings on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\ACPI" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"EnhancedPowerManagementEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendEnabled`" /t REG_BINARY /d `"00`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendOn`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\ACPI" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "WDF" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"IdleInWorkingState`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable hid power savings on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\HID" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"EnhancedPowerManagementEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendEnabled`" /t REG_BINARY /d `"00`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendOn`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\HID" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "WDF" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"IdleInWorkingState`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable pci power savings on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\PCI" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"EnhancedPowerManagementEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendEnabled`" /t REG_BINARY /d `"00`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendOn`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\PCI" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "WDF" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"IdleInWorkingState`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable usb power savings on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\USB" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"EnhancedPowerManagementEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendEnabled`" /t REG_BINARY /d `"00`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"SelectiveSuspendOn`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\USB" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "WDF" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"IdleInWorkingState`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable acpi wake on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\ACPI" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"WaitWakeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable hid wake on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\HID" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"WaitWakeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable pci wake on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\PCI" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"WaitWakeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# disable usb wake on all connected devices
$usbKeys = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\USB" -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -eq "Device Parameters" }
foreach ($key in $usbKeys) {
$regPath = $key.Name
cmd /c "reg add `"$regPath`" /v `"WaitWakeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# turn off windows write-cache buffer flushing on the device on all connected scsi devices
$basePath = "HKLM:\SYSTEM\ControlSet001\Enum\SCSI"
Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq "Device Parameters" } | ForEach-Object {
$diskPath = Join-Path $_.PSPath "Disk"
cmd /c "reg add `"$(($diskPath -replace 'Microsoft.PowerShell.Core\\Registry::',''))`" /v `"CacheIsPowerProtected`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
}

# turn off windows write-cache buffer flushing on the device on all connected nvme devices
$basePath = "HKLM:\SYSTEM\ControlSet001\Enum\NVME"
Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq "Device Parameters" } | ForEach-Object {
$diskPath = Join-Path $_.PSPath "Disk"
cmd /c "reg add `"$(($diskPath -replace 'Microsoft.PowerShell.Core\\Registry::',''))`" /v `"CacheIsPowerProtected`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
}

# import notepad settings
        ## notepad
# stop notepad running
Stop-Process -Name "Notepad" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# create reg file
$NotepadSettings = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Settings\LocalState]
"OpenFile"=hex(5f5e104):01,00,00,00,d1,55,24,57,d1,84,db,01
"GhostFile"=hex(5f5e10b):00,42,60,f1,5a,d1,84,db,01
"RewriteEnabled"=hex(5f5e10b):00,12,4a,7f,5f,d1,84,db,01
'@
Set-Content -Path "$env:SystemRoot\Temp\notepadsettings.reg" -Value $NotepadSettings -Force
$SettingsDat = "$env:LocalAppData\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat"
$RegFileNotepadSettings = "$env:SystemRoot\Temp\notepadsettings.reg"

# load hive
reg load "HKLM\Settings" $SettingsDat >$null 2>&1

# import reg file
if ($LASTEXITCODE -eq 0) {
reg import $RegFileNotepadSettings >$null 2>&1

# unload hive
[gc]::Collect()
Start-Sleep -Seconds 2
reg unload "HKLM\Settings" >$null 2>&1
}

# unpin all taskbar items
cmd /c "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband /f >nul 2>&1"
Remove-Item -Recurse -Force "$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch" -ErrorAction SilentlyContinue | Out-Null
	
# black signout & lockscreen
		## ms-settings:lockscreen
# create image
Add-Type -AssemblyName System.Windows.Forms
$screenWidth = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width
$screenHeight = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height
Add-Type -AssemblyName System.Drawing
$file = "C:\Windows\Black.jpg"
$edit = New-Object System.Drawing.Bitmap $screenWidth, $screenHeight
$color = [System.Drawing.Brushes]::Black
$graphics = [System.Drawing.Graphics]::FromImage($edit)
$graphics.FillRectangle($color, 0, 0, $edit.Width, $edit.Height)
$graphics.Dispose()
$edit.Save($file)
$edit.Dispose()

# set image
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP`" /v `"LockScreenImagePath`" /t REG_SZ /d `"C:\Windows\Black.jpg`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP`" /v `"LockScreenImageStatus`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# black wallpaper
cmd /c "reg add `"HKCU\Control Panel\Desktop`" /v `"Wallpaper`" /t REG_SZ /d `"C:\Windows\Black.jpg`" /f >nul 2>&1"
rundll32.exe user32.dll, UpdatePerUserSystemParameters

# remove context menu items
# restore the classic context menu
cmd /c "reg add `"HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`" /ve /t REG_SZ /d `"`" /f >nul 2>&1"

# remove customize this folder
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" /v `"NoCustomizeThisFolder`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# remove pin to quick access
cmd /c "reg delete `"HKCR\Folder\shell\pintohome`" /f >nul 2>&1"

# remove add to favorites
cmd /c "reg delete `"HKCR\*\shell\pintohomefile`" /f >nul 2>&1"

# remove troubleshoot compatibility
cmd /c "reg delete `"HKCR\exefile\shellex\ContextMenuHandlers\Compatibility`" /f >nul 2>&1"

# remove open in terminal
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`" /v `"{9F156763-7844-4DC4-B2B1-901F640F5155}`" /t REG_SZ /d `"`" /f >nul 2>&1"

# remove scan with defender
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`" /v `"{09A47860-11B0-4DA5-AFA5-26D86198A780}`" /t REG_SZ /d `"`" /f >nul 2>&1"

# remove give access to
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`" /v `"{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}`" /t REG_SZ /d `"`" /f >nul 2>&1"

# remove include in library
cmd /c "reg delete `"HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location`" /f >nul 2>&1"

# remove share
cmd /c "reg delete `"HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing`" /f >nul 2>&1"

# remove restore previous versions
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer`" /v `"NoPreviousVersionsPage`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# remove send to
cmd /c "reg delete `"HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo`" /f >nul 2>&1"
cmd /c "reg delete `"HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\SendTo`" /f >nul 2>&1"

# windows 10 import start menu
# delete startmenulayout.xml
Remove-Item -Recurse -Force "$env:SystemDrive\Windows\StartMenuLayout.xml" -ErrorAction SilentlyContinue | Out-Null

# create startmenulayout.xml
$MultilineComment = @'
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
'@
Set-Content -Path "C:\Windows\StartMenuLayout.xml" -Value $MultilineComment -Force -Encoding ASCII

# assign startmenulayout.xml registry
$layoutFile="C:\Windows\StartMenuLayout.xml"
$regAliases = @("HKLM", "HKCU")
foreach ($regAlias in $regAliases){
$basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
$keyPath = $basePath + "\Explorer"
IF(!(Test-Path -Path $keyPath)) {
New-Item -Path $basePath -Name "Explorer" | Out-Null
}
Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1 | Out-Null
Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile | Out-Null
}

# restart explorer
Stop-Process -Force -Name explorer -ErrorAction SilentlyContinue | Out-Null
Start-Sleep -Seconds 5

# disable lockedstartlayout registry
foreach ($regAlias in $regAliases){
$basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
$keyPath = $basePath + "\Explorer"
Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
}

# delete startmenulayout.xml
Remove-Item -Recurse -Force "$env:SystemDrive\Windows\StartMenuLayout.xml" -ErrorAction SilentlyContinue | Out-Null

# windows 11 import start menu
# remove start2 bin
Remove-Item -Recurse -Force "$env:USERPROFILE\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin" -ErrorAction SilentlyContinue | Out-Null

# decode start2 txt
certutil.exe -decode "$env:SystemRoot\Temp\start2.txt" "$env:SystemRoot\Temp\start2.bin" >$null

# install start2 bin
Copy-Item "$env:SystemRoot\Temp\start2.bin" -Destination "$env:USERPROFILE\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState" -Force -ErrorAction SilentlyContinue | Out-Null

# set start menu apps view to list
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Start`" /v `"AllAppsViewMode`" /t REG_DWORD /d `"2`" /f >nul 2>&1"

# restart explorer
Stop-Process -Force -Name explorer -ErrorAction SilentlyContinue | Out-Null

# create start menu & startup shortcuts
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Start Menu Shortcuts 1.lnk")
$Shortcut.TargetPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
$Shortcut.Save()
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Start Menu Shortcuts 2.lnk")
$Shortcut.TargetPath = "$env:AppData\Microsoft\Windows\Start Menu\Programs"
$Shortcut.Save()
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup Programs 1.lnk")
$Shortcut.TargetPath = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup"
$Shortcut.Save()
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup Programs 2.lnk")
$Shortcut.TargetPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
$Shortcut.Save()

# create recycle bin shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Recycle Bin.lnk")
$Shortcut.TargetPath = '::{645ff040-5081-101b-9f08-00aa002f954e}'
$Shortcut.Save()

# hide accessibility accessories folders and all contents from start menu
$folders = @(
"$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessibility",
"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Accessibility",
"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories"
)
foreach ($folder in $folders) {
if (Test-Path $folder) {
cmd /c "attrib +h `"$folder`" >nul 2>&1"
cmd /c "attrib +h `"$folder\*.*`" /s /d >nul 2>&1"
}
}

# set start menu apps view to list
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Start`" /v `"AllAppsViewMode`" /t REG_DWORD /d `"2`" /f >nul 2>&1"

# restart explorer
Stop-Process -Force -Name explorer -ErrorAction SilentlyContinue | Out-Null
Start-Sleep -Seconds 10


# detect nvidia gpu automatically - nvidia only, no menu, no user action
# detect by pci vendor id (VEN_10DE = NVIDIA), not by driver-reported name - the name-based check fails right after DDU wipes the driver, since windows falls back to a generic "Microsoft Basic Display Adapter" name until a driver is reinstalled
$hasNvidia = [bool](Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match 'VEN_10DE' })

if ($hasNvidia) {
        Clear-Host

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Telechargement du pilote GPU Nvidia" -PercentComplete 38
        Write-Host "Telechargement du pilote GPU Nvidia`n"
    	## explorer "https://www.nvidia.com/en-us/drivers"
		## shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel

# fully automatic driver detection & download - no user action needed
$InstallFile = $null

# powershell 5.1 negotiates ssl3/tls1.0 by default; nvidia's endpoints only accept tls 1.2+, so every
# Invoke-RestMethod below used to fail instantly and drop straight through to the manual file picker
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 } catch { }
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288 } catch { }
$nvUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

# small retry helper - nvidia's lookup services time out often enough that a single attempt is unreliable
function Get-NvJson([string]$url) {
for ($attempt = 1; $attempt -le 3; $attempt++) {
try {
return Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 30 -Headers @{ "User-Agent" = $nvUserAgent } -ErrorAction Stop
} catch {
Start-Sleep -Seconds 3
}
}
return $null
}

try {
# read the gpu name captured before ddu wiped the driver (fallback to a live query if the cache file is missing)
$gpuNameCache = "$env:SystemRoot\Temp\gpuname.txt"
if (Test-Path $gpuNameCache) {
$gpuName = (Get-Content $gpuNameCache -Raw).Trim()
} else {
$gpuName = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" } | Select-Object -First 1).Name
}

$downloadUrl = $null
if ($gpuName) {
# normalise: strip the vendor prefix, the memory suffix some oems append, and collapse whitespace
$cleanGpuName = ($gpuName -replace '^NVIDIA\s+', '' -replace '\s+\d+GB$', '' -replace '\s+', ' ').Trim()

$productList = Get-NvJson "https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3"
$candidates = @()
if ($productList) { $candidates = @($productList.LookupValueSearch.LookupValues.LookupValue) }

$match = $null
if ($candidates.Count -gt 0) {
# 1. exact name match
$match = $candidates | Where-Object { (($_.Name -replace '^NVIDIA\s+', '').Trim()) -ieq $cleanGpuName } | Select-Object -First 1
# 2. substring match, longest name first so "RTX 4070 Ti SUPER" wins over "RTX 4070"
if (-not $match) {
$match = $candidates | Where-Object { $_.Name -and ($cleanGpuName -like "*$($_.Name -replace '^NVIDIA\s+','')*") } |
Sort-Object { $_.Name.Length } -Descending | Select-Object -First 1
}
if (-not $match) {
$match = $candidates | Where-Object { $_.Name -like "*$cleanGpuName*" } | Select-Object -First 1
}
}

if ($match) {
$pfid = $match.Value
$psid = $match.ParentID
$osVersion = [System.Environment]::OSVersion.Version
$osID = if ($osVersion.Build -ge 22000) { 135 } else { 57 }

# ask for several results and take the first one that actually carries a download url, instead of
# assuming result #1 exists - a single-result query returns nothing at all for some product ids
foreach ($dch in @(1,0)) {
$driverInfo = Get-NvJson "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$psid&pfid=$pfid&osID=$osID&languageCode=1033&beta=0&isWHQL=1&dltype=-1&dch=$dch&sort1=0&numberOfResults=10"
if ($driverInfo -and $driverInfo.IDS) {
$downloadUrl = ($driverInfo.IDS | ForEach-Object { $_.downloadInfo.DownloadURL } | Where-Object { $_ } | Select-Object -First 1)
}
if ($downloadUrl) { break }
}
}
}

if ($downloadUrl) {
Write-Host "Pilote trouve : $downloadUrl`n"
$candidateFile = "$env:SystemRoot\Temp\nvidia_driver_auto.exe"
Remove-Item $candidateFile -Force -ErrorAction SilentlyContinue

# real download progress via webclient events (Invoke-WebRequest's own bar is unusably slow in powershell 5.1)
# retried up to 3 times - a truncated driver package is worse than no download at all
$downloadOk = $false
for ($try = 1; $try -le 3 -and -not $downloadOk; $try++) {
$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("User-Agent", $nvUserAgent)
Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WinSuxDriverDownload.Progress | Out-Null
Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -SourceIdentifier WinSuxDriverDownload.Completed | Out-Null
$webClient.DownloadFileAsync([Uri]$downloadUrl, $candidateFile)
$downloadDone = $false
while (-not $downloadDone) {
$progEvent = Wait-Event -SourceIdentifier WinSuxDriverDownload.Progress -Timeout 1
if ($progEvent) {
$percent = $progEvent.SourceEventArgs.ProgressPercentage
$mbReceived = [math]::Round($progEvent.SourceEventArgs.BytesReceived / 1MB, 1)
$mbTotal = [math]::Round($progEvent.SourceEventArgs.TotalBytesToReceive / 1MB, 1)
Write-Progress -Id 2 -ParentId 1 -Activity "Telechargement du pilote NVIDIA (essai $try/3)" -Status "$mbReceived Mo / $mbTotal Mo ($percent%)" -PercentComplete $percent
Remove-Event -SourceIdentifier WinSuxDriverDownload.Progress
}
$compEvent = Wait-Event -SourceIdentifier WinSuxDriverDownload.Completed -Timeout 0
if ($compEvent) {
$downloadDone = $true
$downloadOk = -not $compEvent.SourceEventArgs.Cancelled -and -not $compEvent.SourceEventArgs.Error
Remove-Event -SourceIdentifier WinSuxDriverDownload.Completed
}
}
Unregister-Event -SourceIdentifier WinSuxDriverDownload.Progress -ErrorAction SilentlyContinue
Unregister-Event -SourceIdentifier WinSuxDriverDownload.Completed -ErrorAction SilentlyContinue
$webClient.Dispose()
if ($downloadOk -and (Test-Path $candidateFile) -and (Get-Item $candidateFile).Length -lt 100MB) { $downloadOk = $false }
}
Write-Progress -Id 2 -Activity "Telechargement du pilote NVIDIA" -Completed
if ($downloadOk) { $InstallFile = $candidateFile }
}
} catch { $InstallFile = $null }

# fallback to manual download only if automatic detection/download failed - tell the user why instead of silently switching
if (-not $InstallFile -or -not (Test-Path $InstallFile)) {
Write-Host "Le telechargement automatique du pilote a echoue, selection manuelle requise`n"
Start-Sleep -Seconds 5
Start-Process "https://www.nvidia.com/en-us/drivers"
Pause
Clear-Host

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Selection du pilote" -PercentComplete 44
        Write-Host "Selectionnez le pilote telecharge`n"

Start-Sleep -Seconds 5
Add-Type -AssemblyName System.Windows.Forms
$Dialog = New-Object System.Windows.Forms.OpenFileDialog
$Dialog.Filter = "All Files (*.*)|*.*"
$Dialog.ShowDialog() | Out-Null
$InstallFile = $Dialog.FileName
}

# only extract/install if we actually have a driver file - the manual dialog can be cancelled, leaving $InstallFile empty
if ($InstallFile -and (Test-Path $InstallFile)) {

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Allegement du pilote" -PercentComplete 50
        Write-Host "Allegement du pilote`n"

# extract driver with 7zip
& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemRoot\Temp\nvidiadriver" -y | Out-Null

# debloat nvidia driver
# NvContainer / NvCpl / HDAudio / PhysX are deliberately KEPT now: removing NvContainer+NvCpl left the machine
# with no nvidia control panel at all (no resolution / refresh rate / colour control), removing HDAudio killed
# hdmi & displayport audio, and removing PhysX crashes older titles that ship against it
$nvidiaDebloatItems = @(
"Display.Nview","FrameViewSDK","NvApp.MessageBus","NvBackend","NvDLISR","NvTelemetry","NvVAD","PPC","ShadowPlay",
"NvApp\CEF","NvApp\osc","NvApp\Plugins","NvApp\UpgradeConsent","NvApp\www",
"NvApp\7z.dll","NvApp\7z.exe","NvApp\DarkModeCheck.exe","NvApp\InstallerExtension.dll","NvApp\NvApp.nvi","NvApp\NvAppApi.dll","NvApp\NvAppExt.dll","NvApp\NvConfigGenerator.dll"
)
# NVPCF drives dynamic boost on laptops - only strip it on a desktop
if (-not (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)) { $nvidiaDebloatItems += "NVPCF" }
$totalNvidiaItems = $nvidiaDebloatItems.Count
$i = 0
foreach ($item in $nvidiaDebloatItems) {
$i++
Write-Progress -Id 2 -ParentId 1 -Activity "Allegement du pilote" -Status "$item ($i/$totalNvidiaItems)" -PercentComplete (($i / $totalNvidiaItems) * 100)
Remove-Item "$env:SystemRoot\Temp\nvidiadriver\$item" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}
Write-Progress -Id 2 -Activity "Allegement du pilote" -Completed

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Installation du pilote" -PercentComplete 56
        Write-Host "Installation du pilote`n"

# install nvidia driver
Start-Process "$env:SystemRoot\Temp\nvidiadriver\setup.exe" -ArgumentList "-s -noreboot -noeula -clean" -Wait -NoNewWindow

# install nvidia control panel only if the driver did not already bring it in - winget itself may be gone,
# so this is best-effort and no longer the only path to a working control panel
if (-not (Get-AppxPackage -AllUsers "*NVIDIAControlPanel*" -ErrorAction SilentlyContinue)) {
try {
Start-Process "winget" -ArgumentList "install `"9NF8H0H7WMLT`" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
} catch { }
}

# delete download
Remove-Item "$InstallFile" -Force -ErrorAction SilentlyContinue | Out-Null

# delete old driver files
Remove-Item "$env:SystemDrive\NVIDIA" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

} else {
Write-Host "Aucun fichier pilote disponible - installation du pilote ignoree`n"
}

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Importation des parametres" -PercentComplete 63
        Write-Host "Importation des parametres`n"

# turn on disable dynamic pstate
$subkeys = Get-ChildItem -Path "Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -Force -ErrorAction SilentlyContinue
foreach($key in $subkeys){
if ($key -notlike '*Configuration'){
reg add "$key" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f | Out-Null
}
}

# disable hdcp
$subkeys = Get-ChildItem -Path "Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -Force -ErrorAction SilentlyContinue
foreach($key in $subkeys){
if ($key -notlike '*Configuration'){
reg add "$key" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f | Out-Null
}
}

# unblock drs files
$path = "C:\ProgramData\NVIDIA Corporation\Drs"
Get-ChildItem -Path $path -Recurse | Unblock-File

# set physx to gpu
cmd /c "reg add `"HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak`" /v `"NvCplPhysxAuto`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# enable developer settings
cmd /c "reg add `"HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak`" /v `"NvDevToolsVisible`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# allow access to the gpu performance counters to all users
$subkeys = Get-ChildItem -Path "Registry::HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -Force -ErrorAction SilentlyContinue
foreach($key in $subkeys){
if ($key -notlike '*Configuration'){
reg add "$key" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f | Out-Null
}
}
cmd /c "reg add `"HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak`" /v `"RmProfilingAdminOnly`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable show notification tray icon
cmd /c "reg add `"HKCU\Software\NVIDIA Corporation\NvTray`" /v `"StartOnLogin`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# enable nvidia legacy sharpen
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS`" /v `"EnableGR535`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS`" /v `"EnableGR535`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS`" /v `"EnableGR535`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# set config for inspector
$nipfile = @'
<?xml version="1.0" encoding="utf-16"?>
<ArrayOfProfile>
  <Profile>
    <ProfileName>Base Profile</ProfileName>
    <Executables/>
    <Settings>
      <ProfileSetting>
        <SettingNameInfo>Frame Rate Limiter V3</SettingNameInfo>
        <SettingID>277041154</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>GSYNC - Application Mode</SettingNameInfo>
        <SettingID>294973784</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>GSYNC - Application State</SettingNameInfo>
        <SettingID>279476687</SettingID>
        <SettingValue>4</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>GSYNC - Global Feature</SettingNameInfo>
        <SettingID>278196567</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>GSYNC - Global Mode</SettingNameInfo>
        <SettingID>278196727</SettingID>
        <SettingValue>2</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>GSYNC - Indicator Overlay</SettingNameInfo>
        <SettingID>268604728</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Maximum Pre-Rendered Frames</SettingNameInfo>
        <SettingID>8102046</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Preferred Refresh Rate</SettingNameInfo>
        <SettingID>6600001</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Ultra Low Latency - CPL State</SettingNameInfo>
        <SettingID>390467</SettingID>
        <SettingValue>2</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Ultra Low Latency - Enabled</SettingNameInfo>
        <SettingID>277041152</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Vertical Sync</SettingNameInfo>
        <SettingID>11041231</SettingID>
        <SettingValue>138504007</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Vertical Sync - Smooth AFR Behavior</SettingNameInfo>
        <SettingID>270198627</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Vertical Sync - Tear Control</SettingNameInfo>
        <SettingID>5912412</SettingID>
        <SettingValue>2525368439</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Vulkan/OpenGL Present Method</SettingNameInfo>
        <SettingID>550932728</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Antialiasing - Gamma Correction</SettingNameInfo>
        <SettingID>276652957</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Antialiasing - Mode</SettingNameInfo>
        <SettingID>276757595</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Antialiasing - Setting</SettingNameInfo>
        <SettingID>282555346</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Anisotropic Filter - Optimization</SettingNameInfo>
        <SettingID>8703344</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Anisotropic Filter - Sample Optimization</SettingNameInfo>
        <SettingID>15151633</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Anisotropic Filtering - Mode</SettingNameInfo>
        <SettingID>282245910</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Anisotropic Filtering - Setting</SettingNameInfo>
        <SettingID>270426537</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Texture Filtering - Negative LOD Bias</SettingNameInfo>
        <SettingID>1686376</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Texture Filtering - Quality</SettingNameInfo>
        <SettingID>13510289</SettingID>
        <SettingValue>20</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Texture Filtering - Trilinear Optimization</SettingNameInfo>
        <SettingID>3066610</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>CUDA - Force P2 State</SettingNameInfo>
        <SettingID>1343646814</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
	  <ProfileSetting>
        <SettingNameInfo>CUDA - Sysmem Fallback Policy</SettingNameInfo>
        <SettingID>283962569</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Power Management - Mode</SettingNameInfo>
        <SettingID>274197361</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Shader Cache - Cache Size</SettingNameInfo>
        <SettingID>11306135</SettingID>
        <SettingValue>4294967295</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>Threaded Optimization</SettingNameInfo>
        <SettingID>549528094</SettingID>
        <SettingValue>1</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
      <ProfileSetting>
        <SettingNameInfo>OpenGL GDI Compatibility</SettingNameInfo>
        <SettingID>544392611</SettingID>
        <SettingValue>0</SettingValue>
        <ValueType>Dword</ValueType>
      </ProfileSetting>
    </Settings>
  </Profile>
</ArrayOfProfile>
'@
Set-Content -Path "$env:SystemRoot\Temp\inspector.nip" -Value $nipfile -Force

# import nip
Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\inspector.nip"

# apply a light power limit boost adapted to the gpu (raises to the manufacturer's own default, never the extreme max, no clock/voltage overclock)
# smart: only boosts on ac power (or desktops with no battery), re-checks periodically instead of a one-shot fixed value
try {
# permanent folder, NOT C:\Windows\Temp - the disk cleanup step at the end of this script wipes that folder,
# which would delete the script the scheduled task depends on and silently kill the boost after reboot
$persistentDir = "$env:ProgramData\Optimisation"
New-Item -Path $persistentDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$gpuBoostScript = "$persistentDir\gpuboost.ps1"
$gpuBoostScriptContent = @'
Add-Type -AssemblyName System.Windows.Forms
$hasBattery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
$onAC = (-not $hasBattery) -or ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online')
$powerReport = & nvidia-smi -q -d POWER 2>$null
$currentLine = $powerReport | Select-String "Current Power Limit\s*:\s*([\d.]+)"
$defaultLine = $powerReport | Select-String "Default Power Limit\s*:\s*([\d.]+)"
$maxLine = $powerReport | Select-String "Max Power Limit\s*:\s*([\d.]+)"

# thermal guard. the boost is only worth having while the card is not already close to its own
# throttling point - past that, a higher power limit buys nothing and just adds heat and fan noise
$gpuTemp = 0
$slowdownTemp = 0
try { $gpuTemp = [int]((& nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null) | Select-Object -First 1) } catch { }
try {
$thermalReport = & nvidia-smi -q -d TEMPERATURE 2>$null
$slowLine = $thermalReport | Select-String "GPU Slowdown Temp\s*:\s*(\d+)"
if ($slowLine) { $slowdownTemp = [int]$slowLine.Matches[0].Groups[1].Value }
} catch { }
# stay 10 degrees below the card's own slowdown threshold, or 80 C if it could not be read
$tempCeiling = if ($slowdownTemp -gt 0) { $slowdownTemp - 10 } else { 80 }

if ($currentLine -and $defaultLine -and $maxLine) {
$currentLimit = [double]$currentLine.Matches[0].Groups[1].Value
$defaultLimit = [double]$defaultLine.Matches[0].Groups[1].Value
$maxLimit = [double]$maxLine.Matches[0].Groups[1].Value
# light +15% boost above the manufacturer default, always capped by the card's own max power limit
$boostTarget = [math]::Min($defaultLimit * 1.15, $maxLimit)

if ($gpuTemp -gt 0 -and $gpuTemp -ge $tempCeiling -and $currentLimit -gt $defaultLimit) {
# running hot: step back down to the manufacturer default and stop there
& nvidia-smi -pl ([math]::Floor($defaultLimit)) 2>$null | Out-Null
} elseif ($onAC -and $currentLimit -lt $boostTarget -and ($gpuTemp -eq 0 -or $gpuTemp -lt $tempCeiling)) {
# progressive ramp in 4 steps instead of an instant jump, re-checking temperature between steps
$steps = 4
$stepSize = ($boostTarget - $currentLimit) / $steps
for ($s = 1; $s -le $steps; $s++) {
$stepTarget = [math]::Floor($currentLimit + ($stepSize * $s))
& nvidia-smi -pl $stepTarget 2>$null | Out-Null
Start-Sleep -Seconds 3
try {
$t = [int]((& nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null) | Select-Object -First 1)
if ($t -ge $tempCeiling) { & nvidia-smi -pl ([math]::Floor($defaultLimit)) 2>$null | Out-Null; break }
} catch { }
}
} elseif (-not $onAC -and $currentLimit -gt $defaultLimit) {
& nvidia-smi -pl ([math]::Floor($defaultLimit)) 2>$null | Out-Null
}
}
'@
Set-Content -Path $gpuBoostScript -Value $gpuBoostScriptContent -Force

# run once now, then keep re-checking (at logon, at startup, and every 15 min while logged in) so it reacts to plugging/unplugging
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gpuBoostScript

$gpuBoostAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$gpuBoostScript`""
$gpuBoostTriggers = @(
(New-ScheduledTaskTrigger -AtLogOn),
(New-ScheduledTaskTrigger -AtStartup),
(New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650))
)
$gpuBoostPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "GPU Boost" -Action $gpuBoostAction -Trigger $gpuBoostTriggers -Principal $gpuBoostPrincipal -Force -ErrorAction SilentlyContinue | Out-Null
} catch { }
}

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Optimisations jeux" -PercentComplete 69
        Write-Host "Optimisations jeux`n"

# disable game dvr & fullscreen optimizations
cmd /c "reg add `"HKCU\System\GameConfigStore`" /v `"GameDVR_Enabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\System\GameConfigStore`" /v `"GameDVR_FSEBehaviorMode`" /t REG_DWORD /d `"2`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\System\GameConfigStore`" /v `"GameDVR_FSEBehavior`" /t REG_DWORD /d `"2`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\System\GameConfigStore`" /v `"GameDVR_HonorUserFSEBehaviorMode`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR`" /v `"AllowGameDVR`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# explicitly ensure game mode (background task deprioritization during games) stays on
cmd /c "reg add `"HKCU\Software\Microsoft\GameBar`" /v `"AutoGameModeEnabled`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\GameBar`" /v `"AllowAutoGameMode`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# disable windows error reporting service - crash dumps still saved locally, just not processed/sent
cmd /c "sc stop `"WerSvc`" >nul 2>&1"
cmd /c "sc config `"WerSvc`" start= disabled >nul 2>&1"

# enable hardware-accelerated gpu scheduling
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`" /v `"HwSchMode`" /t REG_DWORD /d `"2`" /f >nul 2>&1"

# disable nagle's algorithm & delayed ack on all network interfaces
$basePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue | ForEach-Object {
$regPath = $_.Name
cmd /c "reg add `"$regPath`" /v `"TcpAckFrequency`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"TCPNoDelay`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg add `"$regPath`" /v `"TcpDelAckTicks`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
}

# remove qos packet scheduler's soft bandwidth reservation
cmd /c "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched`" /v `"NonBestEffortLimit`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# enable receive side scaling to spread nic interrupts across cpu cores
Enable-NetAdapterRss -Name "*" -ErrorAction SilentlyContinue | Out-Null

# enable explicit congestion notification - reduces packet loss/retransmits under congestion, no throughput cost
cmd /c "netsh int tcp set global ecncapability=enabled >nul 2>&1"

# disable receive segment coalescing - trades a bit of cpu efficiency for lower per-packet latency
cmd /c "netsh int tcp set global rsc=disabled >nul 2>&1"

# disable tcp timestamps - shaves a few bytes/cycles of per-packet overhead
cmd /c "netsh int tcp set global timestamps=disabled >nul 2>&1"

# widen the ephemeral port range and shorten time_wait - avoids port exhaustion stalls under heavy connection churn (voice chat, matchmaking, many short-lived sockets)
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" /v `"MaxUserPort`" /t REG_DWORD /d `"65534`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" /v `"TcpTimedWaitDelay`" /t REG_DWORD /d `"30`" /f >nul 2>&1"

# disable unused ipv6 tunneling adapters - removes background negotiation overhead, no effect on normal connectivity
cmd /c "netsh interface teredo set state disabled >nul 2>&1"
cmd /c "netsh interface 6to4 set state disabled >nul 2>&1"
cmd /c "netsh interface isatap set state disabled >nul 2>&1"

# lower nic interrupt moderation for less per-packet latency, where the driver exposes it (silently skipped otherwise)
# uses RegistryKeyword (language-independent) instead of DisplayName, which is localized and silently fails to match on non-English Windows
Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
try { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*InterruptModeration" -RegistryValue 0 -ErrorAction Stop } catch { }
try { Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation Rate" -DisplayValue "Off" -ErrorAction Stop } catch { }

# raise receive/transmit buffers where the driver exposes them - fewer dropped packets under load
try {
$rxProp = Get-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*ReceiveBuffers" -AllProperties -ErrorAction Stop
if ($rxProp.NumericParameterMaxValue) { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*ReceiveBuffers" -RegistryValue $rxProp.NumericParameterMaxValue -ErrorAction Stop }
} catch { }
try {
$txProp = Get-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*TransmitBuffers" -AllProperties -ErrorAction Stop
if ($txProp.NumericParameterMaxValue) { Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "*TransmitBuffers" -RegistryValue $txProp.NumericParameterMaxValue -ErrorAction Stop }
} catch { }
}

# disable sysmain (superfetch)
cmd /c "sc stop `"SysMain`" >nul 2>&1"
cmd /c "sc config `"SysMain`" start= disabled >nul 2>&1"

# mmcss - stop background tasks from throttling foreground multimedia/games & remove network throttling
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`" /v `"SystemResponsiveness`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`" /v `"NetworkThrottlingIndex`" /t REG_DWORD /d `"4294967295`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games`" /v `"GPU Priority`" /t REG_DWORD /d `"8`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games`" /v `"Priority`" /t REG_DWORD /d `"6`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games`" /v `"Scheduling Category`" /t REG_SZ /d `"High`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games`" /v `"SFIO Priority`" /t REG_SZ /d `"High`" /f >nul 2>&1"

# boost foreground app cpu scheduling priority over background apps - 38 decimal = 0x26 (short quantum, variable, 3:1 foreground boost)
# reg.exe reads /d as decimal: the old value "26" wrote 0x1A and silently contradicted the 0x26 set by reg.reg
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl`" /v `"Win32PrioritySeparation`" /t REG_DWORD /d `"38`" /f >nul 2>&1"

# persistent foreground app process priority booster - whatever app has focus (the game) gets bumped to High
try {
# permanent folder, NOT C:\Windows\Temp - see the same note on the gpu boost script above
$persistentDir = "$env:ProgramData\Optimisation"
New-Item -Path $persistentDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$boosterScript = "$persistentDir\foregroundboost.ps1"
$boosterScriptContent = @'
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinSuxForeground {
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@
# never touch the shell, the compositor or the audio engine. audiodg already runs at High and starving
# it is what produces crackling and dropouts; dwm losing time against a boosted process produces the
# stutter this tweak is supposed to remove
$excluded = @('explorer','SearchHost','TextInputHost','ShellExperienceHost','StartMenuExperienceHost',
'dwm','audiodg','csrss','winlogon','services','lsass','svchost','SystemSettings','ApplicationFrameHost',
'LockApp','sihost','fontdrvhost','conhost','WindowsTerminal','taskmgr')
# remember what we changed so focus loss can put it back instead of leaving every app ever focused at High
$boosted = @{}
while ($true) {
try {
$hwnd = [WinSuxForeground]::GetForegroundWindow()
$procId = 0
[WinSuxForeground]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null

# restore anything that is no longer in the foreground
foreach ($oldId in @($boosted.Keys)) {
if ($oldId -ne $procId) {
$old = Get-Process -Id $oldId -ErrorAction SilentlyContinue
if ($old) { try { $old.PriorityClass = $boosted[$oldId] } catch { } }
$boosted.Remove($oldId)
}
}

if ($procId -gt 0) {
$proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
if ($proc -and $proc.ProcessName -notin $excluded -and $proc.PriorityClass -ne 'High') {
$boosted[$procId] = $proc.PriorityClass
# AboveNormal, not High: High competes with the audio engine and the compositor, which both sit
# at High themselves. AboveNormal wins against every ordinary background process without that risk
$proc.PriorityClass = 'AboveNormal'
}
}
} catch { }
# 2s instead of 500ms - the polling loop itself was waking the cpu 120 times a minute for nothing
Start-Sleep -Seconds 2
}
'@
Set-Content -Path $boosterScript -Value $boosterScriptContent -Force

$boosterAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$boosterScript`""
$boosterTrigger = New-ScheduledTaskTrigger -AtLogOn
$boosterSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Days 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "Foreground App Boost" -Action $boosterAction -Trigger $boosterTrigger -Settings $boosterSettings -Force -ErrorAction SilentlyContinue | Out-Null
Start-ScheduledTask -TaskName "Foreground App Boost" -ErrorAction SilentlyContinue
} catch { }

# reduce system timer jitter
cmd /c "bcdedit /set disabledynamictick yes >nul 2>&1"
cmd /c "bcdedit /set tscsyncpolicy Enhanced >nul 2>&1"
cmd /c "bcdedit /set useplatformclock false >nul 2>&1"

# modern interrupt controller mode - lower interrupt handling overhead on multi-core systems
cmd /c "bcdedit /set x2apicpolicy Enable >nul 2>&1"
cmd /c "bcdedit /set uselegacyapicmode false >nul 2>&1"

# fully disable the hypervisor/vbs at the boot level - complements the registry-level vbs removal, real cpu overhead reduction
cmd /c "bcdedit /set hypervisorlaunchtype off >nul 2>&1"
cmd /c "bcdedit /set vsmlaunchtype Off >nul 2>&1"

# skip boot menu delay and boot animation - shaves a few seconds off every boot
cmd /c "bcdedit /timeout 0 >nul 2>&1"
cmd /c "bcdedit /set bootux disabled >nul 2>&1"

# increase gpu timeout detection delay - avoids false "driver crashed" resets during long/heavy frame renders
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`" /v `"TdrDelay`" /t REG_DWORD /d `"8`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`" /v `"TdrDdiDelay`" /t REG_DWORD /d `"8`" /f >nul 2>&1"

# disable background services with no benefit for a gaming pc
cmd /c "sc stop `"DoSvc`" >nul 2>&1"
cmd /c "sc config `"DoSvc`" start= disabled >nul 2>&1"
cmd /c "sc stop `"NDU`" >nul 2>&1"
cmd /c "sc config `"NDU`" start= disabled >nul 2>&1"
cmd /c "sc stop `"PcaSvc`" >nul 2>&1"
cmd /c "sc config `"PcaSvc`" start= disabled >nul 2>&1"

# ------------------------------------------------------------------
# cpu - deeper scheduling / memory / interrupt tuning
# ------------------------------------------------------------------

# keep the kernel and drivers resident in ram instead of letting them be paged out (needs plenty of ram)
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`" /v `"DisablePagingExecutive`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
# workstation/gaming balance for the file cache - 0 favours process working sets over the system cache
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`" /v `"LargeSystemCache`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
# stop windows splitting every service into its own svchost process on machines with plenty of ram
try {
$ramKB = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control`" /v `"SvcHostSplitThresholdInKB`" /t REG_DWORD /d `"$ramKB`" /f >nul 2>&1"
} catch { }

# spread deferred procedure calls instead of serialising them
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`" /v `"ThreadDpcEnable`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# speculative-execution mitigations (spectre / meltdown / mds) tax every syscall and context switch.
# turning them off is worth a few percent of cpu time, mostly visible in cpu-bound frame times.
# SECURITY TRADE-OFF, deliberate: this machine already runs with defender, uac, vbs, smartscreen and the
# vulnerable driver blocklist disabled, so the mitigations were the last component still paying a
# permanent performance cost for a threat model this configuration has already abandoned.
# to undo: delete both values below, or set FeatureSettingsOverride to 0, then reboot
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`" /v `"FeatureSettingsOverride`" /t REG_DWORD /d `"3`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`" /v `"FeatureSettingsOverrideMask`" /t REG_DWORD /d `"3`" /f >nul 2>&1"

# prefetcher off - it only helps mechanical disks, and costs background io on an ssd
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters`" /v `"EnablePrefetcher`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters`" /v `"EnableSuperfetch`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# ntfs: stop updating a last-access timestamp on every single file read, give the mft room to grow,
# and let ntfs use more memory for its own caches
cmd /c "fsutil behavior set disablelastaccess 1 >nul 2>&1"
cmd /c "fsutil behavior set memoryusage 2 >nul 2>&1"
cmd /c "fsutil behavior set mftzone 2 >nul 2>&1"

# processor power policy - hold the cpu at full performance and react to load instantly
# PERFEPP 0        = energy/performance preference fully biased to performance (intel hwp / amd cppc)
# PERFINCPOL 2     = "rocket" ramp up, PERFDECPOL 1 = single step down
# PERFINCTHRESHOLD low + PERFDECTHRESHOLD low = raise frequency on the smallest load increase
# LATENCYHINTPERF 99 = ignore the "latency insensitive" hint that parks performance during light load
$procSub = "54533251-82be-4824-96c1-47b60b740d00"
$procTweaks = @(
@{Guid="36687f9e-e3a5-4dbf-b1dc-15eb381c6863"; Value=0},    # PERFEPP - energy performance preference
@{Guid="45bcc044-d885-43e2-8605-ee0ec6e96b59"; Value=0},    # PERFEPP1 - class 1 cores
@{Guid="465e1f50-b610-473a-ab58-00d1077dc418"; Value=2},    # PERFINCPOL - increase policy: rocket
@{Guid="40fbefc7-2e9d-4d25-a185-0cfd8574bac6"; Value=1},    # PERFDECPOL - decrease policy: single
@{Guid="06cadf0e-64ed-448a-8927-ce7bf90eb35d"; Value=10},   # PERFINCTHRESHOLD
@{Guid="12a0ab44-fe28-4fa9-b3bd-4b64f44960a6"; Value=8},    # PERFDECTHRESHOLD
@{Guid="984cf492-3bed-4488-a8f9-4286c97bf5aa"; Value=99},   # LATENCYHINTPERF
@{Guid="0cc5b647-c1df-4637-891a-dec35c318583"; Value=100},  # CPMINCORES - no core parking
@{Guid="ea062031-0e34-4ff1-9b6d-eb1059334028"; Value=100},  # CPMAXCORES
@{Guid="be337238-0d82-4146-a960-4f3749d470c7"; Value=0}     # PERFBOOSTPOL - boost policy
)
foreach ($tweak in $procTweaks) {
# unhide the setting first, several of these are hidden from powercfg.cpl by default
cmd /c "reg add `"HKLM\System\ControlSet001\Control\Power\PowerSettings\$procSub\$($tweak.Guid)`" /v `"Attributes`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 $procSub $($tweak.Guid) $($tweak.Value) >nul 2>&1"
cmd /c "powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 $procSub $($tweak.Guid) $($tweak.Value) >nul 2>&1"
}

# c-states are deliberately LEFT ON. disabling them (IDLEDISABLE) removes a few microseconds of
# wake-from-idle latency but keeps every core electrically active at idle, which raises idle temperature
# and package power permanently for no gain in frame times. the same reasoning applies to pinning the
# minimum processor state at 100% - see PROCTHROTTLEMIN further down, set to 5% for that reason.
# performance under load comes from EPP 0 + rocket ramp above, which react in microseconds anyway.
# make sure a previous run of this pack has not left idle disabled
cmd /c "powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 $procSub 5d76a2ca-e8c0-402f-a133-2158492d58ad 0 >nul 2>&1"
cmd /c "powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 $procSub 5d76a2ca-e8c0-402f-a133-2158492d58ad 0 >nul 2>&1"

# idle promotion/demotion thresholds: enter deeper c-states quickly when genuinely idle, leave them
# instantly under load. keeps temperatures down without adding latency where it matters
cmd /c "powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 $procSub 7b224883-b3cc-4d79-819f-8374152cbe7c 100 >nul 2>&1"
cmd /c "powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 $procSub 4b92d758-5a24-4851-a470-815d78aee119 20 >nul 2>&1"
cmd /c "powercfg /setactive 99999999-9999-9999-9999-999999999999 >nul 2>&1"

# ------------------------------------------------------------------
# gpu - interrupt mode, dpc latency and display stability
# ------------------------------------------------------------------

# message signaled interrupts + high device priority on the gpu: fewer shared-irq stalls, lower dpc latency
Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Enum\PCI" -ErrorAction SilentlyContinue |
Where-Object { $_.PSChildName -match 'VEN_10DE' } | ForEach-Object {
Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
$devicePath = ($_.Name -replace 'HKEY_LOCAL_MACHINE', 'HKLM')
cmd /c "reg add `"$devicePath\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties`" /v `"MSISupported`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg add `"$devicePath\Device Parameters\Interrupt Management\Affinity Policy`" /v `"DevicePriority`" /t REG_DWORD /d `"3`" /f >nul 2>&1"
}
}

# nvidia kernel driver: per-core dpc handling only.
# PerfLevelSrc=0x2222 and PowerMizerLevel=1 (previously set here) force the card into its maximum
# p-state permanently, including on an idle desktop - that is 20-30W and 10-15 degrees of idle heat for
# no benefit. the "prefer maximum performance" setting in the Inspector profile already holds the clocks
# up while a 3D application is actually running, which is where it matters.
# clear the forced values in case an earlier run of this pack wrote them
$nvClass = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
Get-ChildItem -Path $nvClass -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
$keyPath = ($_.Name -replace 'HKEY_LOCAL_MACHINE', 'HKLM')
cmd /c "reg add `"$keyPath`" /v `"RmGpsPsEnablePerCpuCoreDpc`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg delete `"$keyPath`" /v `"PerfLevelSrc`" /f >nul 2>&1"
cmd /c "reg delete `"$keyPath`" /v `"PowerMizerLevel`" /f >nul 2>&1"
cmd /c "reg delete `"$keyPath`" /v `"PowerMizerLevelAC`" /f >nul 2>&1"
}

# disable multiplane overlay - the single most common cause of flickering, black flashes and stuttering
# on nvidia + windows 11, especially with more than one monitor or mixed refresh rates
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\Dwm`" /v `"OverlayTestMode`" /t REG_DWORD /d `"5`" /f >nul 2>&1"

# make sure the multimedia scheduler never drops into its low-power lazy mode while a game has focus
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`" /v `"NoLazyMode`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`" /v `"AlwaysOn`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# disable storage sense - stops unpredictable background disk scans/cleanup that can interfere with the manual cleanup already done
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy`" /v `"01`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Peripheriques et audio" -PercentComplete 75
        Write-Host "Peripheriques et audio`n"

# disable mouse pointer acceleration (raw input, no smoothing)
cmd /c "reg add `"HKCU\Control Panel\Mouse`" /v `"MouseSpeed`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Control Panel\Mouse`" /v `"MouseThreshold1`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Control Panel\Mouse`" /v `"MouseThreshold2`" /t REG_SZ /d `"0`" /f >nul 2>&1"

# disable audio enhancements on all playback devices (reduces audio processing latency)
$audioRenderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
Get-ChildItem -Path $audioRenderPath -ErrorAction SilentlyContinue | ForEach-Object {
$regPath = $_.Name -replace 'HKEY_LOCAL_MACHINE', 'HKLM'
cmd /c "reg add `"$regPath\FxProperties`" /v `"{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5`" /t REG_DWORD /d `"1`" /f >nul 2>&1"
}

# reduce visual effects overhead (keep font smoothing, disable animations/transparency/shadows)
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects`" /v `"VisualFXSetting`" /t REG_DWORD /d `"3`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Control Panel\Desktop\WindowMetrics`" /v `"MinAnimate`" /t REG_SZ /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" /v `"TaskbarAnimations`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" /v `"ListviewAlphaSelect`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" /v `"ListviewShadow`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\DWM`" /v `"EnableAeroPeek`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`" /v `"EnableTransparency`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# ensure ssd trim is enabled
cmd /c "fsutil behavior set disabledeletenotify 0 >nul 2>&1"

# set pagefile to a static size to avoid resize stutters (8gb for 16gb+ ram systems, ram size otherwise)
try {
$ramMB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
if ($ramMB -ge 16384) { $pagefileSize = 8192 } else { $pagefileSize = [math]::Max(4096, $ramMB) }
$cs = Get-CimInstance Win32_ComputerSystem
Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$false} -ErrorAction Stop
$pfSetting = Get-CimInstance -Class Win32_PageFileSetting -Filter "Name='C:\\pagefile.sys'"
if ($pfSetting) {
Set-CimInstance -InputObject $pfSetting -Property @{InitialSize=$pagefileSize; MaximumSize=$pagefileSize} -ErrorAction Stop
} else {
New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="C:\pagefile.sys"; InitialSize=$pagefileSize; MaximumSize=$pagefileSize} -ErrorAction Stop | Out-Null
}
} catch { }

# disable telemetry service (diagtrack)
cmd /c "sc stop `"DiagTrack`" >nul 2>&1"
cmd /c "sc config `"DiagTrack`" start= disabled >nul 2>&1"

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Mode d'alimentation" -PercentComplete 81
        Write-Host "Mode d'alimentation`n"
        ## powercfg.cpl

# import ultimate power plan
cmd /c "powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1"

# set ultimate power plan active
cmd /c "powercfg /SETACTIVE 99999999-9999-9999-9999-999999999999 >nul 2>&1"

# get all powerplans
$output = powercfg /L
$powerPlans = @()
foreach ($line in $output) {

# extract guid manually to avoid language issues
if ($line -match ':') {
$parse = $line -split ':'
$index = $parse[1].Trim().indexof('(')
$guid = $parse[1].Trim().Substring(0, $index)
$powerPlans += $guid
}
}

# delete all powerplans
foreach ($plan in $powerPlans) {
cmd /c "powercfg /delete $plan 2>nul" | Out-Null
}

# disable hibernate
powercfg /hibernate off
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Power`" /v `"HibernateEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Power`" /v `"HibernateEnabledDefault`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable lock
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings`" /v `"ShowLockOption`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable sleep
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings`" /v `"ShowSleepOption`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable fast boot
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power`" /v `"HiberbootEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable power throttling
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling`" /v `"PowerThrottlingOff`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# cpu boost - aggressive-at-guaranteed mode: holds the cpu at its guaranteed boosted frequency more consistently, still within the cpu's own factory limits, no overclock
cmd /c "powercfg /setacvalueindex scheme_current sub_processor PERFBOOSTMODE 5 >nul 2>&1"
cmd /c "powercfg /setdcvalueindex scheme_current sub_processor PERFBOOSTMODE 5 >nul 2>&1"
cmd /c "powercfg /setactive scheme_current >nul 2>&1"

# note: core parking / minimum processor state is already forced to 100% further down (processor power management section)

# modify desktop & laptop settings
# hard disk turn off hard disk after 0%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0x00000000 2>$null

# desktop background settings slide show paused
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 001 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 001 2>$null

# wireless adapter settings power saving mode maximum performance
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 000 2>$null

# sleep
# sleep after 0%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0x00000000 2>$null

# allow hybrid sleep off
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 000 2>$null

# hibernate after
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0x00000000 2>$null

# allow wake timers disable
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 000 2>$null

# usb settings
# unhide hub selective suspend timeout
cmd /c "reg add `"HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683`" /v `"Attributes`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# hub selective suspend timeout 0
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0x00000000 2>$null

# usb selective suspend setting disabled
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000 2>$null

# unhide usb 3 link power management
cmd /c "reg add `"HKLM\System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009`" /v `"Attributes`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# usb 3 link power management - off
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 000 2>$null

# power buttons and lid start menu power button shut down
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 4f971e89-eebd-4455-a8de-9e59040e7347 a7066653-8d6c-40a8-910e-a1f54b84c7e5 002 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 4f971e89-eebd-4455-a8de-9e59040e7347 a7066653-8d6c-40a8-910e-a1f54b84c7e5 002 2>$null

# pci express link state power management off
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 000 2>$null

# processor power management
# minimum processor state 5% - deliberately NOT 100%.
# forcing 100% pins every core at its maximum multiplier permanently, including on an idle desktop:
# 15-25 degrees of extra idle temperature, and on modern cpus it actively COSTS performance, because a
# hotter package reaches its thermal/power limit sooner and boosts less far under real load.
# with EPP 0 and the rocket ramp policy set earlier, the cpu still reaches full clocks in microseconds.
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 0x00000005 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 0x00000005 2>$null

# system cooling policy active
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 001 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 001 2>$null

# maximum processor state 100%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 0x00000064 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 0x00000064 2>$null

# unhide processor performance core parking min cores
cmd /c "reg add `"HKLM\System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583`" /v `"Attributes`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# unpark cpu cores
# processor performance core parking min cores 100%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0x00000064 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0x00000064 2>$null

# unhide processor performance core parking max cores
cmd /c "reg add `"HKLM\System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028`" /v `"Attributes`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# unpark cpu cores
# processor performance core parking max cores 100%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 0x00000064 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 0x00000064 2>$null

# display
# turn off display after 10 min - oled protection
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 2>$null

# display brightness 100%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 aded5e82-b909-4619-9949-f5d71dac0bcb 0x00000064 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 aded5e82-b909-4619-9949-f5d71dac0bcb 0x00000064 2>$null

# dimmed display brightness 100%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 f1fbfde2-a960-4165-9f88-50667911ce96 0x00000064 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 f1fbfde2-a960-4165-9f88-50667911ce96 0x00000064 2>$null

# enable adaptive brightness off
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000 2>$null

# video playback quality bias video playback performance bias
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 001 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 001 2>$null

# when playing video optimize video quality
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 000 2>$null

# modify laptop settings
# intel(r) graphics settings intel(r) graphics power plan maximum performance
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 002 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 002 2>$null

# amd power slider overlay best performance
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 003 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 003 2>$null

# ati graphics power settings ati powerplay settings maximize performance
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 001 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 001 2>$null

# switchable dynamic graphics global settings maximize performance
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 003 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 003 2>$null

# battery
# critical battery notification off
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f 000 2>$null

# critical battery action do nothing
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 000 2>$null

# low battery level 0%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 0x00000000 2>$null

# critical battery level 0%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 0x00000000 2>$null

# low battery notification off
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f bcded951-187b-4d05-bccc-f7e51960c258 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f bcded951-187b-4d05-bccc-f7e51960c258 000 2>$null

# low battery action do nothing
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f d8742dcb-3e6a-4b3c-b3fe-374623cdcf06 000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f d8742dcb-3e6a-4b3c-b3fe-374623cdcf06 000 2>$null

# reserve battery level 0%
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f f3c5027d-cd16-4930-aa6b-90db844a8f00 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 e73a048d-bf27-4f12-9731-8b2076e8891f f3c5027d-cd16-4930-aa6b-90db844a8f00 0x00000000 2>$null

# immersive control panel
# low screen brightness when using battery saver disable
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 de830923-a562-41af-a086-e3a2c6bad2da 13d09884-f74e-474a-a852-b6bde8ad03a8 0x00000064 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 de830923-a562-41af-a086-e3a2c6bad2da 13d09884-f74e-474a-a852-b6bde8ad03a8 0x00000064 2>$null

# turn battery saver on automatically at never
powercfg /setacvalueindex 99999999-9999-9999-9999-999999999999 de830923-a562-41af-a086-e3a2c6bad2da e69653ca-cf7f-4f05-aa73-cb833fa90ad4 0x00000000 2>$null
powercfg /setdcvalueindex 99999999-9999-9999-9999-999999999999 de830923-a562-41af-a086-e3a2c6bad2da e69653ca-cf7f-4f05-aa73-cb833fa90ad4 0x00000000 2>$null

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Resolution du minuteur" -PercentComplete 88
        Write-Host "Resolution du minuteur`n"
        ## services.msc

# compile the service. the source is copied to C:\Windows\Temp by WinSux.ps1, but that folder is wiped
# by the disk cleanup step further down, so fall back to the copy next to this script if it is gone
$timerSource = "$env:SystemRoot\Temp\settimerresolutionservice.cs"
if (-not (Test-Path $timerSource) -and $PSScriptRoot) {
$alt = Join-Path $PSScriptRoot "settimerresolutionservice.cs"
if (Test-Path $alt) { $timerSource = $alt }
}
$timerBinary = "$env:SystemRoot\SetTimerResolutionService.exe"
$csc = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if ((Test-Path $csc) -and (Test-Path $timerSource)) {
Start-Process -Wait $csc -ArgumentList "-out:`"$timerBinary`" `"$timerSource`"" -WindowStyle Hidden
}

# remove old service if exists
if (Get-Service -Name "Set Timer Resolution Service" -ErrorAction SilentlyContinue) {
    cmd /c "sc delete `"Set Timer Resolution Service`" >nul 2>&1"
    Start-Sleep -Seconds 2
}

# install and start the service with sc.exe rather than New-Service. New-Service was failing silently
# here (-ErrorAction SilentlyContinue swallowed it), leaving the compiled binary on disk with no service
# registered at all - the timer resolution tweak then did nothing on every boot.
# sc.exe needs a space after each "option=" and the whole binPath quoted
if (Test-Path $timerBinary) {
cmd /c "sc create `"Set Timer Resolution Service`" binPath= `"$timerBinary`" start= auto DisplayName= `"Set Timer Resolution Service`" >nul 2>&1"
cmd /c "sc failure `"Set Timer Resolution Service`" reset= 0 actions= restart/5000 >nul 2>&1"
Start-Sleep -Seconds 1
cmd /c "sc start `"Set Timer Resolution Service`" >nul 2>&1"
Start-Sleep -Seconds 2
$timerSvc = Get-Service -Name "Set Timer Resolution Service" -ErrorAction SilentlyContinue
if ($timerSvc) {
Write-Host "  service resolution du minuteur : $($timerSvc.Status)`n"
} else {
Write-Host "  service resolution du minuteur : echec de l'enregistrement`n"
}
} else {
Write-Host "  service resolution du minuteur : compilation echouee, etape ignoree`n"
}

# enable global timer resolution requests
cmd /c "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`" /v `"GlobalTimerResolutionRequests`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# rebuild performance counters
        ## perfmon.msc
cmd /c "cd /d %systemroot%\system32 && lodctr /R >nul 2>&1"
cmd /c "cd /d %systemroot%\sysWOW64 && lodctr /R >nul 2>&1"


		Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Nettoyage de disque" -PercentComplete 94
		Write-Host "Nettoyage de disque`n"
		## cleanmgr.exe
		## %temp%
		## temp

# remove non-present ("ghost") devices left behind by old/removed hardware
try {
Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { -not $_.Present } | ForEach-Object {
cmd /c "pnputil /remove-device `"$($_.InstanceId)`" >nul 2>&1"
}
} catch { }

# clear windows update download cache
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

# clear prefetch
Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# clear thumbnail cache
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue | Out-Null

# empty recycle bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# clear %temp% folder
Remove-Item -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# clear temp folder
Remove-Item -Path "$env:SystemDrive\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# run disk cleanup
cleanmgr.exe /autoclean /d C:

# delete folders & files
Remove-Item "$env:SystemDrive\inetpub" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:SystemDrive\PerfLogs" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:SystemDrive\XboxGames" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:SystemDrive\DumpStack.log" -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Point de restauration" -PercentComplete 98
        Write-Host "Point de restauration`n"
        ## c:\windows\system32\control.exe sysdm.cpl ,4
        ## rstrui

try {
# allow multiple restore points
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore`" /v `"SystemRestorePointCreationFrequency`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# enable restore point
Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue | Out-Null

# create restore point
Checkpoint-Computer -Description "backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue | Out-Null

# revert allow multiple restore points
cmd /c "reg delete `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore`" /v `"SystemRestorePointCreationFrequency`" /f >nul 2>&1"
} catch { }

        Clear-Host
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Verification" -PercentComplete 100
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Completed

# ------------------------------------------------------------------
# validation report - checks what actually landed, not what was attempted
# ------------------------------------------------------------------
# every step above suppresses its own errors so the run never stops halfway. that means a step can fail
# in complete silence, which is how the timer resolution service ended up compiled but never registered.
# this re-reads the real system state and prints one line per check, then writes the same thing to a log
$checks = @()
function Add-Check([string]$label, [scriptblock]$test, [string]$detail = "") {
$ok = $false
try { $ok = [bool](& $test) } catch { $ok = $false }
$script:checks += [PSCustomObject]@{ Label = $label; Ok = $ok; Detail = $detail }
}

Add-Check "Pilote GPU NVIDIA installe" { (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like '*NVIDIA*' -and $_.DriverVersion }) -ne $null }
Add-Check "Panneau de configuration NVIDIA" { (Get-AppxPackage -AllUsers '*NVIDIAControlPanel*') -or (Test-Path "$env:ProgramFiles\NVIDIA Corporation\Control Panel Client") }
Add-Check "Service resolution du minuteur demarre" { (Get-Service -Name 'Set Timer Resolution Service' -ErrorAction SilentlyContinue).Status -eq 'Running' }
Add-Check "Plan Ultimate Performance actif" { (powercfg /getactivescheme) -match '99999999-9999-9999-9999-999999999999' }
Add-Check "HAGS (planification GPU materielle)" { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -ErrorAction SilentlyContinue).HwSchMode -eq 2 }
Add-Check "MPO desactive (anti-scintillement)" { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name OverlayTestMode -ErrorAction SilentlyContinue).OverlayTestMode -eq 5 }
Add-Check "Priorite premier plan (0x26)" { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name Win32PrioritySeparation -ErrorAction SilentlyContinue).Win32PrioritySeparation -eq 38 }
Add-Check "DPI non force (mise a l'echelle auto)" { -not (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name LogPixels -ErrorAction SilentlyContinue) }
Add-Check "UserPreferencesMask en REG_BINARY" { (Get-Item 'HKCU:\Control Panel\Desktop').GetValueKind('UserPreferencesMask') -eq 'Binary' }
Add-Check "VRR / G-Sync actif" { (Get-ItemProperty 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name DirectXUserGlobalSettings -ErrorAction SilentlyContinue).DirectXUserGlobalSettings -match 'VRROptimizeEnable=1' }
# power settings are read straight from the registry, not parsed out of powercfg /query. the query
# output is fully localised ("Index actuel du parametre de courant alternatif" on a french system), so
# any regex over it silently returns false on every non-english machine - and a hidden setting is not
# printed at all, which would make a "-not match" test pass no matter what the value actually is.
# a missing key means the setting is at its windows default, which is the healthy value in both cases
function Get-PowerAC([string]$subGuid, [string]$settingGuid, $default) {
$p = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\99999999-9999-9999-9999-999999999999\$subGuid\$settingGuid"
if (-not (Test-Path $p)) { return $default }
$v = (Get-ItemProperty $p -Name ACSettingIndex -ErrorAction SilentlyContinue).ACSettingIndex
if ($null -eq $v) { return $default } else { return [int]$v }
}
Add-Check "Etat processeur minimum <= 10% (idle sain)" { (Get-PowerAC '54533251-82be-4824-96c1-47b60b740d00' '893dee8e-2bef-41e0-89c6-b55d0929964c' 5) -le 10 }
Add-Check "Etat processeur maximum = 100%" { (Get-PowerAC '54533251-82be-4824-96c1-47b60b740d00' 'bc5038f7-23e0-4960-96da-33abaf5935ec' 100) -eq 100 }
Add-Check "Veille processeur (C-states) active" { (Get-PowerAC '54533251-82be-4824-96c1-47b60b740d00' '5d76a2ca-e8c0-402f-a133-2158492d58ad' 0) -eq 0 }
Add-Check "Core parking desactive" { (Get-PowerAC '54533251-82be-4824-96c1-47b60b740d00' '0cc5b647-c1df-4637-891a-dec35c318583' 100) -eq 100 }
Add-Check "Tache GPU Boost enregistree" { (Get-ScheduledTask -TaskName 'GPU Boost' -ErrorAction SilentlyContinue) -ne $null }
Add-Check "Tache Foreground App Boost active" { (Get-ScheduledTask -TaskName 'Foreground App Boost' -ErrorAction SilentlyContinue) -ne $null }
Add-Check "SysMain / DiagTrack desactives" { ((Get-Service SysMain -ErrorAction SilentlyContinue).StartType -eq 'Disabled') -and ((Get-Service DiagTrack -ErrorAction SilentlyContinue).StartType -eq 'Disabled') }
Add-Check "Reseau: Nagle desactive" { (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { (Get-ItemProperty $_.PSPath -Name TCPNoDelay -ErrorAction SilentlyContinue).TCPNoDelay }) -contains 1 }

$passed = @($checks | Where-Object { $_.Ok }).Count
$total = $checks.Count

Write-Host "========================================"
Write-Host "   RAPPORT DE VERIFICATION  $passed/$total"
Write-Host "========================================`n"
foreach ($c in $checks) {
if ($c.Ok) {
Write-Host ("  [ OK   ] " + $c.Label) -ForegroundColor Green
} else {
Write-Host ("  [ECHEC ] " + $c.Label) -ForegroundColor Red
}
}
Write-Host ""
if ($passed -lt $total) {
Write-Host "  $($total - $passed) verification(s) en echec - voir le journal ci-dessous`n" -ForegroundColor Yellow
} else {
Write-Host "  Toutes les verifications sont passees`n" -ForegroundColor Green
}

# write the same report next to the persistent scripts, where the disk cleanup cannot reach it
$logDir = "$env:ProgramData\Optimisation"
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = "$logDir\rapport.txt"
$log = @()
$log += "WinSux - rapport de verification"
$log += (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$log += "resultat : $passed/$total"
$log += ""
foreach ($c in $checks) { $log += ("{0,-8} {1}" -f $(if ($c.Ok) { "[OK]" } else { "[ECHEC]" }), $c.Label) }
$log | Set-Content -Path $logFile -Force -Encoding UTF8
Write-Host "  Journal : $logFile`n"

        Write-Host "Redemarrage dans 20 secondes`n"

# restart - long enough to actually read the report before the machine goes down
Start-Sleep -Seconds 20
shutdown -r -t 00
