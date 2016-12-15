# iLORestAPI
Basic PowerShell construct for interacting with HP iLO via the RestAPI

## Synopsis

Collection of functions that can be leveraged to establish session connection and interact with HP iLO RestAPI using PowerShell

## Description

* **New-HpSession**
  * Creates an ILO session and returns the session details
* **Remove-HpSession**
  * Closes an existing ILO session
* **Get-HPSetting**
  * Gets settings from the HP BIOS using the ILO API
* **Test-Call**
  * Testing function only for interacting with various iLO API URI's
* **Set-HPBIOSSettings**
  * Makes changes to the BIOS that are specified in the JSON payload

## Prerequisites

* HP Gen9 Server with iLO capability

## How to run

1. Establish an iLO session
 * ```powershell 
	$session = New-HpSession -ip $ip -username $username -password $password
	```
   * *Note: If your workstation isn't configured to trust the iLO cert the New-HpSession will prompt you if you wish to temporarily ignore the iLO cert warning*

2. Interact with the session
 * ```powershell 
	Get-HPSetting -Session $session -Config "Boot"
	```
   * *This will retrieve the pending BIOS settings*
 * ```powershell 
	Get-HPSetting -Session $session -Config "Running"
	```
   * *This will retrieve the current BIOS settings*
 * ```powershell 
	Test-Call -IP $ip -Session $session
	```
   * *This will retrieve information for the non-commented URI.  This test function contains several URI examples so you can experiment with retrieving info from each one by commenting out and un-commenting different addresses*
 * ```powershell 
	Set-HPBIOSSettings -IP $ip -Json $json -Session $session
	```
   * *This will send the specified JSON payload and make real changes to the server based on options specified in the JSON payload*

3. Remove the iLO session
 * ```powershell 
	Remove-HpSession -Session $Session
	```

### Contributors

Authors: Jake Morrison

http://techthoughts.info

### Notes

http://techthoughts.info/ilo-restful-api-powershell