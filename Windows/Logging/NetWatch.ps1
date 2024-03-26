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

$ErrorActionPreference = "SilentlyContinue"
$hashtable = @{logname="Microsoft-Windows-Sysmon/Operational"; ID=3}
$init_cnt = 10
$data = Get-WinEvent -FilterHashtable $hashtable -MaxEvents $init_cnt
$data | Sort-Object RecordId | Out-Null
$idx = $data[$init_cnt - 1].RecordId

while ($True) {
    Start-Sleep 1
    $new_idx = (Get-WinEvent -FilterHashtable $hashtable -MaxEvents 1).RecordId
    if ($new_idx -gt $idx) {
        $event_cnt = $new_idx - $idx
        $logs = Get-WinEvent -FilterHashtable $hashtable -MaxEvents $event_cnt | Sort-Object RecordId
        foreach ($log in $logs) {
            $evt = $log | Parse-Event
            Write-Output "       Time: $((Get-Date $evt.UtcTime).ToLocalTime().ToString())"
            Write-Output "     Source: $($evt.SourceIp):$($evt.SourcePort)"
            Write-Output "Destination: $($evt.DestinationIp):$($evt.DestinationPort)"
            Write-Output "   Protocol: $($evt.Protocol)"
            Write-Output "      Image: $($evt.Image)   PID: $($evt.ProcessId)   TID: $($evt.ThreadId)"
            Write-Output "       User: $($evt.User)"
            Write-Output "----------------------------------------"
        }
    }
    $idx = $new_idx
}
