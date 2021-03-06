Add-PSSnapin vmware.vimautomation.core
#Connect to VCenter
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction 'SilentlyContinue' 
Connect-VIServer dali.prod.ci.dom -ErrorAction 'SilentlyContinue'
#Clear-Host 
#-------------------------------------------------------------------------------------------------------
#Begin Functions 
#-------------------------------------------------------------------------------------------------------
#Import-Module ActiveDirectory
#-------------------------------------------------------------------------------------------------------
# Check TCP Port 
# $Port = TCP port to check 
# $Device = Server or Workstation to check Port 
#-------------------------------------------------------------------------------------------------------
function Check-TCPPort 
{
	param([int]$Port,[string]$ComputerName) 
	
	try{$socket = New-Object Net.Sockets.TcpClient($ComputerName, $Port)
           if($socket -eq $null){$False} 
		   else {$True 
		   $socket.close()
                }
       }
        catch {$false}
}
#-------------------------------------------------------------------------------------------------------
# EndFunctions 
#-------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------
# Variables & Import Credentials 
#-------------------------------------------------------------------------------------------------------
$Inventory = @()
#-------------------------------------------------------------------------------------------------------
# Import Server's 
#-------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------
#Select Cluster
#-------------------------------------------------------------------------------------------------------
$ClusterName = Read-Host "Entername of Cluster "
#-------------------------------------------------------------------------------------------------------
#Select Name of Search
#-------------------------------------------------------------------------------------------------------
$VMselect = Read-Host "Enter Name of Virtual Machine or * for all Vm's"
$Servers = get-vm $VMselect -location $ClusterName
$ErrorActionPreference = "Continue"
$namespace = "root\CIMV2"
#-------------------------------------------------------------------------------------------------------
#Setting working Directory --> 
#-------------------------------------------------------------------------------------------------------
$WorkDir = "N:\"
#-------------------------------------------------------------------------------------------------------
#clean Export Directory 
#-------------------------------------------------------------------------------------------------------
Remove-Item "$WorkDir\EXPORT\*.txt"
#-------------------------------------------------------------------------------------------------------
#Check server in the list
foreach ($Server in $Servers) {
Write-Host -ForegroundColor Magenta "SERVERNAME : $server"
$Item = New-Object PSObject
$Item | Add-Member -MemberType NoteProperty -Name ServerName -Value $server
#-------------------------------------------------------------------------------------------------------
#test ping if machine is available on network
#-------------------------------------------------------------------------------------------------------
if (Test-Connection -ComputerName $Server -Count 1 -Quiet) 
     {write-host -ForegroundColor Green "The Server $Server is : UP"
	 $Item | Add-Member -MemberType NoteProperty -Name PingStatus -Value $True}  
else {Write-Host -ForegroundColor Red "The Server $Server is : DOWN"
     $Item | Add-Member -MemberType NoteProperty -Name PingStatus -Value $False}
#-------------------------------------------------------------------------------------------------------	 
#check RDP Connection 
#-------------------------------------------------------------------------------------------------------
if (Check-TCPPort -ComputerName $Server -Port 3389) {
		   write-Host -fore Green  "RDP Port enabled on $Server" 
		   $Item | Add-Member -MemberType NoteProperty -Name RDP -Value $True} 
	else {write-host -fore Red "RDP Port not enabled on $Server"
		 $Item | Add-Member -MemberType NoteProperty -Name RDP -Value $False}
	
#-------------------------------------------------------------------------------------------------------
# Start of Indentifying Location
#-------------------------------------------------------------------------------------------------------
    $Disks = Get-HardDisk -vm $Server
    $Datastores = ""
    $DatastoresLoc = ""
        foreach ($Disk in $Disks)
        {
        $Datastore = $Disk.FileName.SubString($Disk.FileName.IndexOf("[")+1,$Disk.FileName.IndexOf("]")-1)
        $DatastoreID = $Datastore.SubString($Datastore.LastIndexOf(".")+1)

if ($Datastores -eq "") {$Datastores = $Datastore}
        elseif ($Datastores.IndexOf($Datastore) -eq -1) {$Datastores += " " + $Datastore}
        if ($DatastoreID -lt 100 -or $DatastoreID -match "KD")
            {
            if ($DatastoresLoc -eq "") {$DatastoresLoc = "KD"}
            elseif ($DatastoresLoc -eq "BC") {$DatastoresLoc = "KD+BC"}
            }
        else
            {
            if ($DatastoresLoc -eq "") {$DatastoresLoc = "BC"}
            elseif ($DatastoresLoc -eq "KD") {$DatastoresLoc = "KD+BC"}
            }
  if ($Datastore -match "local") {$DatastoresLoc = "local"}
    }
#-------------------------------------------------------------------------------------------------------
# END of Indentifying Location
#-------------------------------------------------------------------------------------------------------
Write-Host $Server is $ServernNOTFQDN.PowerState 
#output Host of Virtual Machine 
$ESXHOST = $Server.VMHost
Write-Host "ESXI HOST (FQDN) : $ESXHOST"
#convert FQDN ESXHOSTNAME to NOFQDN ESXHOSTNAME
[string]$ESXHOSTNOFQDN = $ESXHOST
$ESXHOSTNOFQDN = $ESXHOSTNOFQDN.split(".")[0].Trim()
Write-Host "ESXI HOST (NOFQDN) : $ESXHOSTNOFQDN"
#-------------------------------------------------------------------------------------------------------
#Puts servername in corresponding TXT File 
#-------------------------------------------------------------------------------------------------------
add-Content "$WorkDir\EXPORT\$ESXHOSTNOFQDN.txt" $server
write-Host "---------------------------------------------"
$Item | Add-Member -MemberType NoteProperty -Name ESXStatus -Value $Server.PowerState
$Item | Add-Member -MemberType NoteProperty -Name VMTools -Value $Server.ExtensionData.Guest.ToolsStatus
$Item | Add-Member -MemberType NoteProperty -Name HostFQDN -Value $Server.VmHost
$Item | Add-Member -MemberType NoteProperty -Name HostNOFQDN -Value $ESXHOSTNOFQDN
$Item | Add-Member -MemberType NoteProperty -Name DataCenter -Value $DatastoresLoc
$Inventory += $item
}
$Inventory  | out-gridview -Title "Inventory of Servers with checks" 
#-------------------------------------------------------------------------------------------------------
#Output as HTML 
#-------------------------------------------------------------------------------------------------------
$Inventory | ConvertTo-HTML -Body "<H2>Result of Script</H2>" | Out-File "$WorkDir\List.html"