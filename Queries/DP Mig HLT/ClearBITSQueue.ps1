$Servers = (Get-Content '\\HFWDBSCCM01PH\c$\Scripts\Powershell\ClearBITSQueue\serverlist.txt')

Foreach($Server in $Servers)
{
    (Get-WmiObject Win32_Process -ComputerName $Server | ?{ $_.ProcessName -match "CcmExec.exe" }).Terminate()

    (Get-WmiObject Win32_Service -ComputerName $Server | ?{ $_.Name -match "BITS" }).Stopservice()

    sleep 3

    If (Test-Path \\$Server\c$\ProgramData\Microsoft\Network\Downloader\qmgr0.dat)
        {
            Write-host "$Server deleting qmgr0.dat"
            Remove-Item -Path \\$Server\c$\ProgramData\Microsoft\Network\Downloader\qmgr0.dat -Force
            
        }

    If (Test-Path \\$Server\c$\ProgramData\Microsoft\Network\Downloader\qmgr1.dat)
        {
            Write-host "$Server deleting qmgr1.dat"
            Remove-Item -Path \\$Server\c$\ProgramData\Microsoft\Network\Downloader\qmgr1.dat -Force
            
        }

    Get-Service -Name bits -ComputerName $Server | Set-Service -Status Running
    Get-Service -Name CcmExec -ComputerName $Server | Set-Service -Status Running
    }