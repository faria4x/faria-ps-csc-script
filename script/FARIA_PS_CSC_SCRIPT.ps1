<#
    Faria Powershell Custom Setup Config Script Win 10/11
	Essential Version
    Created by FARIA (github.com/faria4x)
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
#  LOGGING
# ========================
# Everything the script prints is saved here, so you can see what ran on each PC.
$logDir = "$env:TEMP\F_PS_CSC_S"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
try { Start-Transcript -Path "$logDir\setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Append | Out-Null } catch { }

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

# ========================
#  HELPER FUNCTIONS
# ========================

# Write a registry value, creating the key if it does not exist yet.
# (Set-ItemProperty alone fails on missing keys, which is common in the Default user hive.)
function Set-Reg {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [AllowEmptyString()]$Value,
        [ValidateSet("DWord","String","Binary","ExpandString","QWord")][string]$Type = "DWord"
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
    } catch {
        Write-Warning "Registry write failed: $Path\$Name ($($_.Exception.Message))"
    }
}

# Runs a scriptblock twice:
#   1) against the CURRENT user (HKCU)  - in audit mode this is the built-in Administrator
#   2) against the DEFAULT user profile  - every account created afterwards inherits these settings
# The scriptblock receives the registry root as its first parameter ($root).
function Invoke-ForUserHives {
    param([Parameter(Mandatory)][scriptblock]$Action)

    # 1) Current user
    & $Action "HKCU:"

    # 2) Default profile
    $ntuser   = "$env:SystemDrive\Users\Default\NTUSER.DAT"
    $hiveName = "DefaultUser"
    $hiveKey  = "HKU\$hiveName"
    $hivePath = "Registry::HKEY_USERS\$hiveName"

    if (-not (Test-Path -LiteralPath $ntuser)) {
        Write-Warning "Default user hive not found ($ntuser). New users will NOT get these settings."
        return
    }

    # Leftover from an interrupted earlier run
    if (Test-Path -LiteralPath $hivePath) { reg unload $hiveKey 2>&1 | Out-Null }

    reg load $hiveKey $ntuser 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not load the Default user hive. New users will NOT get these settings."
        return
    }

    try {
        & $Action $hivePath
    }
    finally {
        # Unload fails while a handle is still open, so collect garbage and retry
        $unloaded = $false
        for ($i = 0; $i -lt 10 -and -not $unloaded; $i++) {
            [gc]::Collect(); [gc]::WaitForPendingFinalizers()
            reg unload $hiveKey 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $unloaded = $true } else { Start-Sleep -Seconds 1 }
        }
        if (-not $unloaded) { Write-Warning "Could not unload the Default user hive. Reboot before running sysprep." }
    }
}

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
# ASK USER INSTALL APPS prompt
$installapps = Read-Host "Do you wish to install extra essential apps? (7zip, Java, VLC Media Player, Microsoft Distributions/Redistributables, Powershell 7) [Y/N]: "
if ($installapps -match '^[Yy]$') { $installapps = $true } else { $installapps = $false }

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
				$exe      = $cmdLine
				$procArgs = ""
				if ($cmdLine -match '^\s*\"([^"]+)\"\s*(.*)$') { $exe=$matches[1]; $procArgs=$matches[2] }
				elseif ($cmdLine -match '^\s*(\S+)\s+(.*)$')    { $exe=$matches[1]; $procArgs=$matches[2] }
				Start-Process -FilePath $exe -ArgumentList $procArgs -Wait -NoNewWindow
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
            if (-not (Test-Path $folder)) { continue }

            # Safety net: never delete a user's OneDrive folder if it contains files
            if ($folder -eq "$env:UserProfile\OneDrive") {
                if (Get-ChildItem $folder -Recurse -File -Force -ErrorAction SilentlyContinue | Select-Object -First 1) {
                    Write-Warning "  $folder contains files - not deleting it."
                    continue
                }
            }
            Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Hide the OneDrive entry in the Explorer navigation pane (HKLM\SOFTWARE\Classes = what HKCR shows)
        Set-Reg "HKLM:\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
        Set-Reg "HKLM:\SOFTWARE\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0

        Get-ScheduledTask -TaskPath "\Microsoft\OneDrive\" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\OneDrive\" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        # The real OneDrive update tasks live in the root task folder
        Get-ScheduledTask -TaskName "OneDrive*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

        Write-Host "  OneDrive uninstalled." -ForegroundColor Cyan
    }
    else {
        Write-Host "  OneDrive is not installed. Skipping..." -ForegroundColor Cyan
    }

    # --- OneDrive PREVENTION ---
    # Uninstalling is not enough: Windows still runs OneDriveSetup from the Default profile for every NEW user,
    # which reinstalls it and starts moving Desktop/Documents/Pictures into the cloud.
    Write-Host "  Blocking OneDrive from returning / moving user folders..." -ForegroundColor Cyan

    # Machine-wide policies.
    # NOTE: DisableFileSyncNGSC also stops OneDrive for Business / Microsoft 365 sync.
    #       Delete that line if a customer wants OneDrive later (KFMBlockOptIn alone only blocks folder moving).
    # Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" "KFMBlockOptIn" 1

    # Remove the auto-run entries from the current user and from the Default profile
    Invoke-ForUserHives {
        param($root)
        $runKey = "$root\Software\Microsoft\Windows\CurrentVersion\Run"
        Remove-ItemProperty -Path $runKey -Name "OneDriveSetup" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $runKey -Name "OneDrive"      -ErrorAction SilentlyContinue
    }
}

