cls
$ports = "80",
    "135",
    "443",
    "445",
    "4000",
    "8005",
    "8530",
    "8531",
    "10123"
$Info=@()
$Servers ="sccmmpw01ewmg",
           "sccmmpw01apmg"


ForEach($Server in $Servers){
    ForEach($Port in $Ports){
           if((Test-NetConnection -ComputerName $Server -Port $Port).TcpTestSucceeded){
                $status = Write-output "Active"
                }Else{
                $status = Write-output "Failed"
                }
                $Info += [pscustomobject][ordered]@{
                    ServerName  = $Server
                    PortName = $Port
                    Status  = $status
                }
    }
}
$Info |Export-Csv -Path "C:\$env:COMPUTERNAME.csv" -NoTypeInformation