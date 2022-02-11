# Microsoft provides script, macro, and other code examples for illustration only, without warranty either expressed or implied, including but not
# limited to the implied warranties of merchantability and/or fitness for a particular purpose. This script is provided 'as is' and Microsoft does not
# guarantee that the following script, macro, or code can be used in all situations. Microsoft does not support modifications of the script, macro,
# or code to suit customer requirements for a particular purpose. 
#
# While Microsoft support engineers can help explain the functionality of a particular script function, macro, or code example, they will not modify these
# examples to provide added functionality, nor will they help you construct scripts, macros, or code to meet your specific needs. If you have
# limited programming experience, you may want to consult one of the Microsoft Solution Providers. Solution Providers offer a wide range of fee-based services,
# including creating custom scripts. For more information about Microsoft Solution call Microsoft Customer Information Service at (800) 426-9400.


#####################################################################################################
# Pings computer, returns status
function Verify-Ping
	{
    param(
    $computerName
    )
	$wmiQuery = "SELECT * FROM win32_PingStatus WHERE address='" + $vMachine + "'"
	$pingResponse = Get-WmiObject -query $wmiQuery
	$resolved = $pingResponse.PrimaryAddressResolutionStatus
	$statusCode = $pingResponse.StatusCode
	if ($resolved -ne 0)
		{
		# Unable to resolve
        $pingStatus = "Unable to resolve"
		}
	else
		{
		# Machine name was resolved, let's see if it responded
		if ($statusCode -eq 0)
			{
			$pingStatus = "Success"
			}
		else
			{
			$pingStatus = "No response"
			}
		}
	Write-Host "`tPing status: $pingStatus"
    return $pingStatus
	}

#####################################################################################################
# Checks to verify that we can connect to and query the root\cimv2 namespace
Function Verify-WMIConnection
    {
    param(
    $computerName
    )
	Try
		{
		$wmiCompName = Get-WmiObject -query "SELECT Name FROM Win32_ComputerSystem" -computer $computerName
        If ($?)
            {
            $wmiStatus = "Success"
            }
        Else
            {
            Throw $error[0].Exception
            }
		}
	Catch
		{
		# For any other error, log a general WMI failure
		$wmiStatus = "$($_.Exception.message)"
		}
    Write-Host "`tWMI status: $wmiStatus"
    Return $wmiStatus
    }

#####################################################################################################
# Checks to verify that the SCCM client service is Automatic and running
function Verify-CMClientService
	{
    param(
    $computerName
    )
	Try
		{
		$CcmSvc = Get-WmiObject -query "SELECT * FROM Win32_Service WHERE Name='CcmExec'" -computer $computerName
        If ($?)
            {
            if ($CcmSvc.StartMode -eq "Auto")
                {
                $clientServiceStatus = $($CcmSvc.State)
                }
            Else
                {
                $clientServiceStatus = $($CcmSvc.StartMode)
                }
            }
        Else
            {
            Throw $error[0].Exception
            }
		}
	Catch [System.Exception]
		{
		#For any other error, log a general WMI failure
		$clientServiceStatus = "$($_.Exception.message)"
		}
    Write-Host "`tClient service status: $clientServiceStatus"
	return $clientServiceStatus
	}


Function Get-CMClientStatusDetails
    {
    param(
    $computerName
    )
    Try
        {
        $smsClient = Get-WmiObject -Namespace "root\ccm" -Query "SELECT ClientVersion FROM SMS_Client" -computer $computerName
        If ($?)
            {
            $clientVersion = $smsClient.ClientVersion
            }
        $ccmRebootPending = Invoke-WmiMethod -Namespace "root\ccm\ClientSDK" -Class "CCM_ClientUtilities" -Name "DetermineIfRebootPending" -ComputerName $computerName
        If ($?)
            {
            $RebootPending = $ccmRebootPending.RebootPending
            $IsHardRebootPending = $ccmRebootPending.IsHardRebootPending
            }
        $clientStatusDetails = @($clientVersion,$RebootPending,$IsHardRebootPending)
        }
    Catch
        {
        $clientStatusDetails = @("Exception","$($_.Exception.message)")
        }    
    Write-Host "`tClient version: $clientVersion"
    Return $clientStatusDetails
    }


Function Get-CCMSetupStartTime
    {
    param(
    $computerName
    )
    Try
		{
		$ccmSetup = Get-WmiObject -query "SELECT CreationDate FROM Win32_Process WHERE Name = 'ccmsetup.exe'" -computer $computerName
        If ($?)
            {
            $ccmSetupStarted = $ccmSetup.ConvertToDateTime($ccmSetup.CreationDate)
            }
        Else
            {
            Throw $error[0].Exception
            }
		}
	Catch
		{
		# For any other error, log a general WMI failure
		$ccmSetupStarted = "$($_.Exception.message)"
		}
    Write-Host "`tCCMSetup started: $ccmSetupStarted"
    
    Return $ccmSetupStarted
    }
#####################################################################################################
# End Functions, begin script work
#####################################################################################################


$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$scriptStartTime = Get-Date -format yyyyMMdd-hhmmss
$scriptLog = "$scriptPath\Check-RemoteSystems_$($scriptStartTime).txt"
"ComputerName`tPingStatus`twmiStatus`tClientServiceStatus`tClientVersion`tRebootPending`tHardRebootPending`tCCMSetupRunningSince" | Out-File $scriptLog

$computerList = Get-Content "$scriptPath\computerList.txt"

ForEach ($computerName in $computerList)
    {
    Write-Host "$computerName" -ForegroundColor Yellow
    $pingStatus = Verify-Ping -computerName $computerName
    If ($pingStatus -eq "Success")
        {
        $wmiStatus = Verify-WMIConnection -computerName $computerName
        If ($wmiStatus -eq "Success")
            {
            $clientServiceStatus = Verify-CMClientService -computerName $computerName
            $clientStatusDetails = Get-CMClientStatusDetails -computerName $computerName
            $clientVersion = $clientStatusDetails[0]
            $rebootPending = $clientStatusDetails[1]
            $isHardRebootPending = $clientStatusDetails[2]
            $ccmSetupStarted = Get-CCMSetupStartTime -computerName $computerName
            }
        }
    "$computerName`t$pingStatus`t$wmiStatus`t$clientServiceStatus`t$clientVersion`t$rebootPending`t$isHardRebootPending`t$ccmSetupStarted" | Out-File $scriptLog -Append
    }
