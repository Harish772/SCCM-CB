[cmdletbinding()]
Param()

$Servers = Get-content "J:\Scripts\PXE\wdsutilservers.txt"
#$Servers = "bosfdserver"


foreach($Server in $Servers){
    
    Write-Host "Getting WDS Settings for $Server"
    $WDSSettings = wdsutil /get-server /server:$Server /show:Config
    $WDSSEttings | out-File J:\scripts\PXE\Tempwds.txt
    $DHCPOption60NO = Select-String -path J:\Scripts\PXE\Tempwds.txt -Pattern "DHCP option 60 configured: No"
    $DHCPOption60YES = Select-String -path J:\Scripts\PXE\Tempwds.txt -Pattern "DHCP option 60 configured: Yes"
    If($WDSSEttings -eq $null){

    Write-Host "No value retrieved for $Server"

    } else{

        If($DHCPoption60NO){

        Write-Host "$Server - Changing WDS Settings"
        wdsutil /set-server /server:$Server /UseDHCPPorts:No /DHCPOption60:yes
        #Verify Settings
        $WDSSettings = wdsutil /get-server /server:$Server /show:Config | out-file J:\Scripts\PXE\postchange.txt
        $VerifyDHCPOption60YES = Select-String -path J:\Scripts\PXE\postchange.txt -Pattern "DHCP option 60 configured: Yes"
            if($VerifyDHCPOption60YES){

            Write-Host "$Server WDS change successful, restarting Service" -BackgroundColor Green
            $service = Get-Service -Name wdsserver -ComputerName $Server
                $service.Status
                if($service.Status -eq "Running"){Get-Service -Name wdsserver -ComputerName $Server | Stop-Service -verbose}
                $service = Get-Service -Name wdsserver -ComputerName $Server
                $Service.Status

                $service = Get-Service -Name wdsserver -ComputerName $Server
                $Service.Status
                if($service.Status -eq "Stopped"){Get-Service -Name wdsserver -ComputerName $Server | Start-Service -verbose}
                $service = Get-Service -Name wdsserver -ComputerName $Server
                $Service.Status

            } else {

            Write-Host "$Server WDS Change did not take" -BackgroundColor Red
            write-host "$Server WDS Change did not take" | out-file J:\scripts\PXE\FailedWDS.log

            }


        } elseif($DHCPOption60YES){

        Write-Host "$Server - DHCP Option 60 already enabled" -BackgroundColor Green

        }

    }


}