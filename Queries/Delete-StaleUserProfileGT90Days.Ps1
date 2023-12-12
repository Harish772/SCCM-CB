[CmdletBinding()]
Param()

# List of user accounts to exclude from deletion
$ExcludedUsers = @("User1", "User2", "User3")

$ProfilesDirectory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Name ProfilesDirectory).ProfilesDirectory

$UserProfiles = Get-CimInstance -ClassName Win32_UserProfile |
    Where-Object { ($_.Special -eq $false) }

foreach ($UserProfile in $UserProfiles) {
    $LastLogonDate = $UserProfile.LastUseTime
    $DaysSinceLastLogon = (Get-Date) - $LastLogonDate
    $Username = $UserProfile.LocalPath -replace "^$ProfilesDirectory\\"

    # Check if the username is in the list of excluded users
    if ($ExcludedUsers -contains $Username) {
        Write-Host "User profile for $Username is excluded from deletion."
    } elseif ($DaysSinceLastLogon.Days -gt 90) {
        Remove-CimInstance -InputObject $UserProfile
        Write-Host "User profile for $Username deleted."

        # Log the deleted user profile to a log file
        $LogData = "Deleted user profile for $Username on $(Get-Date)"
        Add-Content -Path "C:\Path\To\Log\File.txt" -Value $LogData
    } else {
        Write-Host "User profile for $Username not deleted. Last logon within the last 90 days."
    }
}
