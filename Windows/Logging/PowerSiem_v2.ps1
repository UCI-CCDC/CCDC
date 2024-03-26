# PowerSiem_v2
# Original code written by ippsec (https://github.com/IppSec/PowerSiem)
# Modified by: Joshua Chung

# Inspired SilentBreakSecurity DSOPS 1 Course - (SilentBreakSecurity has since been acquired by NetSPI)

param(
    [Parameter(Mandatory=$false)]
    [switch]$NoWrite
)

$ErrorActionPreference = "SilentlyContinue"
$Hostname = "$(hostname)"

Function Parse-Event {
    # Credit: https://github.com/RamblingCookieMonster/PowerShell/blob/master/Get-WinEventData.ps1
    param(
        [Parameter(ValueFromPipeline=$true)] $Event
    )

    Process
    {
        foreach($entry in $Event)
        {
            $XML = [xml]$entry.ToXml()
            $X = $XML.Event.EventData.Data
            For( $i=0; $i -lt $X.count; $i++ ){
                $Entry = Add-Member -InputObject $entry -MemberType NoteProperty -Name "$($X[$i].name)" -Value $X[$i].'#text' -Force -Passthru
            }
            $Entry
        }
    }
}

Function Write-Both ($string) {
    # Helper function which writes both to stdout and a log file
    Write-Host $string
    #Write-Output $string | Out-File -FilePath log_PSv2.txt -Append
}

Function Write-Alert ($alerts) {
    Write-Both "Host: $Hostname"
    Write-Both "Type: $($alerts.Type)"
    Write-Both "Time: $($alerts.UtcTime)"
    $alerts.Remove("Type")
    $alerts.Remove("UtcTime")
    foreach($alert in $alerts.GetEnumerator()) {
        Write-Both "$($alert.Name): $($alert.Value)"
    }
    Write-Both "---------------"
}

$LogName = "Microsoft-Windows-Sysmon"

$maxRecordId = (Get-WinEvent -Provider $LogName -max 1).RecordID

