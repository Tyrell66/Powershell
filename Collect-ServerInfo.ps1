<#
.SYNOPSIS
Collect-ServerInfo.ps1 - PowerShell script to collect information about Windows servers

.DESCRIPTION 
This PowerShell script runs a series of WMI and other queries to collect information
about Windows servers.

.OUTPUTS
Each server's results are output to HTML.

.PARAMETER -Verbose
See more detailed progress as the script is running.

.EXAMPLE
.\Collect-ServerInfo.ps1 SERVER1
Collect information about a single server.

.EXAMPLE
"SERVER1","SERVER2","SERVER3" | .\Collect-ServerInfo.ps1
Collect information about multiple servers.

.EXAMPLE
Get-ADComputer -Filter {OperatingSystem -Like "Windows Server*"} | %{.\Collect-ServerInfo.ps1 $_.DNSHostName}
Collects information about all servers in Active Directory.

Change Log:
V1.00, 20/04/2015 - First release
V1.01, 01/05/2015 - Updated with better error handling
V1.02, 27/09/2018 - Added Managed Services informations (Locally executed, Pagefile, Shadow Storages, Installed softwares, Microsoft Updates)
V1.03, 02/10/2018 - Added DNS and IPv4 only
#>

[CmdletBinding()]

Param (
    [parameter(ValueFromPipeline=$True)]
    [string[]]$ComputerName
)

Begin
{
    #Initialize
    Write-Verbose "Initializing"
}

