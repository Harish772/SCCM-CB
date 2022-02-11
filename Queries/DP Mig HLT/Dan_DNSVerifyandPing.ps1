#$Computers = Get-Content J:\Scripts\DNSCheck\patrickcomputername.txt
$Computers = import-csv J:\Scripts\DNSCheck\Danalldps7-9.csv

foreach ($Computer in $Computers){

    $DNSINFO = $NULL
    $DNSINFO = [System.Net.Dns]::GetHostEntry("$($computer.name)")

    if($DNSINFO){

    #"$($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29DNSVerified.txt -append
    $computer.DNS = "Yes"
    $computer.Hostname = $DNSINFO.Hostname
        if (Test-Connection "$($DNSINFO.HostName)" -Count 1 -ea 0 -Quiet){

        #"Can Ping $($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29Pingresult.txt -append
        $computer.PING = "Yes"

        } else {

        #"Cannot Ping $($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29Pingresult.txt -append
        $computer.PING = "NO"

        }

        $Path = "\\$($DNSINFO.Hostname)\admin$"
        if ([bool]([System.Uri]$path).IsUnc){

        $Computer.Path = "Yes"

        } else {

        $Computer.Path = "No"

        }

    } else {

    $Computer.DNS = "NO"
    #$($Computer.name) | out-file J:\Scripts\DNSCheck\10-29NoDNS.txt -append
    $Inncode = $Computer.name.Substring(0,5)
    $InncodeDNSINFO = @()
    $InncodeDNSINFO = [System.Net.Dns]::GetHostEntry("$Inncode.hilton.com")
        if($InncodeDNSINFO){

        $Computer.HiltonDNS = "Yes"
        $computer.Hostname = $InncodeDNSINFO.Hostname
        if (Test-Connection "$($InncodeDNSINFO.HostName)" -Count 1 -ea 0 -Quiet){

            #"Can Ping $($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29Pingresult.txt -append
            $computer.PING = "Yes"

            } else {

            #"Cannot Ping $($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29Pingresult.txt -append
            $computer.PING = "NO"

            }

        $Path = "\\$($InncodeDNSINFO.Hostname)\admin$"
        if ([bool]([System.Uri]$path).IsUnc){

            $Computer.Path = "Yes"

            } else {

            $Computer.Path = "No"

            }

        } else {

        $Computer.HiltonDNS = "No"
        $computer.Ping = "NO"
        }

        }

}

$Computers | export-csv J:\scripts\dnscheck\allsccmdpsresults7-10.csv -NoTypeInformation

#$path = "\\ZZVOHSERVER.NA.HHCPR.HILTON.COM\admin$"
#[bool]([System.Uri]$path).IsUnc