while ($true)
{
    Start-Sleep 1

    $xPath = "*[System[EventRecordID > $maxRecordId]]"
    $logs = Get-WinEvent -Provider $LogName -FilterXPath $xPath | Sort-Object RecordID

    foreach ($log in $logs) {
        $evt = $log | Parse-Event

        # Write event details to a file
        if (!$NoWrite) {
            $evt | select -ExpandProperty Message | Out-File -FilePath log_PSv2.txt -Append
            Write-Output "---------------" | Out-File -FilePath log_PSv2.txt -Append
        }

        if ($evt.id -eq 1) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Process Create")
            $output.add("PID", $evt.ProcessId)
            $output.add("Image", $evt.Image)
            $output.add("CommandLine", $evt.CommandLine)
            $output.add("CurrentDirectory", $evt.CurrentDirectory)
            $output.add("User", $evt.User)
            $output.add("ParentImage", $evt.ParentImage)
            $output.add("ParentCommandLine", $evt.ParentCommandLine)
            $output.add("ParentUser", $evt.ParentUser)
            write-alert $output
        }
        if ($evt.id -eq 2) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "File Creation Time Changed")
            $output.add("PID", $evt.ProcessId)
            $output.add("Image", $evt.Image)
            $output.add("TargetFilename", $evt.TargetFileName)
            $output.add("CreationUtcTime", $evt.CreationUtcTime)
            $output.add("PreviousCreationUtcTime", $evt.PreviousCreationUtcTime)
            write-alert $output
        }
        if ($evt.id -eq 3) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Network Connection")
            $output.add("Image", $evt.Image)
            $output.add("SourceIp", $evt.SourceIp)
            $output.add("SourcePort", $evt.SourcePort)
            $output.add("SourceHost", $evt.SourceHostname)
            $output.add("DestinationIp", $evt.DestinationIp)
            $output.add("DestinationPort", $evt.DestinationPort)
            $output.add("DestinationHost", $evt.DestinationHostname)
            write-alert $output
        }
        if ($evt.id -eq 5) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Process Ended")
            $output.add("PID", $evt.ProcessId)
            $output.add("Image", $evt.Image)
            $output.add("CommandLine", $evt.CommandLine)
            $output.add("CurrentDirectory", $evt.CurrentDirectory)
            $output.add("User", $evt.User)
            $output.add("ParentImage", $evt.ParentImage)
            $output.add("ParentCommandLine", $evt.ParentCommandLine)
            $output.add("ParentUser", $evt.ParentUser)
            write-alert $output
        }
        if ($evt.id -eq 6) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Driver Loaded")
            write-alert $output
        }
        if ($evt.id -eq 7) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "DLL Loaded By Process")
            write-alert $output
        }
        if ($evt.id -eq 8) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Remote Thread Created")
            write-alert $output
        }
        if ($evt.id -eq 9) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Raw Disk Access")
            write-alert $output
        }
        if ($evt.id -eq 10) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Inter-Process Access")
            write-alert $output
        }
        if ($evt.id -eq 11) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "File Create")
            $output.add("RecordID", $evt.RecordID)
            $output.add("TargetFilename", $evt.TargetFileName)
            $output.add("User", $evt.User)
            $output.add("Process", $evt.Image)
            $output.add("PID", $evt.ProcessID)
            write-alert $output
        }
        if ($evt.id -eq 12) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Registry Added or Deleted")
            $output.add("User", $evt.User)
            $output.add("Process", $evt.Image)
            $output.add("PID", $evt.ProcessID)
            $output.add("TargetObject", $evt.TargetObject)
            $output.add("EventType", $evt.EventType)
            write-alert $output
        }
        if ($evt.id -eq 13) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Registry Set")
            $output.add("User", $evt.User)
            $output.add("Process", $evt.Image)
            $output.add("PID", $evt.ProcessID)
            $output.add("TargetObject", $evt.TargetObject)
            $output.add("Details", $evt.Details)
            write-alert $output
        }
        if ($evt.id -eq 14) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Registry Object Renamed")
            $output.add("User", $evt.User)
            $output.add("Process", $evt.Image)
            $output.add("PID", $evt.ProcessID)
            $output.add("TargetObject", $evt.TargetObject)
            $output.add("NewName", $evt.NewName)
            write-alert $output
        }
        if ($evt.id -eq 15) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "ADFS Created")
            write-alert $output
        }
        if ($evt.id -eq 16) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Sysmon Configuration Change")
            write-alert $output
        }
        if ($evt.id -eq 17) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Pipe Created")
            write-alert $output
        }
        if ($evt.id -eq 18) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Pipe Connected")
            write-alert $output
        }
        if ($evt.id -eq 19) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "WMI Event Filter Activity")
            write-alert $output
        }
        if ($evt.id -eq 20) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "WMI Event Consumer Activity")
            write-alert $output
        }
        if ($evt.id -eq 21) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "WMI Event Consumer To Filter Activity")
            write-alert $output
        }
        if ($evt.id -eq 22) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "DNS Query")
            write-alert $output
        }
        if ($evt.id -eq 23) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "File Delete")
            $output.add("RecordID", $evt.RecordID)
            $output.add("TargetFilename", $evt.TargetFileName)
            $output.add("User", $evt.User)
            $output.add("Process", $evt.Image)
            $output.add("PID", $evt.ProcessID)
            write-alert $output
        }
        if ($evt.id -eq 24) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Clipboard Event Monitor")
            write-alert $output
        }
        if ($evt.id -eq 25) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "Process Tamper")
            write-alert $output
        }
        if ($evt.id -eq 26) {
            $output = @{}
            $output.add("UtcTime", $evt.UtcTime)
            $output.add("Type", "File Delete Logged")
            $output.add("RecordID", $evt.RecordID)
            $output.add("TargetFilename", $evt.TargetFileName)
            $output.add("User", $evt.User)
            $output.add("Process", $evt.Image)
            $output.add("PID", $evt.ProcessID)
            write-alert $output
        }
        $maxRecordId = $evt.RecordId
    }
}