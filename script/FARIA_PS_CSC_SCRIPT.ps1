<#
    Faria Powershell Custom Setup Config Script Win 10/11
	Essential Version
    Created by FARIA (github.com/faria4x)

		    @@@@@@@@@@@@@@@@@@@@@@@@@@
		   @@@@@@@@@@@@@@@@@@@@@@@@@@
	      @@@@@  @@@@@@@@@@@@@@@@@@@
	     @@@@@@@  @@@@@@@@@@@@@@@@@
	    @@@@@@@@@  @@@@@@@@@@@@@@@
	   @@@@@@@@  @@@@@@@@@@@@@@@@
	  @@@@@@@  @@@@@       @@@@@
	 @@@@@@@@@@@@@@@@@@@@@@@@@@
	@@@@@@@@@@@@@@@@@@@@@@@@@@

#>

# Relaunch as Admin if not already
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $IsAdmin) {
    Write-Host "Script not running as Administrator. Relaunching with elevated privileges..." -ForegroundColor Yellow

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Verb = "runas"

    if ($PSCommandPath) {
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        $scriptContent = $MyInvocation.MyCommand.Definition
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptContent))
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
    }

    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "User declined the UAC prompt. Exiting..." -ForegroundColor Red
    }
    exit
}

# ========================
#  CONFIGURATION TWEAKS
# ========================
$removeApps						= $true
$setPowerPlanUltimate     		= $true
$tweakGeneralExplorerAndOther	= $true
$disableTelemetry				= $true
$manageServices  				= $true
$forceDisableBitlocker			= $true
$installapps					= $false

# Detect Windows build information
$osInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

Write-Host "                                                                                       " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "             @@@@@@@@@@@@@@@@@@@@@@@@@@                                                " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "            @@@@@@@@@@@@@@@@@@@@@@@@@@                                                 " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "           @@@@@  @@@@@@@@@@@@@@@@@@@    Faria Powershell                              " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "          @@@@@@@  @@@@@@@@@@@@@@@@@        Custom Setup Config Script                 " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "         @@@@@@@@@  @@@@@@@@@@@@@@@                          for Win10/Win11           " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "        @@@@@@@@  @@@@@@@@@@@@@@@@                                                     " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "       @@@@@@@  @@@@@       @@@@@                                                      " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "      @@@@@@@@@@@@@@@@@@@@@@@@@@                                                       " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "     @@@@@@@@@@@@@@@@@@@@@@@@@@                                                        " -ForegroundColor DarkBlue -BackgroundColor Black
Write-Host "                                                                                       " -ForegroundColor DarkBlue -BackgroundColor Black

Write-Host "`n                                                                  " -ForegroundColor Green -BackgroundColor Black
Write-Host "     https://github.com/faria4x/faria-ps-csc-script               " -ForegroundColor Green -BackgroundColor Black
Write-Host "     FARIA                                                        " -ForegroundColor Green -BackgroundColor Black
Write-Host "                                                                  " -ForegroundColor Green -BackgroundColor Black

if ([int]$osInfo.CurrentBuildNumber -ge 22000) {
    $osName = "Windows 11"
} else {
    $osName = "Windows 10"
}
$displayVer = $osInfo.DisplayVersion
if (-not $displayVer) { $displayVer = $osInfo.ReleaseId }
Write-Host ("`nWindows OS Version Detected: {0} | {1} | {2} {3} | {4}`n" -f $osName, $osInfo.EditionID, $osInfo.DisplayVersion, $osInfo.ReleaseId, $osInfo.CurrentBuildNumber) -ForegroundColor Green -BackgroundColor Black

