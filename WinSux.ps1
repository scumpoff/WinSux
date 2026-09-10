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

        # SCRIPT CHECK INTERNET
        if (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host "Connexion Internet requise`n"
        Pause
        exit
        }

# capture the gpu name now, before ddu wipes the driver - after ddu runs, windows reports a generic
# "Microsoft Basic Display Adapter" name until a driver is reinstalled, so this must happen first
try {
$nvidiaGpuName = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*NVIDIA*" } | Select-Object -First 1).Name
if ($nvidiaGpuName) { Set-Content -Path "$env:SystemRoot\Temp\gpuname.txt" -Value $nvidiaGpuName -Force }
} catch { }

        Write-Host "Telechargement`n"
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Telechargement" -PercentComplete 0

# use local temp files if running from a cloned folder, otherwise download from github
$repo = "scumpoff/WinSux"
$path = "Temp"
$dest = "$env:SystemRoot\Temp"
$useLocal = $false
if (-not [string]::IsNullOrEmpty($PSScriptRoot)) {
$localTemp = Join-Path $PSScriptRoot "Temp"
if (Test-Path $localTemp) { $useLocal = $true }
}
if ($useLocal) {
Copy-Item -Path "$localTemp\*" -Destination $dest -Force
} else {
$files = (IRM "https://api.github.com/repos/$repo/contents/$path").download_url
$totalFiles = $files.Count
$i = 0
foreach ($url in $files) {
$i++
$filename = $url.Split("/")[-1]
Write-Progress -Id 2 -ParentId 1 -Activity "Telechargement des fichiers" -Status "$filename ($i/$totalFiles)" -PercentComplete (($i / $totalFiles) * 100)
$oldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
IWR $url -OutFile "$dest\$filename"
$ProgressPreference = $oldProgressPreference
}
Write-Progress -Id 2 -Activity "Telechargement des fichiers" -Completed
}

        Write-Host "Installation de 7-Zip`n"
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Installation de 7-Zip" -PercentComplete 20
        ## explorer "https://www.7-zip.org"

# install 7zip
Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"

# set config for 7zip
cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"
cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# cleaner 7zip start menu shortcut path
Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Host "Installation de C++`n"
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Installation de C++" -PercentComplete 40
		## explorer "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170"

