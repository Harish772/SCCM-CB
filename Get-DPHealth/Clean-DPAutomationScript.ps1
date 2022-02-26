Param(
[Parameter(Mandatory=$true,
HelpMessage="Enter UNC path to where 'ContentLibraryCleanup.exe' is located, e.g '\\MECMSERVER\D$\ContentLibraryCleanupTool\'")]
[String]
$ToolPath,
 
[Parameter(Mandatory=$true,
HelpMessage="Enter your MECM SiteCode, e.g 'A01'")]
[String]
$SiteCode,
 
[Parameter(Mandatory=$true,
HelpMessage="Enter the MECM server FQDN, e.g 'MECMSERVER.domain.com'")]
[String]
$ProviderMachineName
)
 
# Script to load the MECM Env.
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '2021-06-23 10:55:27'.
 
# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors
 
# Do not change anything below this line
 
# Import the ConfigurationManager.psd1 module
if((Get-Module ConfigurationManager) -eq $null) {
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}
 
# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
 
# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams
 
# Script to get DP's and run the ContentLibraryCleanuptool
# This script will run the CleanupUtility with the /delete switch instantly and will clean content without asking for confirmation.
# To read more about the tool visit:
# https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/hierarchy/content-library-cleanup-tool
 
# Get All DistributionPoints. "@()" is used when you want to run this on a specific DP, uncomment and replace "(Get-CMDistributionPoint).NetworkOSPath" i.e "$DPS = @(DP10110001)"
 
$DPS = (Get-CMDistributionPoint).NetworkOSPath
#$DPS = @("")
 
 
$TrimmedDPS = $DPS.trim("\")
Foreach($DP in $TrimmedDPS){
if($DP -like "**"){ #Add servernames or prefixes to except from DPCleanTool
Write-Output ”$DP found in exception, will skip.”
    }
Else{
$ContentLibCleanupTool = @{
FilePath = "$ToolPath\ContentLibraryCleanup.exe"
ArgumentList = @(
"/DP $DP"
"/Delete"
"/q"
            )
Wait = $True
Passthru = $True
RedirectStandardOutput = "$ToolPath\Logs\$DP-LibraryCleanup.log"
        }
Start-Process @ContentLibCleanupTool
    }
}