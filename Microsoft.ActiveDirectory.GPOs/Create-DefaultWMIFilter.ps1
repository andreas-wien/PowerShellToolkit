<#
.SYNOPSIS
    Creates the most common wmi filters for GPOs in the current domain.
.DESCRIPTION
    Creates the most common wmi filters for GPOs in the current domain.
.EXAMPLE
    C:\PS> Create-DefaultWMIFilter.ps1
.NOTES
    Author: Andreas P.
    Date: August 4, 2024
#>

# Define wmi filters to be created
$WMIFiltersCSV = 'Name,Description,Namespace,Query
Windows Server 2022,Windows Server 2022,root\CIMv2,select * from Win32_OperatingSystem where Version like "10.0.20348%" and (ProductType="2" or ProductType="3")
Windows Server 2019,Windows Server 2019,root\CIMv2,select * from Win32_OperatingSystem where Version like "10.0.17763%" and (ProductType="2" or ProductType="3")
Windows Server 2016,Windows Server 2016,root\CIMv2,select * from Win32_OperatingSystem where Version like "10.0.14393%" and (ProductType="2" or ProductType="3")
Windows Server 2012 R2,Windows Server 2012 R2,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.3%" and (ProductType="2" or ProductType="3")
Windows Server 2012,Windows Server 2012,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.2%" and (ProductType="2" or ProductType="3")
Windows Server 2008 R2,Windows Server 2008 R2,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.1%" and (ProductType="2" or ProductType="3")
Windows Server 2008,Windows Server 2008,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.0%" and (ProductType="2" or ProductType="3")
Windows 11, Windows 11,root\CIMv2,select * from Win32_OperatingSystem where Version like "10.0.2%" and ProductType="1"
Windows 10, Windows 10,root\CIMv2,select * from Win32_OperatingSystem where Version like "10.0.1%" and ProductType="1"
Windows 8.1, Windows 8.1,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.3%" and ProductType="1"
Windows 8, Windows 8,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.2%" and ProductType="1"
Windows 7, Windows 7,root\CIMv2,select * from Win32_OperatingSystem where Version like "6.1%" and ProductType="1"
Domain Contollers,Domain Controllers,root\CIMv2,select * from Win32_OperatingSystem where ProductType="2"
Member Server,Member Server,root\CIMv2,select * from Win32_OperatingSystem where ProductType="3"
Workstations,Workstations,root\CIMv2,select * from Win32_OperatingSystem where ProductType="1"
'

# Get current domain
$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$DomainDistinguishedName = $Domain.GetDirectoryEntry() | Select-Object -ExpandProperty DistinguishedName

# Get current username
$msWMIAuthor = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Load defined wmi filters from csv into ps object
$WMIFilters = ConvertFrom-Csv $WMIFiltersCSV -Delimiter ','
# If there is no wmi filters defined, skip
if (($WMIFilters | Measure-Object).count -gt 0) {
  # Load all wmi filters from active directory
  $SearchRoot = [adsi]("LDAP://CN=SOM,CN=WMIPolicy,CN=System," + $DomainDistinguishedName)
  $search = new-object System.DirectoryServices.DirectorySearcher($SearchRoot)
  $search.filter = "(objectclass=msWMI-Som)"
  $results = $search.FindAll()
  $existingWmiFilters = ForEach ($result in $results) {
    $result.properties["mswmi-name"].item(0)
  }

  foreach ($WMIFilter in $WMIFilters) {
    # Generate new GUID to serve as ID for new WMI filter
    $msWMIID = [string]"{" + ([System.Guid]::NewGuid()) + "}"
    # Define the distinguished name of new WMI Filter
    $WMIDistinguishedName = "CN=" + $msWMIID + ",CN=SOM,CN=WMIPolicy,CN=System," + $DomainDistinguishedName

    # Get current datetime and transform into needed format for the 'when created' and 'when changed' attribute of the new WMI filter
    $now = (Get-Date).ToUniversalTime()
    $msWMICreationDate = ($now.Year).ToString("0000") + ($now.Month).ToString("00") + ($now.Day).ToString("00") + ($now.Hour).ToString("00") + ($now.Minute).ToString("00") + ($now.Second).ToString("00") + "." + ($now.Millisecond * 1000).ToString("000000") + "-000" 

    # Define name and description of new WMI filter
    $msWMIName = $WMIFilter.Name
    $msWMIParm1 = $WMIFilter.Description

    # Define the filter itself in the needed format for the system to be able to compute the WQL
    $msWMIParm2 = "1;3;" + $WMIFilter.Namespace.Length.ToString() + ";" + $WMIFilter.Query.Length.ToString() + ";WQL;" + $WMIFilter.Namespace + ";" + $WMIFilter.Query + ";"

    # If a WMI filter with that name already exists, skip
    if ($existingWmiFilters -notcontains $msWMIName) {
      # Get handle on the ad location where WMI filters are stored
      $SOMContainer = [adsi]("LDAP://CN=SOM,CN=WMIPolicy,CN=System," + $DomainDistinguishedName)
      # Create a new msWMI-Som object, which is the ad class used for wmi filters
      $NewWMIFilter = $SOMContainer.create('msWMI-Som', "CN=" + $msWMIID)
      # Add all the defined attributes to the WMI filter object
      $NewWMIFilter.put("msWMI-Name", $msWMIName)
      $NewWMIFilter.put("msWMI-Parm1", $msWMIParm1)
      $NewWMIFilter.put("msWMI-Parm2", $msWMIParm2)
      $NewWMIFilter.put("msWMI-Author", $msWMIAuthor)
      $NewWMIFilter.put("msWMI-ID", $msWMIID)
      $NewWMIFilter.put("instanceType", 4)
      $NewWMIFilter.put("showInAdvancedViewOnly", "TRUE")
      $NewWMIFilter.put("distinguishedname", $WMIdistinguishedname)
      $NewWMIFilter.put("msWMI-ChangeDate", $msWMICreationDate)
      $NewWMIFilter.put("msWMI-CreationDate", $msWMICreationDate)
      # Save all attributes in the newly created WMI filter object
      $NewWMIFilter.setinfo()
    }
  }
}