$DPservers = Get-Content 'J:\Scripts\Reggie\DP Content Removal\DPContentCleanup\DPsToClean.txt'
#$DPServers ='MOWNRFS1'
 
import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
$PSD = Get-PSDrive -PSProvider CMSite

CD "HLT:"
$SiteServer = 'HFWDBSCCM01PH'
$SiteCode ='HLT'


$CSVFile = "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup\DPContentCleanup.csv"
$LogFile = "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup\DPContentCleanup.log"


################# FUNCTIONS #########################################################################################

# Function to Write To Log
Function Write-ToLog([string]$file, [string]$message) {       
    $Date = $(get-date -uformat %Y-%m-%d-%H.%M.%S)
    $message = "$Date`t$message"
    Write-Verbose $message

    #Write out to log file
    Out-File $file -encoding ASCII -input $message -append
}


# Function to find potential DP server name
Function Get-DPName ($GDPName){

    If (Get-CMDevice -Name "$GDPName`SERVER"){
        $GDPName = "$GDPName`SERVER.na.hhcpr.hilton.com"
    }
    Elseif (Get-CMDevice -Name "$GDPName`FS1"){
        $GDPName = "$GDPName`FS1.na.hhcpr.hilton.com"
    }
    Else{
        write-host "ERROR: $GDPName DP not found" -foregroundcolor Red
        $GDPName = "Fail"
    }

    $GDPName = $GDPName.ToUpper()
    return $GDPName
}


