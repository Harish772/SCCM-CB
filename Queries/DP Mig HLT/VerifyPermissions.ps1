 $Computers = Get-Content J:\Scripts\DNSCheck\oldDNSVerified.txt
 
 foreach($Computer in $Computers){                   
            if (Test-Connection "$($computer)" -Count 1 -ea 0 -Quiet)
                    {                   
                        #Test for access to C$
                        if (Test-Path -Path \\$($computer)\ADMIN$)
                        {
                    
                        Write-Verbose "Can Access C on $($computer)"
                        $Computer | out-file J:\scripts\DNScheck\DNSVerifiedC.txt -append
                        
                        } else {
                
                        Write-Verbose "Cannot Access C$ on $($computer)"
                        $Computer | out-file J:\scripts\DNScheck\DNSverifiednoC.txt -append
                        
                        }

                    } else {

                    $Computer | out-file J:\scripts\DNScheck\DNSverifiedCannotPing.txt -append

                    }

}