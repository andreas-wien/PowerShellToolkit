<#
.SYNOPSIS
    Shuts down the windows subsystem for linux if no distro is currently running.
.DESCRIPTION
    Shuts down the windows subsystem for linux if no distro is currently running. Normally even if no distro is running WSL continues running and uses a lot of memory doing so. Running this script periodically will ensure memory is freed and if a distro is used WSL will start again. You may want to change how often this runs depending how often you use WSL.
.EXAMPLE
    C:\PS> Shutdown-WSLIfNoDistroRunning.ps1
.NOTES
    Author: Andreas P.
    Date: January 16, 2024
#>
[CmdletBinding()]
# Get the status of all distros
# '-replace [char]0' will ensure that the encoding is correct and the output can be filtered in the next statment
$WSLOutput = (Invoke-Expression -Command "wsl $('-l -v' -join ' ')") -replace [char]0
# Get all running distros, if none is found wsl will be shutdown
if (-not $($WSLOutput | findstr.exe "Running")) {
    wsl.exe --shutdown
}