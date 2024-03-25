$shares = Get-SmbShare
$default_shares = @("C$", "ADMIN$", "IPC$")

foreach ($share in $shares) {
    if ($share.Name -notin $default_shares) {
        Write-Output "Share: $($share.Name)" | Out-File -FilePath smb-info.txt -Append
        Write-Output "Path: $($share.Path)" | Out-File -FilePath smb-info.txt -Append
        Get-ChildItem $share.Path -Force | Out-File -FilePath smb-info.txt -Append
        $share | Get-SmbShareAccess | Format-Table -AutoSize -Wrap | Out-File -FilePath smb-info.txt -Append
        Write-Output "####################################################################################################" | Out-File -FilePath smb-info.txt -Append
    }
}