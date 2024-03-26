<#
Changes passwords for all domain users given a csv file.
#>

param(
    [Parameter(mandatory=$true)]
    [string]$domain,

    [Parameter(mandatory=$true)]
    [string]$csvPath,

    [Parameter(mandatory=$false)]
    [string]$outPath,

    [Parameter(mandatory=$false)]
    [string[]]$exclude
)

# Read from csv
$password_list = Import-Csv $csvPath

#Find all the user profiles in the domain
$users = Get-ADUser -Filter * -SearchBase $domain -Properties DistinguishedName

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

    if ($user.SamAccountName -in $exclude) {
        continue
    }
    else {
        #Currently this code uses the Distinguished name becsaue it is garuenteed to be unique, this can be changed
        $dist_name = $user | Select-Object -expand DistinguishedName
        $name = $user | Select-Object -expand SamAccountName

        Add-content $csvPasswordFile ($name + "," + $password)    
        Set-ADAccountPassword -Identity $dist_name -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
        $i++
    }
    # FOR DEBUGGING!!!
    # Write-Output "$name's password changed to $password"
}
