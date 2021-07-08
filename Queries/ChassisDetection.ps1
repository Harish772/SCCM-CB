#Will WIM Detect chassis type, match your string requirement to one of the follow: IsLaptop, IsDesktop, IsTablet, or IsServer
#Be sure to test in your enviroment to fit your needs. Microsoft Surface 4 is a type 9 which is "laptop" even though its a tablet device
#Lenovo X1Tablet First Gen are 32 "Detatachable"

$enclosureType = Get-WmiObject Win32_SystemEnclosure | select ChassisTypes

 If ($enclosureType.ChassisTypes[0] -eq 12 -or $enclosureType.ChassisTypes[0]-eq 21) {} #Ignore Docking Stations


 else {
     switch ($enclosureType.ChassisTypes[0]) {
     {$_ -in "8", "9", "10", "11", "12", "14", "18", "21","31"} {Write-Host "IsLaptop"}
     {$_ -in "32"} {Write-Host "IsTablet"}
     {$_ -in "3", "4", "5", "6", "7", "15", "16"} {Write-Host "IsDesktop"}
     {$_ -in "23"}{Write-Host "IsServer"}
     Default {Write-Host "Error Condition:" $_ `n`n "Full Output of Chassistype" $enclosureType.ChassisTypes }
     }
 }
 

# Below is the current list as of version 3.1.1 posted 1/13/2017.
# https://www.dmtf.org/standards/smbios  main standards site
# https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.1.1.pdf 2017 Standard doc

# Other (1)
# Unknown (2)
# Desktop (3)
# Low Profile Desktop (4)
# Pizza Box (5)
# Mini Tower (6)
# Tower (7)
# Portable (8)
# Laptop (9)
# Notebook (10)
# Hand Held (11)
# Docking Station (12)
# All in One (13)
# Sub Notebook (14)
# Space-Saving (15)
# Lunch Box (16)
# Main System Chassis (17)
# Expansion Chassis (18)
# SubChassis (19)
# Bus Expansion Chassis (20)
# Peripheral Chassis (21)
# RAID Chassis (22)
# Rack Mount Chassis (23)
# Sealed-case PC (24)
# Multi-system chassis (25)
# Compact PCI (26)
# Advanced TCA (27)
# Blade (28)
# Blade Enclosure (29)
# Tablet (30)
# Convertible (31) 
# Detachable (32)
# IoT Gateway (33)
# Embedded PC (34)
# Mini PC (35)
# Stick PC (36)
