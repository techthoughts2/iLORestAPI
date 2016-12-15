<#
	.SYNOPSIS
		Creates an ILO session
	.DESCRIPTION
		Creates an ILO session and returns the session details
	.PARAMETER ip
		The IP of the ILO device you are trying to establish a session to
	.PARAMETER username
		The username that will be used to authenticate for the iLO session
	.PARAMETER password
		The password that will be used to authenticate for the iLO session
	.EXAMPLE
		$session = New-HpSession -ip $ip -username $username -password $password
#>
function New-HpSession {
	param
	(
		[Parameter(Mandatory = $true,
				   HelpMessage = 'IP of iLO device')]
		[string]$ip,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Username for iLO')]
		[string]$username,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Password for iLO')]
		[string]$password
	)
	# Create the JSON request to pass the ILO credentials to the API
	$CredentialsJson = "{
    `"UserName`": `"$username`",
    `"Password`": `"$password`"
    }"
	
	$cert = $false
	#first attempt
	try {
		# Send the request
		$Script:SessionJson = Invoke-WebRequest -Uri "https://$ip/rest/v1/Sessions" -Method Post -Body $CredentialsJson -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
		# Return the session details
		Return $Script:SessionJson
	}
	catch {
		if ($_ -like "*trust relationship*") {
			Write-Host "The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel." -ForegroundColor Red
			$choice = $null
			while ("yes", "no" -notcontains $choice) {
				$choice = Read-Host "Would you like to temp disable certificate checking for the iLO device? (yes/no)"
			}
			if ($choice -eq "yes") {
				# Disable certificate checking as the ILO certificate is not trusted
				if ([System.Net.ServicePointManager]::CertificatePolicy -ne "IDontCarePolicy") {
					add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
    
        public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
					[System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy
				}
				# Send the request to the API
				$Script:SessionJson = Invoke-WebRequest -Uri "https://$ip/rest/v1/Sessions" -Method Post -Body $CredentialsJson -ContentType "application/json" -UseBasicParsing
			}
			else {
				Write-Host "Could not establish iLO session due to Certificate verficaition errors." -ForegroundColor Magenta
			}
		}
		else {
			Write-Error $_	
		}
	}
	
	# Return the session details
	Return $Script:SessionJson
}
<#
    .SYNOPSIS
    	Closes an ILO session
    .DESCRIPTION
    	Closes an existing ILO session
    .PARAMETER Session
    	An object representing the details of the session to close
    .EXAMPLE
    	Remove-HpSession -Session $Session
#>
Function Remove-HpSession {
	Param (
		[Parameter(Mandatory = $true)]
		[object]$Session
	)
	
	# Create the auth header
	$AuthHeaders = @{ "X-Auth-Token" = $Session.Headers.'X-Auth-Token' }
	
	# Send the request to the API
	$EndSessionJson = Invoke-WebRequest -Uri $Session.Headers.Location -Method Delete -Headers $AuthHeaders -UseBasicParsing
	
	# Return the response from the API
	Return $EndSessionJson
}
<#
	.SYNOPSIS
		Gets settings from the HP BIOS
	.DESCRIPTION
		Gets settings from the HP BIOS using the ILO API
	.PARAMETER Config
		Specifies whether to retrieve the boot or running config
	.PARAMETER Session
		An object representing the details of the session to use - created by New-HpSession
	.PARAMETER IP
		Specifies the iLO IP that you are connecting to
	.EXAMPLE
		Get-HPSetting -Session $session -Config "Boot"
		Requires a previously established iLO session and the desired congiguration (Boot or Running)
	.NOTES
		BOOT 	: BIOS Pending Settings
		RUNNING : BIOS Current Settings
