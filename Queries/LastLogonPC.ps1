PC where UserID is last logged on user SCCM

#Used when you have a user id but need to know the name of the computer where they were the last logged on user. If they are using a shared or generic pc where another user has logged in after them since they logged off and the sccm client has reported back already it may not reflect that.
#Wmi Call is rather long as it does a calculated select to convert the datetime from WMI format to a date format easily read, CIM does this conversion automatically for you.
$SiteCode = "" #example: HQ
$SCCMServer = "" #example: MySCCMServer.domain.com
$UserName= "" #This is the SAMAccountName listed in an AD object for a user. 
#WMI Version
Get-WmiObject -namespace "root\sms\site_$SiteCode" -ComputerName $SCCMServer -query "select * from sms_r_system where LastLogOnUserName='$UserName'" | Select-Object Name,MACAddresses,IPAddresses,OperatingSystemNameAndVersion,LastLogOnUserName,ResourceNames,SMBIOSGUID,@{Name="LastLogonTimestamp"; Expression = {[DateTime]::ParseExact(($_.LastLogonTimestamp).split('.')[0], 'yyyyMMddHHmmss', $null)}}
#CIM Instance
Get-CimInstance -namespace "root\sms\site_$SiteCode" -ComputerName $SCCMServer -query "select * from sms_r_system where LastLogOnUserName='$UserName'" | Select-Object Name,MACAddresses,IPAddresses,LastLogonTimestamp,OperatingSystemNameAndVersion,LastLogOnUserName,ResourceNames,SMBIOSGUID
