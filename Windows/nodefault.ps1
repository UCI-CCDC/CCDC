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
    4a) Generates a new password based on the number of each char set passed in
    4b) Adds the name, and new password to the csv file
    4c) Changes the password for the selected user
#>
param(
    [Parameter(Position=0, mandatory=$true, HelpMessage="The domain in the format: DC=CyberUCI,DC=com")]
    [string]$domain,
    
    [Parameter(Position=1, mandatory=$true, HelpMessage="The download path for the csv in the format: C:\...\..")]
    [string]$path,

    [Parameter(Position=2, mandatory=$true, HelpMessage="Password for gmoment")]
    [string]$SuperPass,

    [Parameter(Position=3, mandatory=$true, HelpMessage="UCount is the number of Uppercase Chars in the password (recommend 4)")]
    [int]$UCount,

    [Parameter(Position=4, mandatory=$true, HelpMessage="LCount is the number of the Lowercase Chars in the password (recommend 4)")]
    [int]$LCount,

    [Parameter(Position=5, mandatory=$true, HelpMessage="NCount is the numebr of Number Chars in the passwords (recommend 3)")]
    [int]$NCount,

    [Parameter(Position=6, mandatory=$true, HelpMessage="SCount is the number of Special Chars in the passwords (recommend 3)")]
    [int]$SCount
    )

Import-Module ActiveDirectory
Install-WindowsFeature -Name RSAT-AD-PowerShell

#Tests if running as admin, then elivates if it is not
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   #If the script is runnign as admin, add Elevated to the window title, and change the colors to be hacker themed
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
#May want to add OU=Users before the domain.
#Doing the above may pervent random system users from getting password changes
$users = Get-ADUser -Filter * -SearchBase $domain -Properties DistinguishedName

#Setup for the password generator
$uppercase = "ABCDEFGHKLMNOPRSTUVWXYZ".tochararray() 
$lowercase = "abcdefghiklmnoprstuvwxyz".tochararray() 
$number = "0123456789".tochararray() 
$special = "%()=?}{@#+!".tochararray()

#Where the user passwords are going
#By default it will be created in the same directory with the name UsersNewPasswords.csv
#$csvPasswordFile = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

#Not needed anymore due to passing commands with parameters
#Write-Output "-----------------------------------------------------------------------------------------"
#Write-Output "This is where the csv, and password files are stored"
#Write-Output "Format: C:\...\..."
#Write-Output "DO NOT add the filename at the end of the directory"
#Write-Output ("Default location: " + $csvPasswordFile)
#$path = Read-host "Input"

if(!$path.Equals(""))
{
    $csvPasswordFile = $path
}

$csvPasswordFile += "\UsersNewPasswords.csv"
New-Item $csvPasswordFile -ItemType File


#hostname for the csv file
#Write-Output "-----------------------------------------------------------------------------------------"
#$hostname = Read-Host "Enter Hostname:"


#Loop through each profile hive and set a new password
foreach($user in $users)
{

    #Gets random chars from the lists, and adds the number of each passed in the parameter to the password
    $password =($uppercase | Get-Random -count $UCount) -join ''
    $password +=($lowercase | Get-Random -count $LCount) -join ''
    $password +=($number | Get-Random -count $NCount) -join ''
    $password +=($special | Get-Random -count $SCount) -join ''

    #Scramble the password so the chars are not bunched up by type
    $passArray = $password.tochararray()
    $password = ($passArray | Get-Random -Count $passArray.Count) -join ''

    #Currently this code uses the Distinguished name becsaue it is garuenteed to be unique, this can be changed
    $name = $user | Select-Object -expand DistinguishedName
    Write-Output $name
    Write-Output $password
    #Add-content $csvPasswordFile ($hostname + "," + $name + "," + $password)
    Add-content $csvPasswordFile ($name + "," + $password)
    
    Set-ADAccountPassword -Identity $name -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
}

#Make new (super) user in ad
#This might be changed so that the name of the user is passed through as a param
New-ADUser -Name "gmoment" -Description "Having an epic gamer moment" -Accountpassword (ConvertTo-SecureString -AsPlainText $SuperPass -Force) -Enabled $true
Add-ADGroupMember -Identity "Domain Admins" -Member gmoment
