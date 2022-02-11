function get-ccmsetupfolder {
[cmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $InputFile,

        [Parameter(Mandatory=$true)]
        [string] $OutFile
    )

    $complist = Get-Content $InputFile
    $outstream = @()



    ForEach ($computer in $complist) {
        if (Test-Path "\\$($computer)\c$\ccmsetup") {
            $stream = ("C:\ccmsetup")
            Write-Verbose "$($computer) - C:\ccmsetup"
        } elseif (Test-Path "\\$($computer)\c$\Windows\ccmsetup") {
            $stream = ("C:\Windows\ccmsetup")
            Write-Verbose ("C:\Windows\ccmsetup")
        } elseif (Test-Path "\\$($computer)\c$\Winnt\ccmsetup") {
            $stream = ("C:\Winnt\ccmsetup")
            Write-Verbose ("C:\Winnt\ccmsetup")
        } elseif (Test-Path "\\$($computer)\c$\Windows\System\ccmsetup") {
            $stream = 
            Write-Verbose ("C:\Windows\System\ccmsetup")
        } elseif (Test-Path "\\$($computer)\c$\Windows\System32\ccmsetup") {
            $stream = ("C:\Windows\System32\ccmsetup")
            Write-Verbose ("C:\Windows\System32\ccmsetup")
        } else {
            $stream = "No ccmsetup Folder"
            Write-Verbose "$($computer) - No ccmsetup Folder"
        }

        $outstream += New-Object psobject -Property @{
            computername = $computer
            status = $stream
        }
    }

    $outstream | Export-Csv $OutFile -NoTypeInformation

}