Set-ExecutionPolicy Unrestricted -Force

$LogFile = "C:\Temp\WmiFix.log"
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

# Stop Service
Write-ToLog $LogFile "Stopping WinMGMT" 
Get-Service -DisplayName "Windows Management Instrumentation" | Stop-Service -Force
Get-Service -DisplayName 'SMS Agent Host' |Stop-Service -Force
Get-Service -DisplayName "Windows Update" | Stop-Service -ErrorAction Ignore
Get-Service -DisplayName 'Background Intelligent Transfer Service' |Stop-Service -ErrorAction Ignore
Get-Service -DisplayName 'Cryptographic Services' |Stop-Service -ErrorAction Ignore
Get-Service -DisplayName "Windows Management Instrumentation" | Stop-Service -Force


Start-Sleep -Seconds 90 -ErrorAction SilentlyContinue


# to Clear if issues related to WUA 
Write-ToLog $LogFile "Renaming WUA/WMI folders"
Rename-Item "C:\Windows\SoftwareDistribution\Download" "C:\Windows\SoftwareDistribution\Download.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\System32\catroot2" "C:\Windows\System32\catroot2.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\SoftwareDistribution" "C:\Windows\SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\System32\wbem\Repository" "C:\Windows\System32\wbem\Repository.old" -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 60 -ErrorAction SilentlyContinue

# to Clear if issues related to WUA (step 2)
Write-ToLog $LogFile "Renaming WUA/WMI folders"
Rename-Item "C:\Windows\SoftwareDistribution\Download" "C:\Windows\SoftwareDistribution\Download.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\System32\catroot2" "C:\Windows\System32\catroot2.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\SoftwareDistribution" "C:\Windows\SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\System32\wbem\Repository" "C:\Windows\System32\wbem\Repository.old" -Force -ErrorAction SilentlyContinue


# Start WUA services
Write-ToLog $LogFile "Starting WUA services"
Get-Service -DisplayName "Windows Update" | Start-Service -ErrorAction Ignore
Get-Service -DisplayName 'Background Intelligent Transfer Service' |Start-Service -ErrorAction Ignore
Get-Service -DisplayName 'Cryptographic Services' |Start-Service -ErrorAction Ignore
cd windows\system32\wbem

Write-ToLog $LogFile "Registering MOFS"

if (test-path C:\temp\RegisterMof1.cmd) {
    Remove-Item –path C:\temp\RegisterMOF1.cmd -force
}
 Add-Content C:\temp\RegisterMOF1.cmd "for /f %s in ('dir /b *.dll') do regsvr32 /s %s"
cmd /c C:\temp\RegisterMOF1.cmd

Start-Sleep -Seconds 30 -ErrorAction SilentlyContinue

Write-ToLog $LogFile "Starting WMI services"
Get-Service -DisplayName "Windows Management Instrumentation" | Start-Service -ErrorAction Ignore
Get-Service -DisplayName 'SMS Agent Host' |Start-Service -ErrorAction Ignore

Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule -ArgumentList '{00000000-0000-0000-0000-000000000113}' -ErrorAction SilentlyContinue | Out-Null  

Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule -ArgumentList '{00000000-0000-0000-0000-000000000108}' -ErrorAction SilentlyContinue | Out-Null  

Start-Sleep -Seconds 30 -ErrorAction SilentlyContinue
cd windows\system32\wbem

Write-ToLog $LogFile "Registering MOFS"

if (test-path C:\temp\RegisterMof2.cmd) {
    Remove-Item –path C:\temp\RegisterMOF2.cmd -force
}

Add-Content C:\temp\RegisterMOF2.cmd "for /f %s in ('dir /s /b *.mof *.mfl') do " -NoNewline

Add-Content C:\temp\RegisterMOF2.cmd "mofcomp %s  "
cmd /c C:\temp\RegisterMOF2.cmd

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