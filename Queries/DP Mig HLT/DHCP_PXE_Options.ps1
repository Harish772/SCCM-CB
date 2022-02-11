$DP = '172.16.131.115'
$IPAddress = "172.16.131.5" #([System.Net.DNS]::GetHostAddresses($DP)|Where-Object {$_.AddressFamily -eq "InterNetwork"}   |  select-object IPAddressToString)[0].IPAddressToString

#Create Vendor Class if they don't exist.
if (-not (Get-DhcpServerv4Class -ComputerName $DP | ? { $_.Name -eq 'PXEClient (UEFI x64)' })) {
  Add-DhcpServerv4Class -ComputerName $DP -Name 'PXEClient (UEFI x64)' -Type Vendor -Description 'PXEClient (UEFI x64)' -Data 'PXEClient:Arch:00007'
}
if (-not (Get-DhcpServerv4Class -ComputerName $DP | ? { $_.Name -eq 'PXEClient (UEFI x86)' })) {
  Add-DhcpServerv4Class -ComputerName $DP -Name 'PXEClient (UEFI x86)' -Type Vendor -Description 'PXEClient (UEFI x86)' -Data 'PXEClient:Arch:00006'
}
if (-not (Get-DhcpServerv4Class -ComputerName $DP | ? { $_.Name -eq 'PXEClient (BIOS x86 & x64)' })) {
  Add-DhcpServerv4Class -ComputerName $DP -Name 'PXEClient (BIOS x86 & x64)' -Type Vendor -Description 'PXEClient (BIOS x86 & x64)' -Data 'PXEClient:Arch:00000'
}

#Create Option 060 if doesn't exist.
if (-not (Get-DhcpServerv4OptionDefinition -ComputerName $DP | ? { $_.OptionID -eq 060 })) {
  Add-DhcpServerv4OptionDefinition -ComputerName $DP -Name 'PXEClient' -Description 'PXE Support' -OptionId 060 -Type String
}

#Add Policy for Venfor Classes
Add-DhcpServerv4Policy -ComputerName $DP -Name 'PXEClient (UEFI x64)' -Condition And -VendorClass EQ,"PXEClient (UEFI x64)*"
Add-DhcpServerv4Policy -ComputerName $DP -Name 'PXEClient (UEFI x86)' -Condition And -VendorClass EQ,"PXEClient (UEFI x86)*"
Add-DhcpServerv4Policy -ComputerName $DP -Name 'PXEClient (BIOS x86 & x64)' -Condition And -VendorClass EQ,"PXEClient (BIOS x86 & x64)*"

#Activate Policies on Server
Set-DhcpServerSetting -ComputerName $DP -ActivatePolicies $true

#Set DHCP Options for each Policy
Set-DhcpServerv4OptionValue -OptionId 60 -ComputerName $DP -Value PXEClient -PolicyName "PXEClient (UEFI x64)"
Set-DhcpServerv4OptionValue -OptionId 66 -ComputerName $DP -Value $IPAddress -PolicyName "PXEClient (UEFI x64)"
Set-DhcpServerv4OptionValue -OptionId 67 -ComputerName $DP -Value "boot\x64\wdsmgfw.efi" -PolicyName "PXEClient (UEFI x64)"
Set-DhcpServerv4OptionValue -OptionId 60 -ComputerName $DP -Value PXEClient -PolicyName "PXEClient (UEFI x86)"
Set-DhcpServerv4OptionValue -OptionId 66 -ComputerName $DP -Value $IPAddress -PolicyName "PXEClient (UEFI x86)"
Set-DhcpServerv4OptionValue -OptionId 67 -ComputerName $DP -Value "boot\x86\wdsmgfw.efi" -PolicyName "PXEClient (UEFI x86)"
Set-DhcpServerv4OptionValue -OptionId 60 -ComputerName $DP -Value PXEClient -PolicyName "PXEClient (BIOS x86 & x64)"
Set-DhcpServerv4OptionValue -OptionId 66 -ComputerName $DP -Value $IPAddress -PolicyName "PXEClient (BIOS x86 & x64)"
Set-DhcpServerv4OptionValue -OptionId 67 -ComputerName $DP -Value "SMSboot\x86\wdsnbp.com" -PolicyName "PXEClient (BIOS x86 & x64)"