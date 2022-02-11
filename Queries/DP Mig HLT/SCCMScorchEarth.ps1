Set-ExecutionPolicy Unrestricted -Force

$LogFile = "C:\Temp\SCCMClientFix.log"
$ErrorActionPreference = "SilentlyContinue"

Function Write-ToLog([string]$file, [string]$message) {       
    $Date = $(get-date -uformat %Y-%m-%d-%H.%M.%S)
    $message = "$Date`t$message"
    Write-Verbose $message

    #Write out to log file
    Out-File $file -encoding ASCII -input $message -append
}

Function DeleteItem ($ItemPath) {
    If (test-path $ItemPath){   
        Remove-Item -path $ItemPath -recurse -Force | Out-Null
        Write-ToLog $LogFile $ItemPath " Deleted"     }
}

Function DeleteRegKey ($RegKeyPath) {
    If (Get-Item -path $RegKeyPath){   
        Remove-Item -path $RegKeyPath -recurse | Out-Null
        Write-ToLog $LogFile $RegKeyPath " Deleted"     }
}

# Stop process
Write-ToLog $LogFile "Stopping Processes"
(Get-WmiObject Win32_Process | ?{ $_.ProcessName -match "msiexec.exe" }).Terminate() | Out-Null
(Get-WmiObject Win32_Process | ?{ $_.ProcessName -match "CcmExec.exe" }).Terminate() | Out-Null
(Get-WmiObject Win32_Process | ?{ $_.ProcessName -match "CmRcService.exe" }).Terminate() | Out-Null

# Stop Service
Write-ToLog $LogFile "Stopping WUA Services" 
Get-Service -DisplayName "Windows Update" | Stop-Service
Get-Service -DisplayName 'Background Intelligent Transfer Service' |Stop-Service -Force
Get-Service -DisplayName 'Cryptographic Services' |Stop-Service -Force

# Start uninstall then remove any lingering folders and files
Write-ToLog $LogFile "Uninstalling SCCM Client"
start-process -Wait -PSPath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList " /uninstall"

Start-Sleep -Seconds 90 -ErrorAction SilentlyContinue

Write-ToLog $LogFile "Deleting Files and Folders"
DeleteItem "c:\windows\ccm"
DeleteItem "c:\windows\ccmcache"
DeleteItem "c:\windows\ccmsetup"
DeleteItem "c:\windows\smscfg.ini"

Start-Sleep -Seconds 10 -ErrorAction SilentlyContinue

# In case folder/file deletion is needed again
Write-ToLog $LogFile "Checking for Folders/Files again and deleting if needed"
DeleteItem "c:\windows\ccm"
DeleteItem "c:\windows\ccmcache"
DeleteItem "c:\windows\ccmsetup"
DeleteItem "c:\windows\smscfg.ini"

# to Clear if issues related to WUA 
Write-ToLog $LogFile "Renaming WUA folders"
Rename-Item "C:\Windows\SoftwareDistribution\Download" "C:\Windows\SoftwareDistribution\Download.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\System32\catroot2" "C:\Windows\System32\catroot2.old" -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 30 -ErrorAction SilentlyContinue

# Start WUA services
Write-ToLog $LogFile "Starting WUA services"
Get-Service -DisplayName "Windows Update" | Start-Service -ErrorAction Ignore
Get-Service -DisplayName 'Background Intelligent Transfer Service' |Start-Service -ErrorAction Ignore
Get-Service -DisplayName 'Cryptographic Services' |Start-Service -ErrorAction Ignore

Start-Sleep -Seconds 30 -ErrorAction SilentlyContinue

# Check and delete Reg Keys
Write-ToLog $LogFile "Deleting Reg Keys"
DeleteRegKey "HKLM:\software\Microsoft\ccm"
DeleteRegKey "HKLM:\SOFTWARE\Microsoft\CCMSetup"
DeleteRegKey "HKLM:\software\Microsoft\SMS"
DeleteRegKey "HKLM:\software\Microsoft\Systemcertificates\SMS\Certificates"

Start-Sleep -Seconds 10 -ErrorAction SilentlyContinue

# In case Reg Key deletion is needed again
Write-ToLog $LogFile "Checking for Reg Keys again and deleting if needed"
DeleteRegKey "HKLM:\software\Microsoft\ccm"
DeleteRegKey "HKLM:\SOFTWARE\Microsoft\CCMSetup"
DeleteRegKey "HKLM:\software\Microsoft\SMS"
DeleteRegKey "HKLM:\software\Microsoft\Systemcertificates\SMS\Certificates"

Start-Sleep -Seconds 5 -ErrorAction SilentlyContinue

# Delete any residue WMI item
Write-ToLog $LogFile "Deleting WMI entry"
get-wmiobject -computername Localhost -query "SELECT * FROM __Namespace WHERE Name='CCM'" -Namespace "root" | Remove-WmiObject 

# Call SCCM Client logon script to reinstall SCCM
#Write-ToLog $LogFile "Calling Logon install script"
#Write-ToLog $LogFile $env:LOGONSERVER " is the LOGON SERVER"
#Invoke-Expression $env:LOGONSERVER\NETLOGON\SCCMClientUpgrade.ps1

Write-ToLog $LogFile "Restarting Computer"
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("This computer is scheduled for Restart in 10 minutes",60,"Save Data",0x0)
Sleep 60
$wshell.Popup("This computer is scheduled for Restart in 8 minutes",60,"Save Data",0x0)
Sleep 60
$wshell.Popup("This computer is scheduled for Restart in 6 minutes",60,"Save Data",0x0)
Sleep 60
$wshell.Popup("This computer is scheduled for Restart in 4 minutes",60,"Save Data",0x0)
Sleep 60
$wshell.Popup("This computer is scheduled for Restart in 2 minutes",60,"Save Data",0x0)
Sleep 60

$wshell.Popup("30 seconds to Restart",2,"Save it or it will be gone",0x0)


$xCmdString = {sleep 30}

Invoke-Command $xCmdString

Restart-Computer