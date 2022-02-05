<# 
***************************************************************
* Generate and set new passwords for ALL AD users, and Admins *
***************************************************************
Created by: Payton Joseph Erickson
Purpose:
This script does the following in order
1) Elevates to admin, and changes the powershell colors to look like we are masterhackers
2) Gets all AD accounts in the domain. (This includes Admin, and disabled accounts)
3) Creates a csv file to be sent to scoring engine
4) Loops through all accounts in the AD
    4a) Generates a new pass word with at leas 11 chars (minimums: 2 Uppercase, 5 Lowercase, 2 Number, 2 Special)
    4b) Adds the id, name, and new passs word to the csv file
    4c) Changes the pass word for the selected user
#>

Import-Module ActiveDirectory
Install-WindowsFeature -Name RSAT-AD-PowerShell

#Tests if running as admin, then elivates if it is not
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   #If the script is runnign as admin, add Elevated to the window title, and change the colors to hacker themed
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.ForegroundColor = "DarkGreen"
   $Host.UI.RawUI.BackgroundColor = "Black"
   clear-host
   }
else
   {
   #If the script is not running as admin, start a new powershell that is Elevated and close this one
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   $newProcess.Verb = "runas";
   [System.Diagnostics.Process]::Start($newProcess);
   exit
   }

#Find all the user profiles in the domain
$domain = ""
while ($domain.Equals("")) 
{
    Write-Output "-----------------------------------------------------------------------------------------"
    Write-Output "This is the `"SearchBase`" command."
    Write-Output "If you want to change the entire domain (all AD accounts)"
    Write-Output "then just enter your domain in the format shown below."
    Write-Output "CyberUCI.com = `"DC=CyberUCI,DC=com`" (without the quotes)."
    Write-Output "For more options check out: https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser?view=windowsserver2019-ps"
    $domain = Read-host "Input"
    
}
$users = Get-ADUser -Filter * -SearchBase $domain -Properties DistinguishedName

#Setup for the password generator
$uppercase = "ABCDEFGHKLMNOPRSTUVWXYZ".tochararray() 
$lowercase = "abcdefghiklmnoprstuvwxyz".tochararray() 
$number = "0123456789".tochararray() 
$special = "%()=?}{@#+!".tochararray()

#Where the user passwords are going
#By default it will be created in the same directory with the name UsersNewPasswords.csv
#$csvPasswordFile = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

Write-Output "-----------------------------------------------------------------------------------------"
Write-Output "This is where the csv, and password files are stored"
Write-Output "Format: C:\...\..."
Write-Output "DO NOT add the filename at the end of the directory"
#Write-Output ("Default location: " + $csvPasswordFile)
$inputPath = Read-host "Input"

if(!$inputPath.Equals(""))
{
    $csvPasswordFile = $inputPath
}

$csvPasswordFile += "\UsersNewPasswords.csv"
New-Item $csvPasswordFile -ItemType File

#hostname for the csv file
Write-Output "-----------------------------------------------------------------------------------------"
$hostname = Read-Host "Enter Hostname:"

#Loop through each profile hive and set a new password
foreach($user in $users)
{
    #Linux team wants 14 char passwords, so I temperally removed the randomness for the number of each char to add

    #Start by genreating the new count for each type of char
    #This is done to gearentee there is never a weak password

    $count = 4
    #$count = Get-Random -Minimum 4 -Maximum 10
    $password =($uppercase | Get-Random -count $count) -join ''
    #$count = Get-Random -Minimum 5 -Maximum 10
    $password +=($lowercase | Get-Random -count $count) -join ''
    #$count = Get-Random -Minimum 3 -Maximum 10
    $password +=($number | Get-Random -count $count) -join ''
    $count = 2
    #$count = Get-Random -Minimum 2 -Maximum 4
    $password +=($special | Get-Random -count $count) -join ''

    #Scramble the password so the chars are not bunched up by type
    $passArray = $password.tochararray()
    $password = ($passArray | Get-Random -Count $passArray.Count) -join ''

    #Currently this code uses the Distinguished name becsaue it is garuenteed to be unique, this can be changed
    $name = $user | Select-Object -expand DistinguishedName
    Write-Output $name
    Write-Output $password
    Add-content $csvPasswordFile ($hostname + "," + $name + "," + $password)
    
    Set-ADAccountPassword -Identity $name -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
}