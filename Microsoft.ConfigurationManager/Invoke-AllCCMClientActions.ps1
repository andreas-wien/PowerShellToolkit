<#
.SYNOPSIS
    Invokes all CCM client actions.
.DESCRIPTION
    Invokes all CCM client actions.
.EXAMPLE
    C:\PS> Get-InstalledUpdates.ps1
.EXAMPLE
    C:\PS> Get-InstalledUpdates.ps1 -ComputerName "Client01"
.EXAMPLE
    C:\PS> $computers = Get-ADComputer -Filter "Name -like 'Client0*"; Get-InstalledUpdates.ps1 -ComputerName $computers.Name
.PARAMETER computerName
    The fqdn, hostname or IP address of the computer on which the actions should be invoked. Defaults to the local computer. Accepts a list of values.
.NOTES
    Author: Andreas P.
    Date: November 15, 2024
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string[]]
    $computerName = @($Env:COMPUTERNAME)
)
$ccmActionsCSV = 'Action,ID
"Hardware Inventory","{00000000-0000-0000-0000-000000000001}"
"Software Inventory","{00000000-0000-0000-0000-000000000002}"
"Data Discovery Record","{00000000-0000-0000-0000-000000000003}"
"File Collection","{00000000-0000-0000-0000-000000000010}"
"IDMIF Collection","{00000000-0000-0000-0000-000000000011}"
"Client Machine Authentication","{00000000-0000-0000-0000-000000000012}"
"Machine Policy Assignments Request","{00000000-0000-0000-0000-000000000021}"
"Machine Policy Evaluation","{00000000-0000-0000-0000-000000000022}"
"Refresh Default MP Task","{00000000-0000-0000-0000-000000000023}"
"LS (Location Service) Refresh Locations Task","{00000000-0000-0000-0000-000000000024}"
"LS (Location Service) Timeout Refresh Task","{00000000-0000-0000-0000-000000000025}"
"Policy Agent Request Assignment (User)","{00000000-0000-0000-0000-000000000026}"
"Policy Agent Evaluate Assignment (User)","{00000000-0000-0000-0000-000000000027}"
"Software Metering Generating Usage Report","{00000000-0000-0000-0000-000000000031}"
"Source Update Message","{00000000-0000-0000-0000-000000000032}"
"Clearing proxy settings cache","{00000000-0000-0000-0000-000000000037}"
"Machine Policy Agent Cleanup","{00000000-0000-0000-0000-000000000040}"
"User Policy Agent Cleanup","{00000000-0000-0000-0000-000000000041}"
"Policy Agent Validate Machine Policy / Assignment","{00000000-0000-0000-0000-000000000042}"
"Policy Agent Validate User Policy / Assignment","{00000000-0000-0000-0000-000000000043}"
"Retrying/Refreshing certificates in AD on MP","{00000000-0000-0000-0000-000000000051}"
"Peer DP Status reporting","{00000000-0000-0000-0000-000000000061}"
"Peer DP Pending package check schedule","{00000000-0000-0000-0000-000000000062}"
"SUM Updates install schedule","{00000000-0000-0000-0000-000000000063}"
"Hardware Inventory Collection Cycle","{00000000-0000-0000-0000-000000000101}"
"Software Inventory Collection Cycle","{00000000-0000-0000-0000-000000000102}"
"Discovery Data Collection Cycle","{00000000-0000-0000-0000-000000000103}"
"File Collection Cycle","{00000000-0000-0000-0000-000000000104}"
"IDMIF Collection Cycle","{00000000-0000-0000-0000-000000000105}"
"Software Metering Usage Report Cycle","{00000000-0000-0000-0000-000000000106}"
"Windows Installer Source List Update Cycle","{00000000-0000-0000-0000-000000000107}"
"Software Updates Assignments Evaluation Cycle","{00000000-0000-0000-0000-000000000108}"
"Branch Distribution Point Maintenance Task","{00000000-0000-0000-0000-000000000109}"
"Send Unsent State Message","{00000000-0000-0000-0000-000000000111}"
"State System policy cache cleanout","{00000000-0000-0000-0000-000000000112}"
"Scan by Update Source","{00000000-0000-0000-0000-000000000113}"
"Update Store Policy","{00000000-0000-0000-0000-000000000114}"
"State system policy bulk send high","{00000000-0000-0000-0000-000000000115}"
"State system policy bulk send low","{00000000-0000-0000-0000-000000000116}"
"Application manager policy action","{00000000-0000-0000-0000-000000000121}"
"Application manager user policy action","{00000000-0000-0000-0000-000000000122}"
"Application manager global evaluation action","{00000000-0000-0000-0000-000000000123}"
"Power management start summarizer","{00000000-0000-0000-0000-000000000131}"
"Endpoint deployment reevaluate","{00000000-0000-0000-0000-000000000221}"
"Endpoint AM policy reevaluate","{00000000-0000-0000-0000-000000000222}"
"External event detection","{00000000-0000-0000-0000-000000000223}"'

$ccmActions = ConvertFrom-Csv $ccmActionsCSV -Delimiter ','

foreach ($ccmAction in $ccmActions) {
    Invoke-WMIMethod -ComputerName $computerName -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule $ccmAction.ID
}
