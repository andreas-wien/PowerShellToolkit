<#
.SYNOPSIS
    Updates all ESX hosts in a vCenter server.
.DESCRIPTION
    Moves all VMs from the ESX host that needs to be updated in a load balanced fashion, then updates the ESX host. This is repeated until all hosts in the vCenter are up-to-date.
.PARAMETER vCenter
    The fqdn, hostname or IP address of the vCenter server to connect to.
.EXAMPLE
    C:\PS> Update-VMHost.ps1 -vCenter vcenter01.example.com
.NOTES
    Author: Andreas P.
    Date: January 16, 2024
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $vCenter
)
if (-not (Get-InstalledModule VMware.PowerCLI -ErrorAction SilentlyContinue)) {
    Install-Module -Name VMware.PowerCLI -Scope CurrentUser
}

Import-Module -Name VMware.PowerCLI

# Connect to the vCenter server
Connect-VIServer -Server $vCenter

# Get all virtual machines before migration
$allVMsBeforeMigration = Get-VM

# Get all hosts
$allHosts = Get-VMHost

foreach ($vmHost in $allHosts) {
    $vmHostToUpdate = Get-VMHost -Name $vmHost

    # Test compliance of the host
    Test-Compliance -Entity $vmHostToUpdate

    # Get the other hosts (excluding the current host)
    $otherHosts = $allHosts | Where-Object -FilterScript { $_.Name -ne $vmHostToUpdate.Name }

    # Get the VMs to be moved (powered on and assigned to the current host)
    $vmsToMove = Get-VM | Where-Object -FilterScript { $_.VMHost -eq $vmHostToUpdate -and $_.PowerState -eq "PoweredOn" } | Sort-Object -Property MemoryGB -Descending

    # Add a "modulo" property to each VM to determine the target host
    $vmsToMove | Add-Member -MemberType NoteProperty "modulo" -Value ""

    for ($i = 0; $i -lt $vmsToMove.Count; $i++) {
        # Assign a target host based on the modulo operation
        if ($i % $otherHosts.Count) {
            $vmsToMove[$i].modulo = ($i % $otherHosts.Count)
        }
    }

    for ($j = 0; $j -lt $otherHosts.Count; $j++) {
        # Move the VMs to their respective target hosts
        $vmsMoveNow = $vmsToMove | Where-Object -FilterScript { $_.modulo -eq $j }
        Move-VM -Destination $otherVMHost[$j] -VMotionPriority High -VM $vmsMoveNow
    }

    # Get the baselines for the host
    $baselines = Get-Baseline -Entity $vmHostToUpdate

    # Update the host with the baselines and other settings
    Update-Entity -Entity $vmHostToUpdate -Baseline $baselines -HostFailureAction Retry -HostNumberOfRetries 2 -HostDisableMediaDevices $true

    # Move the VMs back to the original host
    $vmsToMoveBack = $allVMsBeforeMigration | Where-Object -FilterScript { $_.VMHost -eq $vmHostToUpdate }
    Move-VM -Destination $vmHostToUpdate -VMotionPriority High -VM $vmsToMoveBack
}

# Disconnect from the vCenter server
Disconnect-VIServer $vCenter -Confirm:$false