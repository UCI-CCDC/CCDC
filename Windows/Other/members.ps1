# Credit: CPP repo Inv.ps1
$DC = Get-WmiObject -Query "select * from Win32_OperatingSystem where ProductType='2'"
Write-Output "`n#### Start Group Membership ####" 
if ($DC) {
    $Groups = Get-ADGroup -Filter 'SamAccountName -NotLike "Domain Users"' | Select-Object -ExpandProperty Name
    $Groups | ForEach-Object {
        $Users = Get-ADGroupMember -Identity $_ | Select-Object -ExpandProperty Name
        if ($Users.Count -gt 0) {
            $Users = $Users | ForEach-Object { "   Member: $_" }
            Write-Output "Group: $_" $Users
        }
    }
}
else {
    # Get a list of all local groups
    $localGroups = [ADSI]"WinNT://localhost"

    # Iterate through each group
    $localGroups.psbase.Children | Where-Object { $_.SchemaClassName -eq 'group' } | ForEach-Object {

        $groupName = $_.Name[0]
        Write-Output "Group: $groupName"
        
        # List members of the current group
        $_.Members() | ForEach-Object {
            $memberPath = ([ADSI]$_).Path.Substring(8)
            Write-Output "    Member: $memberPath"
        }
    }
}
Write-Output "#### End Group Membership ####"
