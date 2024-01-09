Write-Output "`nIP Address:" | Out-File -FilePath log.txt -Append
((Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias Ethernet*).IPAddress) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "`nHostname/Domain:" | Out-File -FilePath log.txt -Append
#($env:computername) | Out-File -FilePath log.txt -Append
Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select-Object Name, Domain | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

#systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
Write-Output "Operating System:" | Out-File -FilePath log.txt -Append
((Get-WmiObject Win32_OperatingSystem).Caption) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "Open Ports:" | Out-File -FilePath log.txt -Append
(get-nettcpconnection | where {($_.State -eq "Listen")} | select LocalPort,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | Sort-Object LocalPort | ft) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

#Get running services
#    possible change to get better output
#Get-WmiObject -Query "Select * from Win32_Process" | where {$_.Name -notlike "svchost*"} | Select Name, Handle, @{Label="Owner";Expression={$_.GetOwner().User}} | ft -AutoSize
Write-Output "Running Services:" | Out-File -FilePath log.txt -Append
(Get-WmiObject win32_service | where { $_.Caption -notmatch "Windows" -and $_.PathName -notmatch "Windows" -and $_.PathName -notmatch "policyhost.exe" -and $_.Name -ne "LSM" -and $_.PathName -notmatch "OSE.EXE" -and $_.PathName -notmatch "OSPPSVC.EXE" -and $_.PathName -notmatch "Microsoft Security Client"} | where { $_.State -eq "Running" } | Select DisplayName,Description | ft -Autosize -Wrap) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

#Get running processes
# TODO: Find a different way of getting processes
Write-Output "Running Processes:" | Out-File -FilePath log.txt -Append
(Get-Process | Where-Object { $_.MainWindowTitle } | Format-Table ID,Name,Mainwindowtitle -AutoSize -Wrap) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

#Get DNS records if DC
$DC = Get-WmiObject -Query "select * from Win32_OperatingSystem where ProductType='2'"
if ($DC) {
    Write-Output "`n#### DC Detected ####" | Out-File -FilePath log.txt -Append

    Write-Output "`n#### Start DNS Records ####" | Out-File -FilePath log.txt -Append
    try {
        Get-DnsServerResourceRecord -ZoneName $($(Get-ADDomain).DNSRoot) | ? {$_.RecordType -notmatch "SRV|NS|SOA" -and $_.HostName -notmatch "@|DomainDnsZones|ForestDnsZones"} | Format-Table | Out-File -FilePath log.txt -Append
    }
    catch {
        Write-Output "[ERROR] Failed to get DNS records, DC likely too old" | Out-File -FilePath log.txt -Append
    }
    Write-Output "#### End DNS Records ####" | Out-File -FilePath log.txt -Append
}

## IIS
if (Get-Service -Name W3SVC -ErrorAction SilentlyContinue) {
    $IIS = $true
    Import-Module WebAdministration
    Write-Output "`n#### IIS Detected ####" | Out-File -FilePath log.txt -Append
}
if ($IIS) {
    Write-Output "`n#### Start IIS Site Bindings ####" | Out-File -FilePath log.txt -Append
    $websites = Get-ChildItem IIS:\Sites | Sort-Object name

    foreach ($site in $websites) {
        Write-Output "Website Name: $($site.Name)" | Out-File -FilePath log.txt -Append
        Write-Output "Website Path: $($site.physicalPath)" | Out-File -FilePath log.txt -Append
        $bindings = Get-WebBinding -Name $site.name
        foreach ($binding in $bindings) {
            Write-Output "    Binding Information:" | Out-File -FilePath log.txt -Append
            Write-Output "        Protocol: $($binding.protocol)" | Out-File -FilePath log.txt -Append
            Write-Output "        IP Address: $($binding.bindingInformation.split(":")[0])" | Out-File -FilePath log.txt -Append
            Write-Output "        Port: $($binding.bindingInformation.split(":")[1])" | Out-File -FilePath log.txt -Append
            Write-Output "        Hostname: $($binding.hostHeader)" | Out-File -FilePath log.txt -Append
        }
        Write-Output "" | Out-File -FilePath log.txt -Append
    }
    Write-Output "#### End IIS Site Bindings ####" | Out-File -FilePath log.txt -Append
}

#Get installed programs
#From C:\
#Get-ChildItem 'C:\Program Files', 'C:\Program Files (x86)' | ft Parent,Name,LastWriteTime
#From Reg
#Get-ChildItem -path Registry::HKEY_LOCAL_MACHINE\SOFTWARE | ft Name


#Installed Hotfixes
#(Get-HotFix  | Select-Object -ExpandProperty HotFixID)



#Extra inventory info

#Get scheduled tasks
#Get-ScheduledTask | where {$_.TaskPath -notlike "\Microsoft*"} | ft TaskName,TaskPath,State

#Get Startup tasks
#wmic startup get caption,command

#Antiviruses installed
#WMIC /Node:localhost /Namespace:\\root\SecurityCenter2 Path AntivirusProduct Get displayName

#HiveNightmare
#icacls config\SAM
#Search for BUILTIN\Users in the output

#Search for PII
#cd C:\
#findstr /SI /M "password" *.xml *.ini *.txt
# TODO: Add more PII searches
#    - Search for unattened files




Write-Output "----------------------------------------------------------------------------------------------------" | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append
