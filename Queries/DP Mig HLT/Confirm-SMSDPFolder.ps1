$servers = Get-Content J:\Scripts\ConfirmSMSDPFolder\server_list.txt

$count = $servers.Count

forEach( $server in $servers ) {
    
    Write-Host "$server $count"

    if( Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction SilentlyContinue) {

        if( -not ( Get-WmiObject Win32_Share -ComputerName $server | Where Name -like 'SMS_DP*' ) ) {

            $server | Out-File "J:\Scripts\ConfirmSMSDPFolder\no_sms_dp_folder.txt" -Append

        } else {

            $server | Out-File "J:\Scripts\ConfirmSMSDPFolder\good.txt" -Append

        }

    } else {

        $server | Out-File "J:\Scripts\ConfirmSMSDPFolder\unavailable.txt" -Append

    }

    $count -= 1
}