# install c++
$vcredists = @(
@{File="vcredist2005_x86.exe"; Args="/Q /C:`"msiexec /i vcredist.msi /qn /norestart`""},
@{File="vcredist2005_x64.exe"; Args="/Q /C:`"msiexec /i vcredist.msi /qn /norestart`""},
@{File="vcredist2008_x86.exe"; Args="/q"},
@{File="vcredist2008_x64.exe"; Args="/q"},
@{File="vcredist2010_x86.exe"; Args="/quiet /norestart"},
@{File="vcredist2010_x64.exe"; Args="/quiet /norestart"},
@{File="vcredist2012_x86.exe"; Args="/quiet /norestart"},
@{File="vcredist2012_x64.exe"; Args="/quiet /norestart"},
@{File="vcredist2013_x86.exe"; Args="/quiet /norestart"},
@{File="vcredist2013_x64.exe"; Args="/quiet /norestart"},
@{File="vcredist2015_2017_2019_2022_x86.exe"; Args="/quiet /norestart"},
@{File="vcredist2015_2017_2019_2022_x64.exe"; Args="/quiet /norestart"}
)
$totalVc = $vcredists.Count
$i = 0
foreach ($vc in $vcredists) {
$i++
Write-Progress -Id 2 -ParentId 1 -Activity "Installation de C++" -Status "$($vc.File) ($i/$totalVc)" -PercentComplete (($i / $totalVc) * 100)
Start-Process -Wait "$env:SystemRoot\Temp\$($vc.File)" -ArgumentList $vc.Args -WindowStyle Hidden
}
Write-Progress -Id 2 -Activity "Installation de C++" -Completed

        Write-Host "DDU`n"
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Extraction de DDU" -PercentComplete 60
        ## explorer "https://www.wagnardsoft.com/display-driver-uninstaller-ddu"

# extract ddu with 7zip
& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$env:SystemRoot\Temp\ddu.exe" -o"$env:SystemRoot\Temp\ddu" -y | Out-Null

# set config for ddu
$DduConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<DisplayDriverUninstaller Version="18.1.4.2">
	<Settings>
		<SelectedLanguage>en-US</SelectedLanguage>
		<RemoveMonitors>True</RemoveMonitors>
		<RemoveCrimsonCache>True</RemoveCrimsonCache>
		<RemoveAMDDirs>True</RemoveAMDDirs>
		<RemoveAudioBus>True</RemoveAudioBus>
		<RemoveAMDKMPFD>True</RemoveAMDKMPFD>
		<RemoveNvidiaDirs>True</RemoveNvidiaDirs>
		<RemovePhysX>True</RemovePhysX>
		<Remove3DTVPlay>True</Remove3DTVPlay>
		<RemoveGFE>True</RemoveGFE>
		<RemoveNVBROADCAST>True</RemoveNVBROADCAST>
		<RemoveNVCP>True</RemoveNVCP>
		<RemoveINTELCP>True</RemoveINTELCP>
		<RemoveINTELIGS>True</RemoveINTELIGS>
		<RemoveOneAPI>True</RemoveOneAPI>
		<RemoveEnduranceGaming>True</RemoveEnduranceGaming>
		<RemoveIntelNpu>True</RemoveIntelNpu>
		<RemoveAMDCP>True</RemoveAMDCP>
		<UseRoamingConfig>False</UseRoamingConfig>
		<CheckUpdates>False</CheckUpdates>
		<CreateRestorePoint>False</CreateRestorePoint>
		<SaveLogs>False</SaveLogs>
		<RemoveVulkan>True</RemoveVulkan>
		<ShowOffer>False</ShowOffer>
		<EnableSafeModeDialog>False</EnableSafeModeDialog>
		<PreventWinUpdate>True</PreventWinUpdate>
		<UsedBCD>False</UsedBCD>
		<KeepNVCPopt>False</KeepNVCPopt>
		<RememberLastChoice>False</RememberLastChoice>
		<LastSelectedGPUIndex>0</LastSelectedGPUIndex>
		<LastSelectedTypeIndex>0</LastSelectedTypeIndex>
	</Settings>
</DisplayDriverUninstaller>
'@
Set-Content -Path "$env:SystemRoot\Temp\ddu\Settings\Settings.xml" -Value $DduConfig -Force

# set ddu config to read only
Set-ItemProperty -Path "$env:SystemRoot\Temp\ddu\Settings\Settings.xml" -Name IsReadOnly -Value $true

# prevent downloads of drivers from windows update
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`" /v `"SearchOrderConfig`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

        Write-Host "Installation de DirectX`n"
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Installation de DirectX" -PercentComplete 80
        ## explorer "https://www.microsoft.com/en-au/download/details.aspx?id=35"

# extract directx with 7zip
& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$env:SystemRoot\Temp\directx.exe" -o"$env:SystemRoot\Temp\directx" -y | Out-Null

# install directx
Start-Process -Wait "$env:SystemRoot\Temp\directx\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden

# allow password sign in
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device`" /v `"DevicePasswordLessBuildVersion`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable open terminal by default
cmd /c "reg add `"HKCU\Console\%%Startup`" /v `"DelegationConsole`" /t REG_SZ /d `"{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Console\%%Startup`" /v `"DelegationTerminal`" /t REG_SZ /d `"{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}`" /f >nul 2>&1"

# install runonce stepone ps1 file to run in safe boot
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*!stepone`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\stepone.ps1`" /f >nul 2>&1"

# install runonce steptwo ps1 file to run in normal boot
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"!steptwo`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\steptwo.ps1`" /f >nul 2>&1"

# turn on safe boot
cmd /c "bcdedit /set {current} safeboot minimal >nul 2>&1"

        Write-Progress -Id 1 -Activity "Optimisation en cours" -Status "Redemarrage" -PercentComplete 100
        Write-Progress -Id 1 -Activity "Optimisation en cours" -Completed
        Write-Host "Redemarrage`n"

# restart
Start-Sleep -Seconds 5
shutdown -r -t 00