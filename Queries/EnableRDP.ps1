# Enable Remote Desktop

#Set HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections = 0
(Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1,1) | Out-Null
#Alternate commandline: cmd /c Reg add “HKEY_LOCAL_MACHINE\SYSTEM\CurentControlSet\Control\Terminal Server”  /v fDenyTSConnections /t REG_DWORD /d 0 /f
#Disable Network Level Authentication useful in the event Domain Contoler auth isn't avaliable.
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) | Out-Null
#Server 2012/Window8 and above, Enable's ALL RDP related firewall rules. TCP in, UDP in, Shadown TCP in.
Get-NetFirewallRule -DisplayName "Remote Desktop*" | Set-NetFirewallRule -enabled true
