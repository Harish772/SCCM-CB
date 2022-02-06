#.Synopsis
#   Copy-OSDLogsToArchive.ps1
#   Script to copy logs from a directory to a centralized backup location
#   Path can only contain folders under C:\
#.Link
#.Example
#    powershell.exe -ExecutionPolicy Bypass -File Copy-OSDLogsToArchive.ps1
#.Example
#    .\Copy-OSDLogsToArchive.ps1
#.Notes
#   ===== Change Log History =====
#   2022/01/31 by Chad.Simmons@CatapultSystems.com - combined with CopyOSDLogs.ps1 from Johan Schrewelius, Onevinn AB
#   20xx/xx/xx by KIETH GARNER - created
#   ===== To Do / Proposed Changes =====
#
[cmdletbinding()]
param(
    [Parameter(Mandatory = $true)][string]$LogServerSharePath,
    [Parameter(Mandatory = $false)][string]$LogProject = 'Undefined',
    [Parameter(Mandatory = $false)][string[]]$Path = @( #No longer backing these up during CompatScan TS on Fails.
        "$env:Systemdrive\`$WINDOWS.~BT\Sources\Panther"
        "$env:Systemdrive\`$WINDOWS.~BT\Sources\Rollback"
        "$env:SystemRoot\Panther"
        "$env:SystemRoot\SysWOW64\PKG_LOGS"
        #"$env:SystemRoot\System32\winevt\Logs"
        #"$env:SystemRoot\Logs\CBS\CBS.log"
        #"$env:SystemRoot\inf\setupapi.upgrade.log"
        #"$env:SystemRoot\Logs\MoSetup\BlueBox.log"
    ),
    [Parameter(Mandatory = $false)][string[]]$Path1 = @( #Only backup if WaaS failure
        "$env:SystemRoot\CCM\Logs"
        "$env:SystemRoot\CCMSetup\Logs"
        "$env:ProgramData\WaaS\Logs"
        "$env:SystemRoot\Installer\_Logs"
        "$env:SystemRoot\Logs\Software" #PowerShell Application Deployment Toolkit default
    ),
    [Parameter(Mandatory = $false)][string[]]$Path2 = @( #Not recursive
        "$env:SystemRoot\Logs"
    ),
    [Parameter(Mandatory = $false)][string[]]$Exclude = @('*.exe', '*.wim', '*.dll', '*.ttf', '*.mui', '*.tmp', '*.efi', '*.bin')
)
$ScriptVersion = '2022.01.31.0'
$Now = Get-Date
$yyyyMMdd_HHmm = Get-Date -Date $Now -Format yyyyMMdd_HHmm

