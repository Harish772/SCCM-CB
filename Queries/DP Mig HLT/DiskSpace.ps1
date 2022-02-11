$Computers = Get-Content 'J:\Scripts\USB Content\drivespace.txt'

Foreach ($Computer in $Computers){

$disk = ([wmi]"\\$Computer\root\cimv2:Win32_logicalDisk.DeviceID='D:'")
"Remotecomputer D: has {0:#.0} GB free of {1:#.0} GB Total" -f ($disk.FreeSpace/1GB),($disk.Size/1GB) | Out-File "J:\scripts\usb Content\DiskSpaceResults.txt" -append


}