#>
function Get-HPSetting {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateSet("Boot", "Running")]
		[string]$Config,
		[Parameter(Mandatory = $true)]
		[object]$Session,
		[Parameter(Mandatory = $true)]
		[string]$IP
	)
	
	# Create the auth header
	$AuthHeaders = @{ "X-Auth-Token" = $Session.Headers.'X-Auth-Token' }
	
	# Check which config needs to be retrieved and send the request as appropriate
	if ($Config -eq "Boot") {
		$BiosSettingsJson = Invoke-WebRequest -Uri "https://$ip/rest/v1/Systems/1/Bios/Settings" -Method Get -Headers $AuthHeaders
	}
	elseif ($Config -eq "Running") {
		$BiosSettingsJson = Invoke-WebRequest -Uri "https://$ip/rest/v1/Systems/1/Bios" -Method Get -Headers $AuthHeaders
	}
	
	Return $BiosSettingsJson
}
<#
	.SYNOPSIS
		Testing function only for interacting with various iLO API URI's
	.DESCRIPTION
		Testing function only for interacting with various iLO API URI's
	.PARAMETER Session
		An object representing the details of the session to use - created by New-HpSession
	.PARAMETER IP
		Specifies the iLO IP that you are connecting to
	.EXAMPLE
		Test-Call -IP $ip -Session $session
#>
function Test-Call {
	param
	(
		[Parameter(Mandatory = $true)]
		[object]$Session,
		[Parameter(Mandatory = $true)]
		[string]$IP
	)
	# Create the auth header
	$AuthHeaders = @{ "X-Auth-Token" = $session.Headers.'X-Auth-Token' }
	#************************************************************************************
	Try {
		#$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/Chassis/1/PowerMetrics" -Method Get -Headers $AuthHeaders -ErrorAction Stop
		#$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/systems/1" -Method Get -Headers $AuthHeaders
		#$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/Systems/1" -Method Get -Headers $AuthHeaders
		#$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/Systems/1/Bios/Settings" -Method Get -Headers $AuthHeaders
		#$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/Systems/1/Bios" -Method Get -Headers $AuthHeaders
		#$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/systems/1/bios/Boot" -Method Get -Headers $AuthHeaders
		$json = Invoke-WebRequest -Uri "https://$ip/rest/v1/Chassis/1" -Method Get -Headers $AuthHeaders -UseBasicParsing -ErrorAction Stop
	}
	Catch {
		Write-Host $_
	}
	#************************************************************************************
	Return $json
}
<#
    .SYNOPSIS
    	Posts changes to the BIOS
    .DESCRIPTION
    	Makes changes to the BIOS that are specified in the JSON payload
   	.PARAMETER Session
		An object representing the details of the session to use - created by New-HpSession
	.PARAMETER IP
		Specifies the iLO IP that you are connecting to
    .EXAMPLE
    	Set-HPBIOSSettings -IP $ip -Json $json -Session $session
	.NOTES
		Returns a true/false if settings were succesfully changed
#>
Function Set-HPBIOSSettings {
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "IP")]
		[string]$IP,
		[Parameter(Mandatory = $true)]
		[string]$Json,
		[object]$Session
	)
	
	# Create the auth header
	$AuthHeaders = @{ "X-Auth-Token" = $Session.Headers.'X-Auth-Token' }
	
	$results = $false
	# Send the request to the API
	try {
		$HyperthreadingJson = Invoke-WebRequest -Uri "https://$ip/rest/v1/Systems/1/Bios/Settings" -Method Patch -Headers $AuthHeaders -Body $Json -ContentType "application/json" -ErrorAction Stop
		$results = $true
	}
	catch {
		$results = $false
	}
	return $results
}
##########################################################
#some examples of how to run
##########################################################
<#
#1. Pushing BIOS setting changes
#declare the changes to be made in JSON:
$noNICBootingJSON = "{
				`"NicBoot1`": `"Disabled`",
				`"NicBoot2`": `"Disabled`",
				`"NicBoot3`": `"Disabled`",
				`"NicBoot4`": `"Disabled`",
				`"NicBoot5`": `"Disabled`",
				`"NicBoot6`": `"Disabled`"
            }"
$ip = '172.17.0.17' #ip of iLO
#get a session
$session = New-HpSession -ip $ip -username username -password password
Set-HPBIOSSettings -IP $ip -Json $noNICBootingJSON -Session $session
Remove-HpSession -Session $session
#____________________________________________
#2. Get BIOS settings
$ip = '172.17.0.17' #ip of iLO
#get a session
$session = New-HpSession -ip $ip -username username -password password
Get-HPSetting -Config Boot -Session $session -IP $ip
$biosBootSettings = ConvertFrom-Json (Get-HPSetting -Session $session -Config "Boot" -IP $ip)
$biosRunSettings = ConvertFrom-Json (Get-HPSetting -Session $session -Config "Running" -IP $ip)
Remove-HpSession -Session $session
#>
##########################################################
##########################################################