# ========================
#  BEFORE START ASK OPTIONAL
# ========================
Write-Host "Before start we will ask you if you would like these optional tasks" -ForegroundColor White -BackgroundColor Yellow
# DNS prompt
$setDnsYes = $false
$setDns = Read-Host "Set Quad9 (9.9.9.9) and Cloudflare (1.1.1.1) DNS Servers? [Y/N]: "
# Show Windows build at the bottom right of the desktop prompt
$winBuildDesktop = Read-Host "Show Windows build at the bottom right of the desktop? [Y/N]: "
# Enable Verbose Status (additional log information when shutting down/restarting Windows) prompt
$verboseS = Read-Host "Enable Verbose Status? (additional log information when shutting down/restarting Windows) [Y/N]: "
# ?? ASK USER INSTALL APPS prompt
$installapps = Read-Host "Do you wish to install extra essential apps? (7zip, Java, VLC Media Player, Microsoft Distributions/Redistributables, Powershell 7) [Y/N]: "
if ($installapps -match '^[Yy]$') {
	$installapps = $true
} else { 
	$installapps = $false
}

# ========================
#  START
# ========================
Write-Host "Script excuted and started! Recommended not to use your desktop while the script is running." -ForegroundColor White -BackgroundColor Green
$ErrorActionPreference = "SilentlyContinue"

