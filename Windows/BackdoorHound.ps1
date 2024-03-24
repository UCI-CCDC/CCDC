# Uses statistical analysis to find backdoor AD users
# Idea: Legit users will have a valid Description, Company, and Department
# This script will find users without these

param(
    [Parameter(Position=0, mandatory=$true, HelpMessage="The domain in the format: DC=CyberUCI,DC=com")]
    [string]$domain
)

$users = Get-ADUser -Filter * -SearchBase $domain -Properties DistinguishedName,Description,Company,Department

# Calculate averages
$desc_total = ($users | ForEach-Object { if ($_.Description -eq $null) { 0 } else { $_.Description.Length } }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$desc_avg = $desc_total / $users.Count

$comp_total = ($users | ForEach-Object { if ($_.Company -eq $null) { 0 } else { $_.Company.Length } }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$comp_avg = $comp_total / $users.Count

$dep_total = ($users | ForEach-Object { if ($_.Department -eq $null) { 0 } else { $_.Department.Length } }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$dep_avg = $dep_total / $users.Count

# Output averages
# Write-Output "Description average: $desc_avg"
# Write-Output "Company average: $comp_avg"
# Write-Output "Department average: $dep_avg"

# Calculate standard deviations
$desc_sum_of_squares = ($users | ForEach-Object { if ($_.Description -eq $null) { 0 } else { ($_.Description.Length - $desc_avg) * ($_.Description.Length - $desc_avg) } }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$desc_variance = $desc_sum_of_squares / $users.Count
$desc_sd = [Math]::Sqrt($desc_variance)

$comp_sum_of_squares = ($users | ForEach-Object { if ($_.Company -eq $null) { 0 } else { ($_.Company.Length - $comp_avg) * ($_.Company.Length - $comp_avg) } }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$comp_variance = $comp_sum_of_squares / $users.Count
$comp_sd = [Math]::Sqrt($comp_variance)

$dep_sum_of_squares = ($users | ForEach-Object { if ($_.Department -eq $null) { 0 } else { ($_.Department.Length - $dep_avg) * ($_.Department.Length - $dep_avg) } }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$dep_variance = $dep_sum_of_squares / $users.Count
$dep_sd = [Math]::Sqrt($dep_variance)

# Output standard deviations
# Write-Output "Description standard deviation: $desc_sd"
# Write-Output "Company standard deviation: $comp_sd"
# Write-Output "Department standard deviation: $dep_sd"

# Output users 2 or more standard deviations away from the mean, keep track of sussy
$global:sus_users = @()

$users | ForEach-Object {
    $descriptionLength = if ($_.Description -eq $null) { 0 } else { $_.Description.Length }
    $distanceFromMean = [Math]::Abs($descriptionLength - $desc_avg)
    $standardDeviationsAway = $distanceFromMean / $desc_sd
    if ($standardDeviationsAway -ge 2) {
        Write-Output "User $($_.SamAccountName) has a description length of $descriptionLength, which is $standardDeviationsAway standard deviations away from the mean."
        $global:sus_users += $_
    }
}
Write-Output ""

$users | ForEach-Object {
    $companyLength = if ($_.Company -eq $null) { 0 } else { $_.Company.Length }
    $distanceFromMean = [Math]::Abs($companyLength - $comp_avg)
    $standardDeviationsAway = $distanceFromMean / $comp_sd
    if ($standardDeviationsAway -ge 2) {
        Write-Output "User $($_.SamAccountName) has a company length of $companyLength, which is $standardDeviationsAway standard deviations away from the mean."
        $global:sus_users += $_
    }
}
Write-Output ""

$users | ForEach-Object {
    $departmentLength = if ($_.Department -eq $null) { 0 } else { $_.Department.Length }
    $distanceFromMean = [Math]::Abs($departmentLength - $dep_avg)
    $standardDeviationsAway = $distanceFromMean / $dep_sd
    if ($standardDeviationsAway -ge 2) {
        Write-Output "User $($_.SamAccountName) has a department length of $departmentLength, which is $standardDeviationsAway standard deviations away from the mean."
        $global:sus_users += $_
    }
}

$sus_users | select -ExpandProperty SamAccountName