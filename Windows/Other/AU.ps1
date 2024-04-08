# Read authorized users from file
$authorizedUsers = Get-Content .\authorized.txt
$defaultUsers = @("Administrator", "Guest", "Defaultaccount", "WDAGUtilityAccount")
$users = @()
$existingUsers = @()

# Get all users
$DC = Get-WmiObject -Query "select * from Win32_OperatingSystem where ProductType='2'"
if ($DC) {
    $users = Get-ADUser -Filter * | Where-Object {$defaultUsers -notcontains $_.sAMAccountName} | Select-Object -ExpandProperty sAMAccountName
}
else {
    $users = Get-WmiObject Win32_UserAccount | Where-Object {$_.LocalAccount -eq $true -and $defaultUsers -notcontains $_.Name} | Select-Object -ExpandProperty Name
}

# Remove unauthorized users
Write-Host "### Removing unauthorized users ###" -ForegroundColor Green
$users | ForEach-Object {
    $user = $_
    if ($authorizedUsers -notcontains $user) {
        Write-Host "Removing user: $user"
        net user $user /del | Out-Null
    }
    else {
        $existingUsers += $user
    }
}

# Add missing authorized users
Write-Host "### Adding missing authorized users ###" -ForegroundColor Green
$authorizedUsers | ForEach-Object {
    $user = $_
    if ($existingUsers -notcontains $user) {
        Write-Host "Adding user: $user"
        net user $user AmazingPassword1! /add | Out-Null
    }
}