# ========================
#  REMOVE UNWANTED/BLOAT APPS
# ========================
if ($removeApps) {
    Write-Host "Uninstalling unwanted/bloat apps..." -ForegroundColor White -BackgroundColor Blue

	$ProgressPreference = 'SilentlyContinue'

    $apps = @(
        "Microsoft.3DBuilder",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.MicrosoftSolitaireCollection",
		"Microsoft.BingSearch",
		"Microsoft.549981C3F5F10",		# Part of Cortana
        "Microsoft.Windows.Cortana",
		"Microsoft.Copilot",
        "Microsoft.BingNews",
		"Microsoft.BingWeather",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.MicrosoftOfficeHub",
		"Microsoft.Tips",
		"QuickAssist",
		"MicrosoftCorporationII.QuickAssist",
		"Microsoft.PowerAutomateDesktop",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.MicrosoftTeams",
		"MicrosoftTeams",
        "Microsoft.MicrosoftTeamsForSurfaceHub",
		"Microsoft.LinkedIn",
		"7EE7776C.LinkedInforWindows",
        "Microsoft.SkypeApp",
        "Microsoft.Todos",
        "Microsoft.WindowsMaps",
        "Microsoft.YourPhone",
		"Microsoft.Windows.DevHome",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.MicrosoftWhiteboard",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.ClipChamp",
        "Microsoft.Office.OneNote",
        "Microsoft.Office.Desktop",
        "Microsoft.MSPaint",              # Not to be confused with the normal Paint app, this is Paint 3D
        "Microsoft.MixedReality.Portal",
        "microsoft.windowscommunicationsapps",
		"Microsoft.OutlookForWindows",
		"Clipchamp.Clipchamp"
    )

    foreach ($app in $apps) {
        Write-Host "  Removing $app..." -ForegroundColor Cyan

		# Remove provisioned (prevents reinstall for new users)
        Get-AppxProvisionedPackage -Online | 
            Where-Object { $_.DisplayName -eq $app -or $_.PackageName -like "*$app*" } | 
            Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue | Out-Null

        # Remove installed for current + all users
        Get-AppxPackage -AllUsers -Name "*$app*" | 
            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }

	# Extra cleanup for stubborn apps
    Write-Host "  Removing any leftovers from bloat apps..." -ForegroundColor Cyan

    # Microsoft Teams cleanup
    Get-AppxPackage -AllUsers "*Teams*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*Teams*" } | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue

    # LinkedIn cleanup
    Get-AppxPackage -AllUsers "*LinkedIn*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*LinkedIn*" } | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue

    $ProgressPreference = 'Continue'

	# OneDrive
	Write-Host "  Checking for OneDrive installation..." -ForegroundColor Cyan
	function Get-OneDriveUninstallInfo {
		$keys = @(
			"HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
			"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
			"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
		)
		foreach ($k in $keys) {
			$entry = Get-ItemProperty $k -ErrorAction SilentlyContinue |
					 Where-Object { $_.DisplayName -eq "Microsoft OneDrive" } |
					 Select-Object -First 1
			if ($entry) { return $entry }
		}
		return $null
	}

	function Test-OneDriveInstalled {
		$reg = Get-OneDriveUninstallInfo
		if ($reg) { return $true }

		$appx = Get-AppxPackage -AllUsers -Name "Microsoft.OneDrive" -ErrorAction SilentlyContinue
		if (-not $appx) {
			$appx = Get-AppxPackage -AllUsers -Name "Microsoft.OneDriveSync" -ErrorAction SilentlyContinue
		}
		return [bool]$appx
	}

	function Invoke-OneDriveUninstall {
		$entry = Get-OneDriveUninstallInfo
		if ($entry -and $entry.UninstallString) {
			Write-Host "  Uninstalling OneDrive..." -ForegroundColor Cyan

			$cmdLine = $entry.UninstallString
			if ($cmdLine -match 'msiexec') {
				Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmdLine" -Wait -NoNewWindow
			} else {
				$exe  = $cmdLine
				$args = ""
				if ($cmdLine -match '^\s*\"([^"]+)\"\s*(.*)$') { $exe=$matches[1]; $args=$matches[2] }
				elseif ($cmdLine -match '^\s*(\S+)\s+(.*)$')    { $exe=$matches[1]; $args=$matches[2] }
				Start-Process -FilePath $exe -ArgumentList $args -Wait -NoNewWindow
			}
			return
		}

		$oneDriveSetup = @("$env:SystemRoot\SysWOW64\OneDriveSetup.exe", "$env:SystemRoot\System32\OneDriveSetup.exe") | Where-Object { Test-Path $_ -PathType Leaf }

		if ($oneDriveSetup) {
			Write-Host "  Uninstalling OneDrive..." -ForegroundColor Cyan
			taskkill /f /im OneDrive.exe > $null 2>&1
			foreach ($p in $oneDriveSetup) {
				Start-Process $p "/uninstall" -NoNewWindow -Wait
			}
		}
	}

    if (Test-OneDriveInstalled) {
        Invoke-OneDriveUninstall

        $folders = @(
            "$env:UserProfile\OneDrive",
            "$env:LocalAppData\Microsoft\OneDrive",
            "$env:ProgramData\Microsoft OneDrive"
        )
        foreach ($folder in $folders) {
            if (Test-Path $folder) {
                Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskPath "\Microsoft\OneDrive\" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\OneDrive\" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

        Write-Host "  OneDrive uninstalled." -ForegroundColor Cyan
    }
    else {
        Write-Host "  OneDrive is not installed. Skipping..." -ForegroundColor Cyan
    }
}

# ========================
#  POWER SETTINGS
# ========================
if ($setPowerPlanUltimate) {
    Write-Host "Setting power management options..." -ForegroundColor White -BackgroundColor Blue
	Write-Host "  Setting Ultimate Performance power plan..." -ForegroundColor Cyan

    $regPath      = "HKCU:\Software\F_PS_CSC_S"
    $regName      = "UltimatePlanGUID"
    $templateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"  # Microsoft Ultimate Power Plan Template
    $ultimateGUID = $null

    function Get-PowerSchemeGuids {
        $out = powercfg -list 2>$null
        $guids = @()
        foreach ($line in $out) {
            if ($line -match '([0-9A-Fa-f\-]{36})') {
                $guids += $matches[1].ToLower()
            }
        }
        return $guids
    }

    function New-UltimateFromTemplate {
        $before = Get-PowerSchemeGuids
        $dupOut = powercfg -duplicatescheme $templateGUID 2>&1
        $after  = Get-PowerSchemeGuids

        $new = $after | Where-Object { $before -notcontains $_ } | Select-Object -First 1
        if (-not $new) {
            $m = ($dupOut | Select-String -Pattern '([0-9A-Fa-f\-]{36})' | Select-Object -First 1)
            if ($m) { $new = $m.Matches[0].Value.ToLower() }
        }
        if (-not $new) { throw "Could not determine newly created plan GUID." }
        return $new
    }

    $saved = $null
    if (Test-Path $regPath) {
        $saved = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
        if ($saved) { $saved = $saved.ToLower() }
    }

    $existing = Get-PowerSchemeGuids
    if ($saved -and ($existing -contains $saved)) {
        $ultimateGUID = $saved
        Write-Host "  Loaded Ultimate plan GUID from registry and verified it exists: $ultimateGUID" -ForegroundColor Cyan
    }
    else {
        if ($saved -and -not ($existing -contains $saved)) {
            Write-Host "  Registry GUID not present anymore (plan deleted). Recreating..." -ForegroundColor Cyan
        } else {
            Write-Host "  No registry GUID found. Ensuring plan exists..." -ForegroundColor Cyan
        }

        if ($existing -contains $templateGUID) {
            $ultimateGUID = $templateGUID
            Write-Host "  Found existing Ultimate Performance plan from template GUID." -ForegroundColor Cyan
        } else {
            try {
                $ultimateGUID = New-UltimateFromTemplate
                Write-Host "  Created Ultimate Performance plan: $ultimateGUID" -ForegroundColor Cyan
            } catch {
                Write-Warning "Failed to create Ultimate Performance plan: $_"
            }
        }

        if ($ultimateGUID) {
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name $regName -Value $ultimateGUID
            Write-Host "  Saved Ultimate plan GUID to registry." -ForegroundColor Cyan
        }
    }

    # Activate the plan
    if ($ultimateGUID) {
        try {
            powercfg -setactive $ultimateGUID
            Write-Host "  Ultimate Performance plan activated." -ForegroundColor Cyan
        } catch {
            Write-Warning "Failed to activate Ultimate Performance plan. $_"
        }
    }
	
	Write-Host "  Disabling Fast Startup..." -ForegroundColor Cyan
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force

    # Set AC timeouts to never
    if ($ultimateGUID) {
        try {
            powercfg -change -monitor-timeout-ac 0
            powercfg -change -disk-timeout-ac 0
            powercfg -change -standby-timeout-ac 0
            powercfg -setacvalueindex $ultimateGUID SUB_VIDEO VIDEOIDLE 0

            powercfg -change -monitor-timeout-dc 0
            powercfg -change -disk-timeout-dc 0
            powercfg -change -standby-timeout-dc 0
            powercfg -setdcvalueindex $ultimateGUID SUB_VIDEO VIDEOIDLE 0

			Write-Host "  Timeouts (AC) and (DC) set to never for Ultimate plan." -ForegroundColor Cyan
        } catch {
            Write-Warning "Failed to set power plan timeout values. $_"
        }
    }
	
	# Disable USB selective suspend (AC + DC)
	$usbSubGroup         = "2a737441-1930-4402-8d77-b2bebba308a3"
	$usbSelectiveSuspend = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
	powercfg -setacvalueindex $ultimateGUID $usbSubGroup $usbSelectiveSuspend 0
	powercfg -setdcvalueindex $ultimateGUID $usbSubGroup $usbSelectiveSuspend 0
	powercfg -setactive $ultimateGUID
	Write-Host "  USB selective suspend disabled." -ForegroundColor Cyan

	Write-Host "  Changing power settings for network adapters..." -ForegroundColor Cyan

    $netAdapters = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -in @('802.3','Native 802.11') }

	# DNS prompt asked before START
    if ($setDns -match '^[Yy]$') { $setDnsYes = $true }

    foreach ($adapter in $netAdapters) {
        Write-Host "  Processing: $($adapter.Name)" -ForegroundColor Cyan

        try {
            $ifIndex = $adapter.InterfaceIndex

            # === Your existing power management settings ===
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
            $subKeys = Get-ChildItem $regPath -ErrorAction SilentlyContinue

            foreach ($key in $subKeys) {
                if ((Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue).DriverDesc -eq $adapter.InterfaceDescription) {
                    Set-ItemProperty -Path $key.PSPath -Name "PnPCapabilities" -Value 24 -Type DWord -Force
                    if (Get-ItemProperty -Path $key.PSPath -Name "WakeOnMagicPacket" -ErrorAction SilentlyContinue) {
                        Set-ItemProperty -Path $key.PSPath -Name "WakeOnMagicPacket" -Value 0 -Type DWord -Force
                    }
                    Start-Process -FilePath "powercfg.exe" -ArgumentList "/devicedisablewake", "$($adapter.Name)" -WindowStyle Hidden -NoNewWindow -Wait
                }
            }

            # === DISABLE NETBIOS OVER TCP/IP (Best current method) ===
            # Method 1: Modern cmdlet
            try {
                Set-NetTCPIPConfiguration -InterfaceIndex $ifIndex -NetbiosOptions 2 -ErrorAction Stop
                Write-Host "    NetBIOS disabled (Set-NetTCPIPConfiguration) for $($adapter.Name)" -ForegroundColor DarkGray
            }
            catch {
                # Method 2: Direct registry (very reliable)
                $nbtPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\tcpip$ifIndex"
                if (-not (Test-Path $nbtPath)) { New-Item -Path $nbtPath -Force | Out-Null }
                Set-ItemProperty -Path $nbtPath -Name "NetbiosOptions" -Value 2 -Type DWord -Force
                Write-Host "    NetBIOS disabled via registry for $($adapter.Name)" -ForegroundColor DarkGray
            }

            # === Disable LMHOSTS lookup (global) ===
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "EnableLMHOSTS" -Value 0 -Type DWord -Force

            # === DNS Settings ===
            if ($setDnsYes) {
                try {
                    Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @("9.9.9.9", "1.1.1.1")
                    Write-Host "    DNS set successfully" -ForegroundColor DarkGray
                } catch {
                    Write-Host "    Failed to set DNS for $($adapter.Name)" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Warning "Error processing $($adapter.Name): $_"
        }
    }

    Write-Host "  Network configuration completed (NetBIOS + LMHOSTS disabled)." -ForegroundColor Green
}

# ========================
#  FILE EXPLORER, DESKTOP, TASKBAR AND OTHER MISC STUFF...
# ========================
if ($tweakGeneralExplorerAndOther) {
    Write-Host "Configuring File Explorer, Desktop, Taskbar and other misc stuff..." -ForegroundColor White -BackgroundColor Blue

    # Basic Explorer tweaks
	Write-Host "  Configuring file explorer settings..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name NavPaneShowLibraries -Value 1 -Type DWord

	# Check "Allow files on this drive to have contents indexed in addition to file properties" option in the properties of the Windows local drive
	$drive = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter = 'C:'"
	if ($drive) {
		$drive.IndexingEnabled = $true
		$drive.Put() | Out-Null
	} else {
		Write-Warning "Could not find C: drive object"
	}

    # Classic desktop icons
	Write-Host "  Configuring desktop settings..." -ForegroundColor Cyan
    $desktopIcons = @{
		"{59031a47-3f72-44a7-89c5-5595fe6b30ee}" = 0  # User's Files Folder
        "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" = 0  # This PC/Computer
        "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" = 0  # Network
		"{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" = 0  # Control Panel
        "{645FF040-5081-101B-9F08-00AA002F954E}" = 0  # Recycle Bin
    }

    foreach ($iconGuid in $desktopIcons.Keys) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name $iconGuid -Value $desktopIcons[$iconGuid] -Type DWord
    }
	
	# Desktop icon size: 32 = Small, 48 = Medium, 96 = Large
	$bagPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
	if (-not (Test-Path $bagPath)) { New-Item -Path $bagPath -Force | Out-Null }
	Set-ItemProperty -Path $bagPath -Name "IconSize" -Value 32 -Type DWord -Force

	# Restore right-click old context menu
	New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Force | Out-Null
	New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
	Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)" -Value "" -Force

	# Show Windows build at the bottom right of the desktop prompt before START
	if ($winBuildDesktop -match '^[Yy]$') {
		Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "PaintDesktopVersion" -Type DWord -Value 1 -Force
	} else { <# Nothing #> }

	# Disable Spotlight
	$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
	if (-not (Test-Path $cdmPath)) { New-Item -Path $cdmPath -Force | Out-Null }
	Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0 -Force  # Desktop Spotlight off
	Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0 -Force  # Lock bleed-over off
	Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenEnabled"     -Type DWord -Value 0 -Force
	
	$spotlightSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings"
	if (-not (Test-Path $spotlightSettingsPath)) { New-Item -Path $spotlightSettingsPath -Force | Out-Null }
	Set-ItemProperty -Path $spotlightSettingsPath -Name "EnabledState" -Type DWord -Value 0 -Force
	
	# Clear Spotlight cache (prevents old images/state from reloading)
	$cachePaths = @(
		"$env:LocalAppData\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets",
		"$env:LocalAppData\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\RoamingState",
		"$env:LocalAppData\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache\Microsoft\IrisService"
	)
	foreach ($path in $cachePaths) {
		if (Test-Path $path) {
			Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
		}
	}

	$themeReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
	# Determine dark mode (1 = light mode, 0 = dark mode)
    $isLightMode = (Get-ItemProperty -Path $themeReg -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme

	# Set wallpaper path depending of which Windows version
	if ($osInfo.CurrentBuildNumber -ge 22000) {
		# Windows 11 default
		if ($isLightMode -eq 1) {
            $wallpaperPath = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
        } else {
            $wallpaperPath = "C:\Windows\Web\Wallpaper\Windows\img19.jpg"
        }
	} else {
		# Windows 10 default
		$wallpaperPath = "C:\Windows\Web\4K\Wallpaper\Windows\img0_3840x2160.jpg"
	}
	
	$wallpaperModePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"
	if (-not (Test-Path $wallpaperModePath)) { New-Item -Path $wallpaperModePath -Force | Out-Null }

	# DEFAULT WINDOWS WALLPAPER
	# Wallpaper Mode set to Image
	Set-ItemProperty -Path $wallpaperModePath -Name "BackgroundType" -Type DWord -Value 0 -Force
	# Set wallpaper
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $wallpaperPath -Force

	Write-Host "  Configuring taskbar settings..." -ForegroundColor Cyan

	# Taskbar search display set to icon (Windows 10)
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 -Type DWord

	# Taskbar search display set to icon (Windows 11)
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSearchMode" -Value 1 -Type DWord
	
	# Enable "End task" in app right-click menu taskbar (Only on Windows 11)
	New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force | Out-Null
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name TaskbarEndTask -Type DWord -Value 1

	# Taskbar start button, pinned and opened Apps, search filed bar set alignment to the left (Only on Windows 11)
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0

	# Set Performance options preset to "Best Performance" to "Custom"
	Write-Host "  Applying custom set performance options..." -ForegroundColor Cyan
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -Type DWord -Value 2
	Start-Sleep -Milliseconds 500
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -Type DWord -Value 3

	# Default "best performance" UserPreferencesMask
	$PerfMask = [byte[]](144, 18, 3, 128, 16, 0, 0, 0)
	Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name UserPreferencesMask -Value $PerfMask

	# Enable/Check 'Animate controls and elements inside windows'
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations' -Name "DefaultApplied" -Type DWord -Value 1
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations' -Name "DefaultValue" -Type DWord -Value 1
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations' -Name "Value" -Type DWord -Value 1

	# Disable/Uncheck 'Animate windows when minimising and maximising'
	Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name "MinAnimate" -Type String -Value "0"

	# Disable/Uncheck 'Enable Peek'
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name "EnableAeroPeek" -Type DWord -Value 0

	# Enable/Check 'Show thumbnails instead of icons'
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "IconsOnly" -Type DWord -Value 0

	# Enable/Check 'Show translucent selection rectangle'
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "ListviewAlphaSelect" -Type DWord -Value 1

	# Enable/Check 'Show window contents while dragging'
	Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "DragFullWindows" -Type String -Value "1"

	# Enable/Check 'Smooth edges of screen fonts'
	Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "FontSmoothing" -Type String -Value "2"
	Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "FontSmoothingType" -Type DWord -Value 2

	# Enable/Check 'Use drop shadows for icon labels'
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "ListviewShadow" -Type DWord -Value 1

	# Disable taskbar animations
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "TaskbarAnimations" -Type DWord -Value 0

	# Enable Verbose Status (additional log information when shutting down/restarting Windows) prompt before START
	if ($verboseS -match '^[Yy]$') {
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force | Out-Null
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "verbosestatus" -Type DWord -Value 1 -Force
	} else { <# Nothing #> }

    # Restart explorer.exe and Desktop to apply changes
	Write-Host "  Restarting Explorer and Desktop..." -ForegroundColor Cyan
	# Restart desktop
	RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
	# Restart explorer.exe
    Stop-Process -Name explorer -Force

	# Enable DirectPlay. This is for some old games/software (for example: GTA San Andreas)
	Write-Host "  Enabling legacy feature 'DirectPlay'..." -ForegroundColor Cyan
	try {
		DISM /Online /Enable-Feature /FeatureName:DirectPlay /All /NoRestart | Out-Null
	} catch {
		Write-Warning "Failed to enable DirectPlay: $_"
	}
}

# ========================
#  DISABLE TELEMETRY
# ========================
if ($disableTelemetry) {
    Write-Host "Disabling Microsoft Telemetry & Cortana..." -ForegroundColor White -BackgroundColor Blue
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Value 0
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
	Write-Host "  Microsoft Telemtry & Cortana disabled." -ForegroundColor Cyan
}

# ========================
#  OPTIMIZING SERVICES
# ========================
if ($manageServices) {
    Write-Host "Optimizing services..." -ForegroundColor White -BackgroundColor Blue

	$logDir = "$env:ProgramData\FariaSetup"
	New-Item -Path $logDir -ItemType Directory -Force | Out-Null
	Get-Service | Select-Object Name, DisplayName, Status, StartType |
		Export-Csv "$logDir\services-before.csv" -NoTypeInformation

	function Set-SvcStartup {
		param([string]$Name, [string]$Type)
		if (-not (Get-Service -Name $Name -ErrorAction SilentlyContinue)) { return }  # not on this build
		try {
			Set-Service -Name $Name -StartupType $Type -ErrorAction Stop
			Write-Host "  $Name -> $Type" -ForegroundColor Cyan
		} catch {
			Write-Warning "Could not set $Name to $Type"
		}
	}

	$autoServices    = @("Spooler","W32Time","WlanSvc","LanmanWorkstation","LanmanServer")
	$manualServices  = @("SysMain","TrkWks","DoSvc","WerSvc","Fax","XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc")
	$disableServices = @("DiagTrack","RemoteRegistry","RetailDemo","MapsBroker","PhoneSvc",
						 "WalletService","WpcMonSvc","WMPNetworkSvc","SharedAccess")

	foreach ($s in $autoServices)    { Set-SvcStartup $s "Automatic" }
	foreach ($s in $manualServices)  { Set-SvcStartup $s "Manual" }
	foreach ($s in $disableServices) { Set-SvcStartup $s "Disabled" }

	Get-Service | Select-Object Name, DisplayName, Status, StartType |
		Export-Csv "$logDir\services-after.csv" -NoTypeInformation
	
	Write-Host "  All services optimized and set." -ForegroundColor Cyan
}

# ========================
#  FORCE DISABLE BITLOCKER
# ========================
if ($forceDisableBitlocker) {
	Write-Host "[Status]: Disabling BitLocker..." -ForegroundColor White -BackgroundColor Blue
	try {
        $volumes = Get-BitLockerVolume
        $needsAction = $false

        foreach ($vol in $volumes) {
            $mount = $vol.MountPoint
            $status = $vol.VolumeStatus
            $protection = $vol.ProtectionStatus
            $percent = $vol.EncryptionPercentage

            Write-Host "Drive $mount - Status: $status, Protection: $protection, Encrypted: $percent%  " -ForegroundColor Cyan

            if ($status -eq "FullyEncrypted" -or $status -eq "EncryptionInProgress" -or $protection -eq "On") {
                $needsAction = $true
                Write-Host "Drive $mount encrypted. Starting decryption...  " -ForegroundColor Black -BackgroundColor Yellow
                Disable-BitLocker -MountPoint $mount -ErrorAction Continue

                $protectors = $vol.KeyProtector
                foreach ($p in $protectors) {
                    Remove-BitLockerKeyProtector -MountPoint $mount -KeyProtectorId $p.KeyProtectorId -ErrorAction Continue
                }
            }
        }

        if (-not $needsAction) {
            Write-Host "  BitLocker is already off." -ForegroundColor Cyan
        } else {
            # Wait for decryption to complete
            Write-Host "Decrypting drive...  " -ForegroundColor Black -BackgroundColor Yellow
            do {
                Start-Sleep -Seconds 30
                $stillWorking = Get-BitLockerVolume | Where-Object { $_.VolumeStatus -eq "DecryptionInProgress" -or $_.VolumeStatus -eq "FullyEncrypted" }
                if ($stillWorking) {
                    $percent = $stillWorking[0].EncryptionPercentage
                    Write-Host "Progress: $percent% remaining on $($stillWorking[0].MountPoint)  " -ForegroundColor Black -BackgroundColor Yellow
                }
            } while ($stillWorking)

            Write-Host "  Decryption completed on all drives." -ForegroundColor Cyan
        }

        Set-Service -Name "defragsvc" -StartupType Disabled -ErrorAction Continue
        Stop-Service -Name "defragsvc" -Force -ErrorAction Continue

        Write-Host "  BitLocker fully disabled." -ForegroundColor Cyan

        manage-bde -status
    }
    catch {
        Write-Error "Error: $_"
    }
}

# ?? ASK USER INSTALL APPS prompt before START
# ========================
#  INSTALL ESSENTIAL APPS
# ========================
if ($installapps) {
    Write-Host "Installing new apps..." -ForegroundColor White -BackgroundColor Blue

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found (normal in audit mode / before App Installer is available). Skipping app installs."
    }
    else {
        $apps = @(
            "Microsoft.VCRedist.2005.x86",
			"Microsoft.VCRedist.2005.x64",
			"Microsoft.VCRedist.2008.x86",
			"Microsoft.VCRedist.2008.x64",
			"Microsoft.VCRedist.2010.x86",
			"Microsoft.VCRedist.2010.x64",
			"Microsoft.VCRedist.2012.x86",
			"Microsoft.VCRedist.2012.x64",
			"Microsoft.VCRedist.2013.x86",
			"Microsoft.VCRedist.2013.x64",
			"Microsoft.VCRedist.2015+.x86",
			"Microsoft.VCRedist.2015+.x64",
			"Microsoft.DotNet.DesktopRuntime.3_1",
			"Microsoft.DotNet.DesktopRuntime.5",
			"Microsoft.DotNet.DesktopRuntime.6",
			"Microsoft.DotNet.DesktopRuntime.7",
			"Microsoft.DotNet.DesktopRuntime.8",
			"Microsoft.DotNet.DesktopRuntime.9",
			"Microsoft.DotNet.Runtime.3_1",
			"Microsoft.DotNet.Runtime.5",
			"Microsoft.DotNet.Runtime.6",
			"Microsoft.DotNet.Runtime.7",
			"Microsoft.DotNet.Runtime.8",
			"Microsoft.DotNet.Runtime.9",
			"Microsoft.DotNet.AspNetCore.3_1",
			"Microsoft.DotNet.AspNetCore.5",
			"Microsoft.DotNet.AspNetCore.6",
			"Microsoft.DotNet.AspNetCore.7",
			"Microsoft.DotNet.AspNetCore.8",
			"Microsoft.DotNet.AspNetCore.9",
			"Microsoft.DirectX",
			"Microsoft.PowerShell",
			"Oracle.JavaRuntimeEnvironment",
			"7zip.7zip",
			"Notepad++.Notepad++",
			"VideoLAN.VLC"
        )

        foreach ($app in $apps) {
            # winget returns a non-zero exit code when the package isn't installed
            winget list --id $app -e --accept-source-agreements 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  $app already installed. Skipping..." -ForegroundColor Cyan
                continue
            }

            Write-Host "  Installing $app..." -ForegroundColor Cyan
            winget install --id $app -e --silent --accept-source-agreements --accept-package-agreements --disable-interactivity --no-upgrade | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  $app installed successfully!" -ForegroundColor Cyan
            } else {
                Write-Warning "Failed to install $app (exit code $LASTEXITCODE)"
            }
        }
    }
}

# ========================
#  END
# ========================
Write-Host "`n"
Write-Host "Script completed! Windows needs to restart for all applied settings changes to have full effect!" -ForegroundColor White -BackgroundColor Green
$restart = Read-Host "Restart your PC now? (Y/N): "

if ($restart -match '^[Yy]$') {
    Write-Host "Restarting your PC..." -ForegroundColor Green
    Restart-Computer -Force
} else {
    Write-Host "Understood. Remember to restart your PC later!" -ForegroundColor Green
}