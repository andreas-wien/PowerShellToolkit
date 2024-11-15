<#
.SYNOPSIS
    Returns a list of installed updates
.DESCRIPTION
    Returns a list of installed updates
.EXAMPLE
    C:\PS> Get-InstalledUpdates.ps1
.NOTES
    Author: Andreas P.
    Date: November 15, 2024
#>
[CmdletBinding()]
$Session = New-Object -ComObject "Microsoft.Update.Session"
$Searcher = $Session.CreateUpdateSearcher()

$historyCount = $Searcher.GetTotalHistoryCount()

$updates = $Searcher.QueryHistory(0, $historyCount)

return $updates