<#
Changes passwords for all local users given a csv file.
#>

param(
    [Parameter(mandatory=$true)]
    [string]$csvPath,

    [Parameter(mandatory=$false)]
    [string]$outPath,

    [Parameter(mandatory=$false)]
    [string[]]$exclude
)

# Read from csv
$password_list = Import-Csv $csvPath

# Find all local users
$users = (Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'").Name

# Path defaults to "C:\", use -path parameter to set custom path (e.g. C:\Users\gmoment)
$csvPasswordFile = "$env:USERPROFILE\Desktop"
if(!$csvPath.Equals("")) {
    $csvPasswordFile = $outPath
}
if (Test-Path $csvPasswordFile) {
    Remove-Item $csvPasswordFile
}
New-Item $csvPasswordFile -ItemType File

# Loop through users and change passwords
$i = 0
foreach($user in $users) {
    $password = $password_list[$i].password

    if (!$password) {
        Write-Error "NULL PASSWORD DETECTED. TERMINATING"
        exit
    }

    if ($user -in $exclude) {
        continue
    }
    else {
        Add-content $csvPasswordFile ($user + "," + $password)    
        net user $user $password > $null
        $i++
    }
    # FOR DEBUGGING!!!
    # Write-Output "$name's password changed to $password"
}
