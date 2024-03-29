param(
    [Parameter(Mandatory=$false)]
    [string]$outPath = "C:\Programdata\NetWatch-log.txt",

    [Parameter(Mandatory=$false)]
    [string]$filter = "^$",

    [Parameter(Mandatory=$false)]
    [string]$good = "^$",

    [Parameter(Mandatory=$false)]
    [string]$bad = "^$",

    [Parameter(Mandatory=$false)]
    [switch]$v,

    [Parameter(Mandatory=$false)]
    [switch]$NoWrite
)

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
$LogName = "Microsoft-Windows-Sysmon"
$maxRecordId = (Get-WinEvent -Provider $LogName -max 1).RecordID

while ($True) {
    Start-Sleep 1
    $xPath = "*[System[EventRecordID > $maxRecordId]]"
    $logs = Get-WinEvent -Provider $LogName -FilterXPath $xPath | Sort-Object RecordID
    foreach ($log in $logs) {
        $evt = $log | Parse-Event
        if ($evt.id -eq 3) {
            $output = "       Time: $((Get-Date $evt.UtcTime).ToLocalTime().ToString())`n"
            $output += "     Source: $($evt.SourceIp):$($evt.SourcePort) ($($evt.SourceHostname))`n"
            $output += "Destination: $($evt.DestinationIp):$($evt.DestinationPort) ($($evt.DestinationHostName))`n"
            $output += "   Protocol: $($evt.Protocol)`n"
            $output += "      Image: $($evt.Image) (PID: $($evt.ProcessId))`n"
            $output += "       User: $($evt.User)`n"
            $output += "----------------------------------------"
            if ($output | ?{$_ -match $filter}) { continue }
            if (!$NoWrite) {Write-Output $output | Out-File $outPath -Append}
            if ($v -or $NoWrite) {
                if ($output | ?{$_ -match $good}) {
                    Write-Host $output -ForegroundColor Green
                } elseif ($output | ?{$_ -match $bad}) {
                    Write-Host $output -ForegroundColor Red
                } else {
                    Write-Host $output
                }
            }
        }
        $maxRecordId = $evt.RecordId
    }
}
