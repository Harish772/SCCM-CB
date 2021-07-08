#Used when all you have is a computer name no one is logged in currently or is now offline such as laptop or desktop at remote site. As long as their client has reported back who loggedin last you can get a user name for that person.
#Wmi Call is rather long as it does a calculated select to convert the datetime from WMI format to a date format easily read, CIM does this conversion automatically for you.
$SiteCode = "" #example: HQ
$SCCMServer = "" #example: MySCCMServer.domain.com
$PCName= "" #This is the Computer Name listed in SCCM that you want infomraiton from.
#WMI Version
Get-WmiObject -namespace "root\sms\site_$SiteCode" -ComputerName $SCCMServer -query "select * from sms_r_system where Name='$PCName'" | Select-Object Name,MACAddresses,IPAddresses,OperatingSystemNameAndVersion,LastLogOnUserName,ResourceNames,SMBIOSGUID,@{Name="LastLogonTimestamp"; Expression = {[DateTime]::ParseExact(($_.LastLogonTimestamp).split('.')[0], 'yyyyMMddHHmmss', $null)}}
#Cim Instance
Get-CimInstance -namespace "root\sms\site_$SiteCode" -ComputerName $SCCMServer -query "select * from sms_r_system where Name='$PCName'" | Select-Object Name,MACAddresses,IPAddresses,LastLogonTimestamp,OperatingSystemNameAndVersion,LastLogOnUserName,ResourceNames,SMBIOSGUID
