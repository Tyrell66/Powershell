$vmname = "miblgdmm01prd"
$datastore = "nfs.clones"
$location = "VM_Clones"
import-module VMware.PowerCLI
Connect-VIServer -Server Dali3.prod.ci.dom -User OAAD\ke351admin
$vm = Get-VM -name $vmname
$ESXhost = $vm.VMHost.Name
pause

$vm | Shutdown-VMGuest -Confirm

Do { $vm1 = Get-VM -name $vmname } While ($vm1.PowerState -ne "PoweredOff")

New-VM -Name ('CLO_' + $vmname + '_20170507_OT') -VM $vmname -Datastore $datastore -Host $ESXhost -Location $location -Confirm -RunAsync

Set-VM -VM $vmname -Version v10 -RunAsync

$vm | Start-VM -RunAsync

$vm | Update-Tools -RunAsync