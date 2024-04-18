<#
Previously named security.bat, upgraded to be a PowerShell script with registry backups
#>

# REM  Run this script in an elevated CMD prompt
# REM  This does not include firewall rules
# REM Comment out any sections that do not apply to a certain service (ex. SMB scored box)
# REM Don't forget to use msconfig

param(
    [Parameter(Mandatory=$false)]
    [switch]$NoBackup,

    [Parameter(Mandatory=$false)]
    [switch]$v,

    [Parameter(Mandatory=$false)]
    [switch]$Restore
)

# Define the registry paths and values to modify
$registryChanges = @(
    # Disable Admin Shares (psexec defense)
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        ValueName = "AutoShareWks"
        ValueType = "REG_DWORD"
        ValueData = 0
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        ValueName = "AutoShareServer"
        ValueType = "REG_DWORD"
        ValueData = 0
    },
    @{
        Key = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        ValueName = "LocalAccountTokenFilterPolicy"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # SMBv1 Disable 
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Services\LanmanServer\Parameters"
        ValueName = "SMB1"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # Hashing
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "NoLMHash"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "LMCompatibilityLevel"
        ValueType = "REG_DWORD"
        ValueData = 5
    },

    # Anon Login
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "restrictanonymous"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "disableRestrictedAdmin"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # Disable Keys
    @{
        Key = "HKCU\Control Panel\Accessibility\StickyKeys"
        ValueName = "Flags"
        ValueType = "REG_SZ"
        ValueData = "506"
    },
    @{
        Key = "HKCU\Control Panel\Accessibility\ToggleKeys"
        ValueName = "Flags"
        ValueType = "REG_SZ"
        ValueData = "58"
    },
    @{
        Key = "HKCU\Control Panel\Accessibility\Keyboard Response"
        ValueName = "Flags"
        ValueType = "REG_SZ"
        ValueData = "122"
    },
    @{
        Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
        ValueName = "ShowTabletKeyboard"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # Disable floppy disk remoting
    @{
        Key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        ValueName = "AllocateFloppies"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Enable SMB Signing (prevent smb ntlm relaying attacks)
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Services\LanmanServer\Parameters"
        ValueName = "EnableSecuritySignature"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Services\LanmanServer\Parameters"
        ValueName = "RequireSecuritySignature"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Rdr\Parameters"
        ValueName = "EnableSecuritySignature"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Rdr\Parameters"
        ValueName = "RequireSecuritySignature"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Prevent print driver installs 
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
        ValueName = "AddPrinterDrivers"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Local account blank passwords
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "LimitBlankPasswordUse"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Enable full UAC
    @{
        Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        ValueName = "PromptOnSecureDesktop"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Enable installer detections
    @{
        Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        ValueName = "EnableInstallerDetection"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Anon enumeration prevention
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "restrictanonymous"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "restrictanonymoussam"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Domain cred storing 
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "disabledomaincreds"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # No perms to anons
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "everyoneincludesanonymous"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # SMB strengtheners
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\services\LanmanWorkstation\Parameters"
        ValueName = "EnablePlainTextPassword"
        ValueType = "REG_DWORD"
        ValueData = 0
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters"
        ValueName = "NullSessionPipes"
        ValueType = "REG_MULTI_SZ"
        ValueData = "\0"
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters"
        ValueName = "NullSessionShares"
        ValueType = "REG_MULTI_SZ"
        ValueData = "\0"
    },

    # Remote registry path denial
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedExactPaths"
        ValueName = "Machine"
        ValueType = "REG_MULTI_SZ"
        ValueData = "\0"
    },
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedPaths"
        ValueName = "Machine"
        ValueType = "REG_MULTI_SZ"
        ValueData = "\0"
    },

    # Require UAC
    @{
        Key = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        ValueName = "EnableLUA"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer"
        ValueName = "AlwaysInstallElevated"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # Enable LSASS Memory Protection
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
        ValueName = "RunAsPPL"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Enable Credential Guard
    @{
        Key = "HKLM\SYSTEM\CurrentControl\Control\Lsa"
        ValueName = "LsaCfgFlags"
        ValueType = "REG_DWORD"
        ValueData = 1
    },

    # Disable plain text passwords stored in LSASS
    @{
        Key = "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest"
        ValueName = "UseLogonCredential"
        ValueType = "REG_DWORD"
        ValueData = 0
    },

    # Enable PowerShell Logging
    @{
        Key = "HKLM\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
        ValueName = "EnableModuleLogging"
        ValueType = "REG_DWORD"
        ValueData = 1
    },
    @{
        Key = "HKLM\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
        ValueName = "EnableScriptBlockLogging"
        ValueType = "REG_DWORD"
        ValueData = 1
    }
)

$dns = (sc.exe query dns | findstr RUNNING)
if ($dns) {
    # SIGRED
    $registryChanges += @{
        Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Parameters"
        ValueName = "TcpReceivePacketSize"
        ValueType = "REG_DWORD"
        ValueData = 0xFF00
    }
}

if (!$Restore) {
    # Making changes here

    # REM sc.exe config "wfcs" displayname= "wfcservice"
    # REM sc.exe description wfcs "wfcservice description"
    # REM perm charlie delta
    # @echo off

    # REM rename admin acct + disable default accounts
    # REM wmic useraccount where "name='Administrator'" rename Admin
    # REM net user Administrator /active:no
    net user Guest /active:no
    net user DefaultAccount /active:no
    net user WDAGUtilityAccount /active:no

    # REM Enable full auditing
    auditpol /set /category:* /success:enable /failure:enable

    if (!$NoBackup) {
        # Create a backup of the current registry values
        $backupPath = ".\RegistryBackups\"
        if (-not (Test-Path -Path $backupPath)) {
            New-Item -ItemType Directory -Path $backupPath | Out-Null
        }
    }

    foreach ($change in $registryChanges) {
        $key = $change.Key
        $valueName = $change.ValueName
        
        if (!$NoBackup) {
            $backupFilePath = Join-Path -Path $backupPath -ChildPath "$($key.Replace('\', '_')).reg"
            $backupCommand = "reg export '$key' '$backupFilePath' /y | Out-Null"
            # Backup the current registry value
            if ($v) {
                Write-Output "Backing up $($key)\$($valueName) to $($backupFilePath)..."
            }
            Invoke-Expression -Command $backupCommand
        }

        # Modify the registry value
        $setValueCommand = "reg add '$key' /v '$valueName' /t $($change.ValueType) /d $($change.ValueData) /f | Out-Null"
        if ($v) {
            Write-Output "Modifying $($key)\$($valueName)..."
        }
        Invoke-Expression -Command $setValueCommand
    }

    # Restart DNS for SIGRED
    if ($dns) {
        net stop DNS
        net start DNS
    }

    net share admin$ /del
    net share c$ /del
    # reg delete hklm\software\microsoft\windows\currentversion\runonce /f
    # reg delete hklm\software\microsoft\windows\currentversion\run /f
    # del /S "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*"
    # del /S "C:\Users\LocalGuard\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*"
}
else {
    # Restore from backups
    $backupPath = ".\RegistryBackups\"

    foreach ($change in $registryChanges) {
        $key = $change.Key
        $valueName = $change.ValueName
        $backupFilePath = Join-Path -Path $backupPath -ChildPath "$($key.Replace('\', '_')).reg"
        $restoreCommand = "reg import '$backupFilePath'"

        # Restore the backup
        if ($v) {
            Write-Output "Restoring $($key)\$($valueName) from $($backupFilePath)..."
        }
        Invoke-Expression -Command $restoreCommand
    }
    Write-Output "Registry values restored."
}
