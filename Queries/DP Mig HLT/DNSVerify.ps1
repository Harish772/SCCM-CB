$Computers = Get-Content J:\Scripts\DNSCheck\computers.txt

foreach ($Computer in $Computers){

    $DNSINFO = $NULL
    $DNSINFO = [System.Net.Dns]::GetHostAddresses("$computer")

    if($DNSINFO){

    "$Computer $DNSINFO"  | out-file J:\Scripts\DNSCheck\DNSVerified.txt -append

    } else {

    $computer | out-file J:\Scripts\DNSCheck\NoDNS.txt -append

    }

}