Function RemovePackage ($DP, $PkgID) {

    $pkgtype = $null


    # Find package type
    $pkg = Get-CMPackage -ID $PkgID -Fast
    $pkgtype = "Package"

    if(!($pkg)) { 
    #$PkgIDInterger = $PkgID -as [int32]
    #$pkg = Get-CMApplication -ID $PkgIDInterger -Fast
    $AppName = (Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -class SMS_ObjectContentInfo -Filter "PackageID = '$PkgID'").softwareName
    $pkg = Get-CMApplication -Name $AppName -Fast
    $pkgtype = "Application" }

    if(!($pkg)) { 
    $pkg = Get-CMSoftwareUpdateDeploymentPackage -ID $PkgID
    $pkgtype = "SoftwareUpdatePackage" }

    if(!($pkg)) { 
    $pkg = Get-CMDriverPackage -ID $PkgID
    $pkgtype = "DriverPackage" }
    
    if(!($pkg)) { 
    $pkg = Get-CMBootImage -ID $PkgID
    $pkgtype = "BootImage" }

    if(!($pkg)) { 
    $pkg = Get-CMOperatingSystemImage -ID $PkgID
    $pkgtype = "OperatingSystemImage" }

    if(!($pkg)) { 
    $pkg = Get-CMOperatingSystemInstaller -ID $PkgID
    $pkgtype = "OperatingSystemInstaller" }

    if(!($pkg)) { 
    $pkg = Get-CMTaskSequence -ID $PkgID
    $pkgtype = "TaskSequence" }



    #Write-Host "$PkgID is $pkgtype"
    Write-ToLog $LogFile "INFO   `t$PkgID is $pkgtype"

    #Return $pkgtype



    if($pkgtype -eq "Package") { 
    
        try {
            Remove-CMContentDistribution -PackageID $PkgID -DistributionPointName $DP -Force 
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }

    if($pkgtype -eq "SoftwareUpdatePackage") {

        try {
            Remove-CMContentDistribution -DeploymentPackageID $PkgID -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
        }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }

    if($pkgtype -eq "DriverPackage") {
        try {
            Remove-CMContentDistribution -DriverPackageID $PkgID -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }

    if($pkgtype -eq "Application") {
            try {
            Remove-CMContentDistribution -ApplicationName $AppName -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }

    if($pkgtype -eq "BootImage") {
        try {
            Remove-CMContentDistribution -BootImageId $PkgID -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }

    if($pkgtype -eq "OperatingSystemImage") {
        try {
            Remove-CMContentDistribution -OperatingSystemImageId $PkgID -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }

        if($pkgtype -eq "OperatingSystemInstaller") {
        try {
            Remove-CMContentDistribution -OperatingSystemInstallerId $PkgID -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }
    
    if($pkgtype -eq "TaskSequence") {
        try {
            Remove-CMContentDistribution -TaskSequenceId $PkgID -DistributionPointName $DP -Force
            #write-host "Removing $PkgID from $DP" -ForegroundColor green
            Write-ToLog $LogFile "INFO   `tRemoving $PkgID from $DP"
            }
        Catch {
            #write-host "$PkgID not found on $DP" -ForegroundColor red
            Write-ToLog $LogFile "ERROR   `t$PkgID not found on $DP"
        }
    }
  
    Return $pkgtype  
        
#>

}

Function ContentLibraryCleanup ($DP2Clean, $pswd) {

<#$DP2Clean ='ABGVASERVER'

            CD "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup"
            $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
            & "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup\ContentLibraryCleanup.exe" /q /dp $DP2Clean /delete /log "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup"
            $stopwatch.Stop()
            Write-ToLog $LogFile "INFO   `t$DP2Clean content library cleanup took $($stopwatch.Elapsed.ToString('dd\.hh\:mm\:ss')) to complete"
            CD "HLT:"


#>


            CD "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup"
            $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
            
            Invoke-Command -Credential $pswd -ScriptBlock 
            & "J:\Scripts\Reggie\DP Content Removal\DPContentCleanup\ContentLibraryCleanup.exe" /q /dp $DP2Clean /delete /log "C:\Temp"




}

Function GetPKGTypeCommand ($GetDPserver, $GetPKGID, $GetPKGType) {

    if ($GetPKGType -eq "Application") {
        $GetAppName = (Get-WmiObject -ComputerName $SiteServer -Namespace "root\sms\site_$SiteCode" -class SMS_ObjectContentInfo -Filter "PackageID = '$GetPKGID'").softwareName
        $DistributeCommand = "Start-CMContentDistribution –ApplicationName $GetAppName –DistributionPointName $GetDPserver"
    }
    Elseif ($FindPKGType -eq "SoftwareUpdatePackage") {
        $DistributeCommand = "Start-CMContentDistribution -DeploymentPackageId $GetPKGID –DistributionPointName $GetDPserver"
    }
    Elseif ($FindPKGType -eq "Package") {
        $DistributeCommand = "Start-CMContentDistribution –PackageID $GetPKGID –DistributionPointName $GetDPserver"
    }
    Elseif ($FindPKGType -eq "DriverPackage") {
        $DistributeCommand = "Start-CMContentDistribution –DriverPackageID $GetPKGID –DistributionPointName $GetDPserver"
    }
    Elseif ($FindPKGType -eq "BootImage") {
        $DistributeCommand = "Start-CMContentDistribution –BootImageID $GetPKGID –DistributionPointName $GetDPserver"
    }
    Elseif ($FindPKGType -eq "OperatingSystemImage") {
        $DistributeCommand = "Start-CMContentDistribution –OperatingSystemImageID $GetPKGID –DistributionPointName $GetDPserver"
    }
    Elseif ($FindPKGType -eq "OperatingSystemInstaller") {
        $DistributeCommand = "Start-CMContentDistribution –OperatingSystemInstallerID $GetPKGID –DistributionPointName $GetDPserver"
    }
    Else {
        #write-host "Failed to get proper package type command for $GetDPserver $GetPKGID $FindPKGType"
        Write-ToLog $LogFile "ERROR   `tFailed to get proper package type command for $GetDPserver $GetPKGID $FindPKGType"
        $DistributeCommand = "FAIL"
    }
    
    Return $DistributeCommand

}





######################################## MAIN ######################################
 
 Write-ToLog $LogFile "START   `tDP Content Cleanup has started."

 # Get credentials
 #$Secret = Get-Credential

 foreach ($Server in $DPservers)
 {

    #$Server = Get-DPName $Server
    $DistributionPoint = Get-WmiObject -Namespace root/sms/site_hlt -Query "Select NALPath,Name From SMS_DistributionPointInfo Where ServerName Like '%$Server%'"
    $ServerNalPath = $DistributionPoint.NALPath -replace "([\[])",'[$1]' -replace "(\\)",'\$1'

 
    $FailedPackages = Get-WmiObject -Namespace root/sms/site_hlt -Query "Select PackageID From SMS_PackageStatusDistPointsSummarizer Where ServerNALPath Like '$ServerNALPath' AND (State != '0')"
    
    Write-Host "There are $($FailedPackages.count) failed packages on $($DistributionPoint.Name)" -ForegroundColor Yellow
    Write-ToLog $LogFile "INFO   `tThere are $($FailedPackages.count) unsuccessful packages on $($DistributionPoint.Name)"

    Foreach($Package in $FailedPackages)
    {

        write-host $DistributionPoint.Name " failed " $Package.PackageID
        #Write-ToLog $LogFile "INFO   `t$($Package.PackageID) failed on $($DistributionPoint.Name)"
            
        $PKGTypeMain = RemovePackage  $($DistributionPoint.Name) $($Package.PackageID)
        [pscustomobject]@{ DPName = $DistributionPoint.Name; PackageID =  $Package.PackageID; PackageType = $PKGTypeMain } | Export-Csv -Path  $CSVFile -Append -NoTypeInformation


    }

    <#

    Start-Sleep -s 300
    Write-ToLog $LogFile "START   `tContent Library Cleanup on $($DistributionPoint.Name) has started. Check log for further details."
    ContentLibraryCleanup $DistributionPoint.Name $Secret
    Write-ToLog $LogFile "END   `tContent Library Cleanup on $($DistributionPoint.Name) has ended. Check log for further details."

    #write-host ""
    
    #>

}

<#
Start-Sleep -s 600

# Redistribute to DPs
Write-ToLog $LogFile "START   `tRedistribution process starting."
$infile = Import-Csv $CSVFile
Foreach ($entry in $infile) { 


    $PKGTypeCommand = GetPKGTypeCommand $($entry.'DPName') $($entry.'PackageID')  $($entry.'PackageType')

    if ($PKGTypeCommand -ne "FAIL") {
        Try {
            #Write-Host "Distributing $($entry.'PackageID') to $($entry.'DPName')"
            Write-ToLog $LogFile "INFO   `tDistributing $($entry.'PackageID') to $($entry.'DPName')"
            $PKGTypeCommand
        }
        Catch {
            #Write-Host "Failed to distribute $($entry.'PackageID') to $($entry.'DPName')" -foregroundcolor Yellow
            Write-ToLog $LogFile "ERROR   `tFailed to distribute $($entry.'PackageID') to $($entry.'DPName')"
        }
    }

}

#>

Write-ToLog $LogFile "END   `tDP Content Cleanup has ended."