Write-Output "IP Address:" | Out-File -FilePath log.txt -Append
((Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias Ethernet*).IPAddress) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "Hostname:" | Out-File -FilePath log.txt -Append
($env:computername) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "Operating System:" | Out-File -FilePath log.txt -Append
((Get-WmiObject Win32_OperatingSystem).Caption) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "Open Ports:" | Out-File -FilePath log.txt -Append
(get-nettcpconnection | where {($_.State -eq "Listen")} | select LocalPort,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | ft) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "Running Services:" | Out-File -FilePath log.txt -Append
(Get-WmiObject win32_service | where { $_.Caption -notmatch "Windows" -and $_.PathName -notmatch "Windows" -and $_.PathName -notmatch "policyhost.exe" -and $_.Name -ne "LSM" -and $_.PathName -notmatch "OSE.EXE" -and $_.PathName -notmatch "OSPPSVC.EXE" -and $_.PathName -notmatch "Microsoft Security Client"} | where { $_.State -eq "Running" } | Select DisplayName,Description | ft -Autosize -Wrap) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "Running Processes:" | Out-File -FilePath log.txt -Append
(Get-Process | Where-Object { $_.MainWindowTitle } | Format-Table ID,Name,Mainwindowtitle -AutoSize -Wrap) | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append

Write-Output "----------------------------------------------------------------------------------------------------" | Out-File -FilePath log.txt -Append
Write-Output "" | Out-File -FilePath log.txt -Append