# ========================
#  POWER SETTINGS
# ========================
if ($setPowerPlanUltimate) {
    Write-Host "Setting power management options..." -ForegroundColor White -BackgroundColor Blue
	Write-Host "  Setting Ultimate Performance power plan..." -ForegroundColor Cyan

    $planRegPath  = "HKLM:\SOFTWARE\F_PS_CSC_S"
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
    if (Test-Path $planRegPath) {
        $saved = (Get-ItemProperty -Path $planRegPath -Name $regName -ErrorAction SilentlyContinue).$regName
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
            Set-Reg $planRegPath $regName $ultimateGUID "String"
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

    # Plan that the settings below are applied to.
    # Some laptops only offer Balanced (no Ultimate Performance), so fall back to whatever plan is active.
    $targetGUID = $ultimateGUID
    if (-not $targetGUID) {
        $activeOut = powercfg -getactivescheme 2>$null | Out-String
        if ($activeOut -match '([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})') {
            $targetGUID = $matches[1].ToLower()
            Write-Warning "Ultimate Performance is not available on this machine. Applying settings to the active plan instead ($targetGUID)."
        }
    }

	Write-Host "  Disabling Fast Startup..." -ForegroundColor Cyan
	Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0

    # Set timeouts to never
    if ($targetGUID) {
        try {
            powercfg -change -monitor-timeout-ac 0
            powercfg -change -disk-timeout-ac 0
            powercfg -change -standby-timeout-ac 0
            powercfg -setacvalueindex $targetGUID SUB_VIDEO VIDEOIDLE 0

            powercfg -change -monitor-timeout-dc 0
            powercfg -change -disk-timeout-dc 0
            powercfg -change -standby-timeout-dc 0
            powercfg -setdcvalueindex $targetGUID SUB_VIDEO VIDEOIDLE 0

			Write-Host "  Timeouts (AC) and (DC) set to never." -ForegroundColor Cyan
        } catch {
            Write-Warning "Failed to set power plan timeout values. $_"
        }

        # Disable USB selective suspend (AC + DC)
        $usbSubGroup         = "2a737441-1930-4402-8d77-b2bebba308a3"
        $usbSelectiveSuspend = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
        powercfg -setacvalueindex $targetGUID $usbSubGroup $usbSelectiveSuspend 0
        powercfg -setdcvalueindex $targetGUID $usbSubGroup $usbSelectiveSuspend 0
        powercfg -setactive $targetGUID
        Write-Host "  USB selective suspend disabled." -ForegroundColor Cyan
    }
    else {
        Write-Warning "No power plan found - timeouts and USB selective suspend were NOT changed."
    }

	Write-Host "  Changing power settings for network adapters (Ethernet + Wi-Fi only)..." -ForegroundColor Cyan

    # Physical Ethernet (802.3) and Wi-Fi (Native 802.11) only - no hidden/virtual/VPN adapters
    $netAdapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.PhysicalMediaType -in @('802.3','Native 802.11') }

	# DNS prompt asked before START
    if ($setDns -match '^[Yy]$') { $setDnsYes = $true }

    $nicClassPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
    $nicKeys      = Get-ChildItem $nicClassPath -ErrorAction SilentlyContinue

    foreach ($adapter in $netAdapters) {
        Write-Host "  Processing: $($adapter.Name)" -ForegroundColor Cyan

        try {
            $ifIndex = $adapter.InterfaceIndex

            # === Power management settings ===
            foreach ($key in $nicKeys) {
                if ((Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue).DriverDesc -eq $adapter.InterfaceDescription) {
                    # 24 = "Allow the computer to turn off this device to save power" unchecked
                    Set-Reg $key.PSPath "PnPCapabilities" 24
                    foreach ($wolName in @("*WakeOnMagicPacket", "WakeOnMagicPacket")) {
                        if (Get-ItemProperty -Path $key.PSPath -Name $wolName -ErrorAction SilentlyContinue) {
                            Set-ItemProperty -Path $key.PSPath -Name $wolName -Value 0 -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
            # powercfg wants the device description, not the connection name
            powercfg /devicedisablewake "$($adapter.InterfaceDescription)" 2>&1 | Out-Null

            # === DISABLE NETBIOS OVER TCP/IP (per adapter, 2 = disabled) ===
            $nbtPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$($adapter.InterfaceGuid)"
            Set-Reg $nbtPath "NetbiosOptions" 2
            Write-Host "    NetBIOS disabled for $($adapter.Name)" -ForegroundColor DarkGray

            # === DNS Settings ===
            if ($setDnsYes) {
                try {
                    Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @("9.9.9.9", "1.1.1.1") -ErrorAction Stop
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

    # === Disable LMHOSTS lookup (global, once) ===
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" "EnableLMHOSTS" 0

    Write-Host "  Network configuration completed (NetBIOS + LMHOSTS disabled)." -ForegroundColor Green
}

# ========================
#  FILE EXPLORER, DESKTOP, TASKBAR AND OTHER MISC STUFF...
# ========================
if ($tweakGeneralExplorerAndOther) {
    Write-Host "Configuring File Explorer, Desktop, Taskbar and other misc stuff..." -ForegroundColor White -BackgroundColor Blue

	# ---- Machine-wide / current-user-only items ----

	# Check "Allow files on this drive to have contents indexed in addition to file properties" option in the properties of the Windows local drive
	$drive = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter = 'C:'"
	if ($drive) {
		$drive.IndexingEnabled = $true
		$drive.Put() | Out-Null
	} else {
		Write-Warning "Could not find C: drive object"
	}

	# Restore right-click old context menu (Windows 11).
	# HKLM\SOFTWARE\Classes applies to every user; HKCU covers the account running the script.
	Set-Reg "HKLM:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(default)" "" "String"
	Set-Reg "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(default)" "" "String"

	# Clear Spotlight cache (prevents old images/state from reloading) - current user's profile only
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

	# Enable Verbose Status (additional log information when shutting down/restarting Windows) prompt before START
	if ($verboseS -match '^[Yy]$') {
		Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "verbosestatus" 1
	}

	# ---- Per-user items: applied to the current user AND the Default profile (new accounts) ----
	Write-Host "  Applying per-user settings (current user + Default profile for new users)..." -ForegroundColor Cyan

	Invoke-ForUserHives {
		param($root)

		$explorer = "$root\Software\Microsoft\Windows\CurrentVersion\Explorer"
		$adv      = "$explorer\Advanced"

		# Basic Explorer tweaks
		Set-Reg $adv "HideFileExt"          0
		Set-Reg $adv "Hidden"               1
		Set-Reg $adv "LaunchTo"             1
		Set-Reg $adv "NavPaneShowLibraries" 1

		# Classic desktop icons (0 = show)
		$desktopIcons = @{
			"{59031a47-3f72-44a7-89c5-5595fe6b30ee}" = 0  # User's Files Folder
			"{20D04FE0-3AEA-1069-A2D8-08002B30309D}" = 0  # This PC/Computer
			"{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" = 0  # Network
			"{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" = 0  # Control Panel
			"{645FF040-5081-101B-9F08-00AA002F954E}" = 0  # Recycle Bin
		}
		foreach ($iconGuid in $desktopIcons.Keys) {
			Set-Reg "$explorer\HideDesktopIcons\NewStartPanel" $iconGuid $desktopIcons[$iconGuid]
		}

		# Desktop icon size: 32 = Small, 48 = Medium, 96 = Large
		Set-Reg "$root\Software\Microsoft\Windows\Shell\Bags\1\Desktop" "IconSize" 32

		# Show Windows build at the bottom right of the desktop (prompt before START)
		if ($winBuildDesktop -match '^[Yy]$') {
			Set-Reg "$root\Control Panel\Desktop" "PaintDesktopVersion" 1
		}

		# Disable Spotlight
		$cdmPath = "$root\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
		Set-Reg $cdmPath "SubscribedContent-338388Enabled" 0   # Desktop Spotlight off
		Set-Reg $cdmPath "SubscribedContent-338387Enabled" 0   # Lock bleed-over off
		Set-Reg $cdmPath "RotatingLockScreenEnabled"       0
		Set-Reg "$root\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings" "EnabledState" 0

		# Default Windows wallpaper (light/dark depending on the theme of THIS hive; no value = light)
		$light = (Get-ItemProperty -Path "$root\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
		if ($null -eq $light) { $light = 1 }

		if ([int]$osInfo.CurrentBuildNumber -ge 22000) {
			# Windows 11 default
			if ($light -eq 1) { $wallpaperPath = "C:\Windows\Web\Wallpaper\Windows\img0.jpg" }
			else              { $wallpaperPath = "C:\Windows\Web\Wallpaper\Windows\img19.jpg" }
		} else {
			# Windows 10 default
			$wallpaperPath = "C:\Windows\Web\4K\Wallpaper\Windows\img0_3840x2160.jpg"
		}
		# Wallpaper Mode set to Image
		Set-Reg "$explorer\Wallpapers" "BackgroundType" 0
		Set-Reg "$root\Control Panel\Desktop" "WallPaper" $wallpaperPath "String"

		# Taskbar search display set to icon (Windows 10 / Windows 11)
		Set-Reg "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1
		Set-Reg $adv "TaskbarSearchMode" 1
		
		# Widgets / News off on Windows 11 and Windows 10
		Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0              # Windows 11 Widgets
		Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0      # Windows 10 News and Interests
		
		Set-Reg "$root\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2   # Windows 10 taskbar feed off

		# Enable "End task" in app right-click menu taskbar (Only on Windows 11)
		Set-Reg "$adv\TaskbarDeveloperSettings" "TaskbarEndTask" 1

		# Taskbar start button, pinned and opened Apps, search field bar set alignment to the left (Only on Windows 11)
		Set-Reg $adv "TaskbarAl" 0

		# Performance options: preset "Best Performance" -> "Custom"
		Set-Reg "$explorer\VisualEffects" "VisualFXSetting" 2
		Start-Sleep -Milliseconds 500
		Set-Reg "$explorer\VisualEffects" "VisualFXSetting" 3

		# Default "best performance" UserPreferencesMask
		Set-Reg "$root\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](144, 18, 3, 128, 16, 0, 0, 0)) "Binary"

		# Enable/Check 'Animate controls and elements inside windows'
		Set-Reg "$explorer\VisualEffects\ControlAnimations" "DefaultApplied" 1
		Set-Reg "$explorer\VisualEffects\ControlAnimations" "DefaultValue"   1
		Set-Reg "$explorer\VisualEffects\ControlAnimations" "Value"          1

		# Disable/Uncheck 'Animate windows when minimising and maximising'
		Set-Reg "$root\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"

		# Disable/Uncheck 'Enable Peek'
		Set-Reg "$root\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0

		# Enable/Check 'Show thumbnails instead of icons'
		Set-Reg $adv "IconsOnly" 0

		# Enable/Check 'Show translucent selection rectangle'
		Set-Reg $adv "ListviewAlphaSelect" 1

		# Enable/Check 'Show window contents while dragging'
		Set-Reg "$root\Control Panel\Desktop" "DragFullWindows" "1" "String"

		# Enable/Check 'Smooth edges of screen fonts'
		Set-Reg "$root\Control Panel\Desktop" "FontSmoothing"     "2" "String"
		Set-Reg "$root\Control Panel\Desktop" "FontSmoothingType" 2

		# Enable/Check 'Use drop shadows for icon labels'
		Set-Reg $adv "ListviewShadow" 1

		# Disable taskbar animations
		Set-Reg $adv "TaskbarAnimations" 0
	}

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

    # Machine-wide
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0

    # Per-user (current user + Default profile)
    Invoke-ForUserHives {
        param($root)
        Set-Reg "$root\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
        Set-Reg "$root\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
        Set-Reg "$root\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent"    0
    }
	Write-Host "  Microsoft Telemtry & Cortana disabled." -ForegroundColor Cyan
}

# ========================
#  OPTIMIZING SERVICES
# ========================
if ($manageServices) {
    Write-Host "Optimizing services..." -ForegroundColor White -BackgroundColor Blue

	# Snapshot BEFORE, so you can see exactly what this script changed (diff command is in the notes)
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
						 "WalletService","WpcMonSvc","WMPNetworkSvc",
						 "SharedAccess")   # SharedAccess = Internet Connection Sharing, breaks Mobile Hotspot
	# dmwappushservice is intentionally NOT disabled: Intune/MDM uses it.

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

	# --- PREVENTION ---
	# Stops Windows from automatically starting Device Encryption / BitLocker (some laptops do it at first sign-in).
	# Set before first sign-in (e.g. in audit mode) this keeps the drive unencrypted.
	Write-Host "  Blocking automatic device encryption..." -ForegroundColor Cyan
	Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" "PreventDeviceEncryption" 1

	# --- FORCE DISABLE (decrypt anything that is already encrypted) ---
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
            Start-Sleep -Seconds 5   # give Windows a moment to switch the status to DecryptionInProgress
            do {
                $stillWorking = Get-BitLockerVolume | Where-Object { $_.VolumeStatus -eq "DecryptionInProgress" }
                if ($stillWorking) {
                    $percent = $stillWorking[0].EncryptionPercentage
                    Write-Host "Progress: $percent% still encrypted on $($stillWorking[0].MountPoint)  " -ForegroundColor Black -BackgroundColor Yellow
                    Start-Sleep -Seconds 30
                }
            } while ($stillWorking)

            # Anything still fully encrypted at this point means decryption never started
            $stuck = Get-BitLockerVolume | Where-Object { $_.VolumeStatus -eq "FullyEncrypted" }
            if ($stuck) {
                Write-Warning "Decryption did not start on: $(($stuck | ForEach-Object { $_.MountPoint }) -join ', ')"
            } else {
                Write-Host "  Decryption completed on all drives." -ForegroundColor Cyan
            }
        }

        # NOTE: this also stops scheduled SSD optimization (TRIM). Remove these two lines if you want it to keep running.
        Set-Service -Name "defragsvc" -StartupType Disabled -ErrorAction Continue
        Stop-Service -Name "defragsvc" -Force -ErrorAction Continue

        Write-Host "  BitLocker fully disabled." -ForegroundColor Cyan

        manage-bde -status
    } catch { Write-Error "Error: $_" }
}

# ASK USER INSTALL APPS prompt before START
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
Write-Host "Log files: $logDir" -ForegroundColor Green
$restart = Read-Host "Restart your PC now? (Y/N): "

try { Stop-Transcript | Out-Null } catch { }

if ($restart -match '^[Yy]$') {
    Write-Host "Restarting your PC..." -ForegroundColor Green
    Restart-Computer -Force
} else {
    Write-Host "Understood. Remember to restart your PC later!" -ForegroundColor Green
}
