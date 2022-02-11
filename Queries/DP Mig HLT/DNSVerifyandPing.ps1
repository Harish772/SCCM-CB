#$Computers = Get-Content J:\Scripts\DNSCheck\patrickcomputername.txt
$Computers = import-csv J:\scripts\dnscheck\patrick.csv

foreach ($Computer in $Computers){

    $DNSINFO = $NULL
    $DNSINFO = [System.Net.Dns]::GetHostAddresses("$($computer.name)")

    if($DNSINFO){

    #"$($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29DNSVerified.txt -append
    $computer.DNS = "Yes"
        if (Test-Connection "$($computer.name)" -Count 1 -ea 0 -Quiet){

        #"Can Ping $($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29Pingresult.txt -append
        $computer.PING = "Yes"

        } else {

        #"Cannot Ping $($Computer.name) $DNSINFO"  | out-file J:\Scripts\DNSCheck\10-29Pingresult.txt -append
        $computer.PING = "NO"

        }

    } else {

    $Computer.DNS = "NO"
    $computer.Ping = "NO"
    #$($Computer.name) | out-file J:\Scripts\DNSCheck\10-29NoDNS.txt -append

    }

}

$Computers | export-csv J:\scripts\dnscheck\10-29results.csv -NoTypeInformation
