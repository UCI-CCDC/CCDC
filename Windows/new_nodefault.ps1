<#
Changes passwords for all domain users given a csv file.
#>

param(
    [Paramter(mandatory=$true)]
    [string]$domain,

    [Parameter(mandatory=$true)]
    [string]$csvPath,

    [Parameter(mandatory=$false)]
    [string]$outPath
)

# Read from csv
$password_list = Import-Csv $csvPath

#Find all the user profiles in the domain
$users = Get-ADUser -Filter * -SearchBase $domain -Properties DistinguishedName

# Path defaults to "C:\", use -path parameter to set custom path (e.g. C:\Users\gmoment)
$csvPasswordFile = ""$env:USERPROFILE\Desktop""
if(!$path.Equals("")) {
    $csvPasswordFile = $outPath
}
$csvPasswordFile += "\UsersNewPasswords.csv"
New-Item $csvPasswordFile -ItemType File

# Loop through users and change passwords
$i = 0
foreach($user in $users) {
    $password = $passwords[$i].password

    #Currently this code uses the Distinguished name becsaue it is garuenteed to be unique, this can be changed
    $dist_name = $user | Select-Object -expand DistinguishedName
    $name = $user | Select-Object -expand SamAccountName
    #Add-content $csvPasswordFile ($hostname + "," + $name + "," + $password)
    Add-content $csvPasswordFile ($name + "," + $password)
    
    Set-ADAccountPassword -Identity $dist_name -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)

    Write-Output "$name's password changed"
    $i++
}
