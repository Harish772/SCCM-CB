[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True)]
    [string]$Username
)

$ProfilesDirectory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Name ProfilesDirectory).ProfilesDirectory

$UserProfiles = Get-CimInstance -ClassName Win32_UserProfile |
    Where-Object { ($_.LocalPath -eq "$ProfilesDirectory\$Username") -and ($_.Special -eq $false) }

foreach ($UserProfile in $UserProfiles) {
    $LastLogonDate = $UserProfile.LastUseTime
    $DaysSinceLastLogon = (Get-Date) - $LastLogonDate

    if ($DaysSinceLastLogon.Days -gt 90) {
        Remove-CimInstance -InputObject $UserProfile
        Write-Host "User profile for $Username deleted."

        # Log the deleted user profile to a log file
        $LogData = "Deleted user profile for $Username on $(Get-Date)"
        Add-Content -Path "C:\Path\To\Log\File.txt" -Value $LogData
    } else {
        Write-Host "User profile for $Username not deleted. Last logon within the last 90 days."
    }
}
