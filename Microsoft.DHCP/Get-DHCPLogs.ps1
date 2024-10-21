$dhcplogs = Get-ChildItem "C:\Windows\System32\dhcp\DhcpSrvLog-???.log"

$dhcplogheader = Get-Content $dhcplogs[0] | Select-Object -skip 33 -First 1

$dhcplogcontent = foreach ($log in $dhcplogs) {
    (Get-Content $log | Select-Object -skip 34) -join "`n"
}
$dhcplogcsv = $dhcplogheader + "`n" + $dhcplogcontent
$dhcplog = ConvertFrom-csv $dhcplogcsv

return $dhcplog