Process
{
#---------------------------------------------------------------------
# Check if the script has been launched locally with no parameter
#---------------------------------------------------------------------

    $client = [System.Net.Dns]::GetHostByName((hostname)).HostName
    $client = $client.ToLower()

    If (!$ComputerName) { $ComputerName = $client }

#---------------------------------------------------------------------
# Process each ComputerName
#---------------------------------------------------------------------

    if (!($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent))
    {
        Write-Host "Processing $ComputerName"
    }

    Write-Verbose "=====> Processing $ComputerName <====="

    $htmlreport = @()
    $htmlbody = @()
    $htmlfile = "$($ComputerName).html"
    $spacer = "<br />"

#---------------------------------------------------------------------
# Do 10 pings and calculate the fastest response time
# Not using the response time in the report yet so it might be
# removed later.
#---------------------------------------------------------------------
    
    try
    {
        $bestping = (Test-Connection -ComputerName $ComputerName -Count 10 -ErrorAction STOP | Sort-Object ResponseTime)[0].ResponseTime
    }

    catch
    {
        Write-Warning $_.Exception.Message
        $bestping = "Unable to connect"
    }

    if ($bestping -eq "Unable to connect")
    {
        if (!($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent))
        {
            Write-Host "Unable to connect to $ComputerName"
        }
        "Unable to connect to $ComputerName"
    }
    else
    {

#---------------------------------------------------------------------
# Collect computer system information and convert to HTML fragment
#---------------------------------------------------------------------
    
        Write-Verbose "Collecting computer system information"

        $subhead = "<h3>Server Information</h3>"
        $htmlbody += $subhead
    
        try
        {
            $csinfo = Get-WmiObject Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object Name,Manufacturer,Model,
                            @{Name='Physical Processors';Expression={$_.NumberOfProcessors}},
                            @{Name='Logical Processors';Expression={$_.NumberOfLogicalProcessors}},
                            @{Name='Total Physical Memory (Gb)';Expression={
                                $tpm = $_.TotalPhysicalMemory/1GB;
                                "{0:F0}" -f $tpm
                            }},
                            DnsHostName,Domain
       
            $htmlbody += $csinfo | ConvertTo-Html -Fragment
            $htmlbody += $spacer
       
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect operating system information and convert to HTML fragment
#---------------------------------------------------------------------
    
        Write-Verbose "Collecting operating system information"

        $subhead = "<h3>Operating System</h3>"
        $htmlbody += $subhead
    
        try
        {
            $osinfo = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction STOP | 
                Select-Object @{Name='Operating System';Expression={$_.Caption}},
                            @{Name='Architecture';Expression={$_.OSArchitecture}},
                            Version,Organization,
                            @{Name='Install Date';Expression={
                                $installdate = [datetime]::ParseExact($_.InstallDate.SubString(0,8),"yyyyMMdd",$null);
                                $installdate.ToShortDateString()
                            }},
                            WindowsDirectory

            $htmlbody += $osinfo | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect physical memory information and convert to HTML fragment
#---------------------------------------------------------------------

        Write-Verbose "Collecting physical memory information"

        $subhead = "<h3>Installed Memory</h3>"
        $htmlbody += $subhead

        try
        {
            $memorybanks = @()
            $physicalmemoryinfo = @(Get-WmiObject Win32_PhysicalMemory -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object DeviceLocator,Manufacturer,Speed,Capacity)

            foreach ($bank in $physicalmemoryinfo)
            {
                $memObject = New-Object PSObject
                $memObject | Add-Member NoteProperty -Name "Device Locator" -Value $bank.DeviceLocator
                $memObject | Add-Member NoteProperty -Name "Manufacturer" -Value $bank.Manufacturer
                $memObject | Add-Member NoteProperty -Name "Speed" -Value $bank.Speed
                $memObject | Add-Member NoteProperty -Name "Capacity (GB)" -Value ("{0:F0}" -f $bank.Capacity/1GB)

                $memorybanks += $memObject
            }

            $htmlbody += $memorybanks | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect pagefile information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>PageFile</h3>"
        $htmlbody += $subhead

        Write-Verbose "Collecting pagefile information"

        try
        {
            $pagefileinfo = Get-WmiObject Win32_PageFileUsage -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object @{Name='Pagefile Name';Expression={$_.Name}},
                            @{Name='Allocated Size (Mb)';Expression={$_.AllocatedBaseSize}}

            $htmlbody += $pagefileinfo | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect BIOS information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>BIOS Information</h3>"
        $htmlbody += $subhead

        Write-Verbose "Collecting BIOS information"

        try
        {
            $biosinfo = Get-WmiObject Win32_Bios -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object Status,Version,Manufacturer,
                            @{Name='Release Date';Expression={
                                $releasedate = [datetime]::ParseExact($_.ReleaseDate.SubString(0,8),"yyyyMMdd",$null);
                                $releasedate.ToShortDateString()
                            }},
                            @{Name='Serial Number';Expression={$_.SerialNumber}}

            $htmlbody += $biosinfo | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect volume information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>Hard Disk</h3>"
        $htmlbody += $subhead

        Write-Verbose "Collecting hard disk information"

        try
        {
            $hddinfo = Get-WmiObject -query "select * from win32_logicaldisk where DriveType=3" -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object DeviceID,FileSystem,VolumeName,
                @{Expression={$_.Size /1Gb -as [int]};Label="Total Size (GB)"},
                @{Expression={$_.Freespace / 1Gb -as [int]};Label="Free Space (GB)"}

            $htmlbody += $hddinfo | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect Shadow Storage information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>Shadow Storage</h3>"
        $htmlbody += $subhead

        Write-Verbose "Collecting Shadow Storage information"

        try
        {
            $shadowStorageList = @();

            $volumeList = Get-WmiObject Win32_Volume -ComputerName $ComputerName -Property SystemName,DriveLetter,DeviceID,Capacity,FreeSpace -Filter "DriveType=3" -ErrorAction STOP | 
                        select @{n="DriveLetter";e={$_.DriveLetter.ToUpper()}},DeviceID,
                        @{n="CapacityGB";e={([math]::Round([int64]($_.Capacity)/1GB,2))}},
                        @{n="FreeSpaceGB";e={([math]::Round([int64]($_.FreeSpace)/1GB,2))}} | 
                        Sort DriveLetter;
            
            $shadowStorages = Get-WmiObject Win32_ShadowStorage -ComputerName $ComputerName -Property DiffVolume,MaxSpace,UsedSpace,Volume -ErrorAction STOP |
                            Select @{n="Volume";e={$_.Volume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
                            @{n="DiffVolume";e={$_.DiffVolume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
                            @{n="MaxSpaceGB";e={([math]::Round([int64]($_.MaxSpace)/1MB,2))}},
                            @{n="UsedSpaceGB";e={([math]::Round([int64]($_.UsedSpace)/1MB,2))}}
            
            # Create an array of Customer PSobject
            foreach($shStorage in $shadowStorages) {
                $tmpDriveLetter = "";
                foreach($volume in $volumeList) {
                    if($shStorage.DiffVolume -eq $volume.DeviceID) {
                        $tmpDriveLetter = $volume.DriveLetter;
                    }
                }
                $objVolume = New-Object PSObject -Property @{
                    "Used Space (MB)" = $shStorage.UsedSpaceGB
                    "Max Space (MB)" = $shStorage.MaxSpaceGB
                    "Drive" = $tmpDriveLetter
                }
                $shadowStorageList += $objVolume;
            }
            
            for($i = 0; $i -lt $shadowStorageList.Count; $i++){
                $objCopyList = Get-WmiObject Win32_ShadowCopy -ComputerName $ComputerName  -ErrorAction STOP | Where-Object {$_.VolumeName -eq $shadowStorageList[$i].Volume} | 
                select DeviceObject, InstallDate
            }

            $htmlbody += $shadowStorageList | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect Removable devices information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>Removable devices</h3>"
        $htmlbody += $subhead

        Write-Verbose "Collecting Removable devices information"

        try
        {
            $remdevinfo = Get-WmiObject -query "select * from win32_logicaldisk where DriveType<>3" -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object DeviceID,FileSystem,VolumeName,
                @{Expression={$_.Size /1Gb -as [int]};Label="Total Size (GB)"},
                @{Expression={$_.Freespace / 1Gb -as [int]};Label="Free Space (GB)"}

            $htmlbody += $remdevinfo | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect network interface information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>Network Interface(s)</h3>"
        $htmlbody += $subhead

        Write-Verbose "Collecting network interface information"

        try
        {
            $nics = @()
            $nicinfo = @(Get-WmiObject Win32_NetworkAdapter -ComputerName $ComputerName -ErrorAction STOP | Where-Object {$_.PhysicalAdapter} |
                Select-Object Name, AdapterType, MACAddress,
                @{Name='ConnectionName';Expression={$_.NetConnectionID}},
                @{Name='Enabled';Expression={$_.NetEnabled}},
                @{Name='Speed';Expression={$_.Speed/1000000}})

            $nwinfo = @(Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -ErrorAction STOP |
                Select-Object Description, DHCPServer,
                @{Name='IpAddress';Expression={$_.IpAddress -like "*.*"}[0]},
                @{Name='IpSubnet';Expression={$_.IpSubnet -join ' ; '}},
                @{Name='DefaultIPgateway';Expression={$_.DefaultIPgateway -join ' ; '}},
                @{Name='DnsServerSearchOrder';Expression={$_.DnsServerSearchOrder -join ' ; '}})

            foreach ($nic in $nicinfo)
            {
                $nicObject = New-Object PSObject
                $nicObject | Add-Member NoteProperty -Name 'Enabled' -Value $nic.Enabled
                $nicObject | Add-Member NoteProperty -Name 'Adapter Name' -Value $nic.Name
                $nicObject | Add-Member NoteProperty -Name 'MAC' -Value $nic.MACAddress
                $nicObject | Add-Member NoteProperty -Name 'Speed (Mbps)' -Value $nic.Speed
                $nicObject | Add-Member NoteProperty -Name 'Connection Name' -Value $nic.connectionname

                $FixedIP = ($nwinfo | Where-Object {$_.Description -eq $nic.Name}).IpAddress
                $nicObject | Add-Member NoteProperty -Name 'IP Address' -Value $FixedIP

                $Gateway = ($nwinfo | Where-Object {$_.Description -eq $nic.Name}).DefaultIPgateway
                If (!$Gateway) {$Gateway = 'No Gateway set'}
                $nicObject | Add-Member NoteProperty -Name 'Gateway' -Value $Gateway

                $DNSServers = ($nwinfo | Where-Object {$_.Description -eq $nic.Name}).DNSServerSearchOrder
                If (!$DNSServers) {$DNSServers = 'No DNS set'}
                $nicObject | Add-Member NoteProperty -Name 'DNS Servers' -Value $DNSServers
    
                $DHCPStatus = ($nwinfo | Where-Object {$_.Description -eq $nic.Name}).DHCPServer
                If (!$DHCPStatus) {$DHCPStatus = 'DHCP Disabled'}
                $nicObject | Add-Member NoteProperty -Name 'DHCP Server' -Value $DHCPStatus

                $nics += $nicObject
            }

            $htmlbody += $nics | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect software information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>Installed softwares</h3>"
        $htmlbody += $subhead
 
        Write-Verbose "Collecting software information"
        
        try
        {
            $InstalledProducts = Invoke-Command -ComputerName $computername -ScriptBlock {
                Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            }

            $InstalledProducts = $InstalledProducts | Select-Object DisplayName,Publisher,DisplayVersion | Where-Object { $_.DisplayName -ne $null } | Sort-Object DisplayName -Unique

            $htmlbody += $InstalledProducts | ConvertTo-Html -Fragment
            $htmlbody += $spacer
        
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Collect Installed udpates information and convert to HTML fragment
#---------------------------------------------------------------------

        $subhead = "<h3>Installed updates</h3>"
        $htmlbody += $subhead
 
        Write-Verbose "Collecting Installed updates information"
        
        try
        {
            $remoteupdates = Invoke-Command -ComputerName $computername -ScriptBlock {
                $Session = New-Object -ComObject Microsoft.Update.Session 
                $Searcher = $Session.CreateUpdateSearcher()
                $HistoryCount = $Searcher.GetTotalHistoryCount()
                $Searcher.QueryHistory(0,$HistoryCount) | ForEach-Object {$_}  
            }

            # For sorting Title in ascending order and Date in descending order, please uncomment the following 2 lines:
            # $remoteupdates = $remoteupdates | Select-Object Title,Date | Sort-Object Title,
            # @{ Expression="Date";Descending=$true }

            $remoteupdates = $remoteupdates | Where-Object {(![String]::IsNullOrWhiteSpace($_.title)) -and ($_.ResultCode -eq '2') -and ($_.Title -notlike "*Windows Defender*") -and ($_.Title -notlike "*Malicious*")} | Select-Object Title,Date | Sort-Object Date -Descending -Unique

            $htmlbody += $remoteupdates | ConvertTo-Html -Fragment
            $htmlbody += $spacer 
        }

        catch
        {
            Write-Warning $_.Exception.Message
            $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
            $htmlbody += $spacer
        }

#---------------------------------------------------------------------
# Generate the HTML report and output to file
#---------------------------------------------------------------------
	
        Write-Verbose "Producing HTML report"
    
        $reportime = Get-Date

        #Common HTML head and styles
	    $htmlhead="<html>
				    <style>
				    BODY{font-family: Arial; font-size: 8pt;}
				    H1{font-size: 20px;}
				    H2{font-size: 18px;}
                    H3{font-size: 16px;}
                    H4{font-size: 10px;}
				    TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
				    TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
				    TD{border: 1px solid black; padding: 5px; }
				    td.pass{background: #7FFF00;}
				    td.warn{background: #FFE600;}
				    td.fail{background: #FF0000; color: #ffffff;}
				    td.info{background: #85D4FF;}
				    </style>
                    <body>
                    <h1 align=""center"">Server: $ComputerName</h1>
				    <h3 align=""center"">Installation report generated on: $reportime</h3>"

        $htmltail = "</body>
                    <h4 align=""left"">Managed Services, Clearstream Services<br>Deutsche-Boerse Group<br><br>v1.03</h4>
			        </html>"

        $htmlreport = $htmlhead + $htmlbody + $htmltail

        $htmlreport | Out-File $htmlfile -Encoding Utf8
    }
}

End
{
    #Wrap it up
    Write-Verbose "=====> Finished <====="
}