Function Write-LogMessage ([string]$Message) {
    If ($VerbosePreference -eq 'Continue') { Write-Host "$Message" }
}
Function ZipFiles ([string]$ZipFileName, [string]$SourceDir) {
    Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $ZipFileName, $compressionLevel, $false)
}
Function Authenticate {
    param(
        [string]$UNCPath = $(Throw 'An UNC Path must be specified'),
        [string]$User,
        [string]$PW
    )
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = 'net.exe'
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = "USE * $($UNCPath) /USER:$($User) $($PW)"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
}
Function Get-SystemInfo ($Path) {
    [void](New-Item -ItemType Directory -Path $Path -Force)

    #TODO: Run with a timeout of 60 seconds
    Start-Process -FilePath "$env:SystemRoot\System32\GPResult.exe" -ArgumentList '/scope:Computer', '/H', "$Path\GPResult.html" -Wait
    #TODO: Run with a timeout of 60 seconds
    GPResult.exe /scope:Computer /Z > "$Path\GPResult.txt"
    Get-ComputerInfo | Out-File -FilePath "$Path\ComputerInfo.txt"
    Get-ChildItem env: | Out-File -FilePath "$Path\EnvironmentVariables.txt"
    IPConfig.exe /all > "$Path\IPConfig.txt"
    arp -a -v > "$Path\ARP.txt"
    NET.exe localgroup administrators > "$Path\Local Administrators.txt"
    #SystemInfo.exe /FO LIST > "$Path\SystemInfo.txt"

    Function Export-WMIClass ($Class, $Path) {
        Get-WmiObject -Class $Class | Select-Object * | Out-File -FilePath "$Path\$($Class.replace('Win32','WMI')).txt"
        ### replaces: WMIC.exe /OUTPUT:"$Path\WMI_BASEBOARD.txt" BASEBOARD GET * /FORMAT:LIST
        ### replaces: WMIC.exe /OUTPUT:"$Path\WMI_BASEBOARD.txt" BASEBOARD GET * /FORMAT:HFORM
    }
    Export-WMIClass -Path $Path -Class Win32_Baseboard
    Export-WMIClass -Path $Path -Class Win32_BIOS
    Export-WMIClass -Path $Path -Class Win32_BootConfiguration
    Export-WMIClass -Path $Path -Class Win32_ComputerSystem
    Export-WMIClass -Path $Path -Class Win32_ComputerSystemProduct
    Export-WMIClass -Path $Path -Class Win32_Processor
    Export-WMIClass -Path $Path -Class Win32_DiskDrive
    Export-WMIClass -Path $Path -Class Win32_Environment
    Export-WMIClass -Path $Path -Class Win32_LogicalDisk
    Export-WMIClass -Path $Path -Class Win32_NetworkAdapter
    Export-WMIClass -Path $Path -Class Win32_NetworkAdapterConfiguration
    Export-WMIClass -Path $Path -Class Win32_OperatingSystem
    Export-WMIClass -Path $Path -Class Win32_DiskPartition
    Export-WMIClass -Path $Path -Class Win32_QuickFixEngineering
    Export-WMIClass -Path $Path -Class Win32_SystemDriver
    Export-WMIClass -Path $Path -Class Win32_SystemEnclosure
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition #PowerShell 2.0 method
Write-LogMessage -Message "scriptPath is $scriptPath"
Write-LogMessage -Message "Log Archive Tool $ScriptVersion"
Write-LogMessage -Message "LogServerSharePath is $LogServerSharePath"
Write-LogMessage -Message "LogProject is $LogProject"

#Setup TS Environment
try {
    $TSenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $LogPath = $TSenv.Value('SLShare')
    $TaskSequence = $TSenv.Value('_SMSPackageID') #_SMSPackageName
    $CmpName = $TSenv.Value("$ComputerNameVariable")
    $source = $TSenv.Value('_SMSTSLogPath')
    $NaaUser = $TSenv.Value('_SMSTSReserved1-000')
    $NaaPW = $TSenv.Value('_SMSTSReserved2-000')

    $FailedStep = $TSEnv.Value('FailedStepName')
    $TSbuild = $TSenv.Value('SMSTS_Build') #Get Build Number from TS Variable.
    $RegistryVar = "HKLM:\$($TSenv.Value('RegistryPath'))"
    $RegistryPath = "$RegistryVar\$TSbuild"
} catch {
    Write-LogMessage -Message "Not running in a task sequence."
}
If ([string]::IsNullOrEmpty($FailedStep)) { $FailedStep = 'StepNameUndefined' }
Write-LogMessage -Message "TSbuild is $TSbuild"

#region Prepare Target
Write-LogMessage -Message "Create Target $LogServerSharePath\$LogProject"
New-Item -ItemType Directory -Path "$LogServerSharePath\$LogProject" -Force -ErrorAction SilentlyContinue | Out-Null

#Ensure write access to the Server Share Path
$ServerTempFile = Join-Path -Path $LogServerSharePath\$LogProject -ChildPath $(Split-Path -Path $([System.IO.Path]::GetTempFileName()) -Leaf)
Try {
    [void](New-Item -ItemType File -Path $ServerTempFile -Force)
} catch {
    #Authenticate to the remote share.  Fallback to the Network Access Account if necessary
    try {
        Authenticate -UNCPath $LogPath -User $TSenv.Value('_SMSTSReserved1-000') -PW $TSenv.Value('_SMSTSReserved2-000')
    } catch {}
}
Remove-Item -Path $ServerTempFile -Force -ErrorAction SilentlyContinue

$ComputerInfoFile = "$LogServerSharePath\$LogProject\$env:ComputerName.txt"
Get-ComputerInfo | Out-File -FilePath "$LogServerSharePath\$LogProject\$env:ComputerName.txt" -Force
#grab Path info and write out as well, since we've had issues with machines having messed up Path.
"PATH = $($env:path)" | Out-File -FilePath $ComputerInfoFile -Append
#endregion

#Add Log File to Folder that Contains WaaS Registry Key Info & Failed Step Name
If (-not([string]::IsNullOrEmpty($RegistryPath))) {
    If (Test-Path -Path $RegistryPath -ErrorAction SilentlyContinue) {
        "RegistryPath = $(Get-Item $registryPath)" | Out-File -FilePath $ComputerInfoFile -Append
    }
}
#If ($FailedStep -ne 'StepNameUndefined') {
    "FailedStep = $FailedStep" | Out-File -FilePath $ComputerInfoFile -Append
    [PSCustomObject][ordered]@{ Timestamp = $(Get-Date -Date $Now -Format 'yyyyMMdd HH:mm:ss'); ComputerName = $env:ComputerName; FailedStep = $FailedStep } | Export-Csv -Path "$LogServerSharePath\$LogProject\_FailureLog.csv" -Append -NoTypeInformation
#}


#region Create temporary Store
$TempPath = [System.IO.Path]::GetTempFileName()
Remove-Item $TempPath

#First Zip File for Panther & Windows Logs - NOT USING DURING COMPAT SCAN... didn't find much need after enabling SetupDiag
[void](New-Item -ItemType Directory -Path $TempPath -Force)
Get-SystemInfo -Path "$TempPath\SystemInfo"

#Gather Windows / Panther logs
ForEach ($Item in $Path) {
    $TmpTarget = (Join-Path -Path $TempPath -ChildPath (Split-Path -NoQualifier $Item))
    Write-LogMessage -Message "COPY [$Item] to [$TmpTarget]"
    "COPY [$Item] to [$TmpTarget]" | Out-File -FilePath $ComputerInfoFile -Append
    Copy-Item -Path $Item -Destination $TmpTarget -Force -Recurse -Exclude $Exclude -ErrorAction SilentlyContinue
}
#Gather CCM Logs & WaaS logs & SetupDiag
ForEach ($Item in $Path1) {
    $TmpTarget = (Join-Path -Path $TempPath -ChildPath (Split-Path -NoQualifier $Item))
    Write-LogMessage -Message "COPY [$Item] to [$TmpTarget]"
    "COPY [$Item] to [$TmpTarget]" | Out-File -FilePath $ComputerInfoFile -Append
    Copy-Item -Path $Item -Destination $TmpTarget -Force -Recurse -Exclude $Exclude -ErrorAction SilentlyContinue
}
#Gather Logs non-recursive
ForEach ($Item in $Path2) {
    $TmpTarget = (Join-Path -Path $TempPath -ChildPath (Split-Path -NoQualifier $Item))
    Write-LogMessage -Message "COPY [$Item] to [$TmpTarget]"
    "COPY [$Item] to [$TmpTarget]" | Out-File -FilePath $ComputerInfoFile -Append
    Get-ChildItem "$Item\*" -File -Exclude $Exclude | Copy-Item -Destination $TmpTarget -ErrorAction SilentlyContinue
}

#create Zip File for CCM Logs & WaaS logs & SetupDiag
$ArchiveFile = "$LogServerSharePath\$LogProject\$($env:ComputerName)_$($yyyyMMdd_HHmm).zip"
"ZipFiles [$TempPath] to [$ArchiveFile]" | Out-File -FilePath $ComputerInfoFile -Append
Write-LogMessage -Message "ArchiveFile is $ArchiveFile"
ZipFiles -ZipFileName $ArchiveFile -SourceDir $TempPath
Remove-Item -Path $TempPath -Recurse -Force

#Return exit/error code 2 if the remote zip file does not exist
If (Test-Path -Path $ArchiveFile -PathType Leaf) {
    Exit 0
} Else {
    Exit 2
}