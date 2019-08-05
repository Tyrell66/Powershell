# Here’s how:
# On a Prod Support Metaframe, start PowerShell.
# If PowerCLI is not installed, see below how to install it.
# If you want to keep track of the actions you did: 
    Start-Transcript N:\[whatever folder]\PowerShell-Transcript-[date].txt


# Use the following commands:
# Connecting to the vCenter: 
    Connect-VIServer -Server dali3.prod.ci.dom
    a pop-up will wait for your credentials if needed.
# Add the VMTools infos (just once):
    New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force
    New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force
# Define the target VM: 
    $vmname = “my VM little name”
# Get the VM object: 
    $vm = Get-VM -name $vmname
# Get the current VM infos (before the update): 
    Get-VM -name $vmname | Select Name,Version,Tools*
# Shutdown the VM: 
    $vm | Shutdown-VMGuest -Confirm
# Wait until the VM is actually down:
    Do { $vm1 = Get-VM -name $vmname } While ($vm1.PowerState -ne "PoweredOff")
# Create a clone based on my target VM: 
    # Old version: New-VM -Name ('CLO_' + $vmname + '_20170507_OT') -VM $vmname -Datastore "nfs.clones" -Host $vm.VMHost.Name -Location "VM_Clones" -Confirm -RunAsync
    New-Snapshot -VM $vm -Name "$($vmname)_$((get-date).ToString('yyyyMMdd'))_AUTODEL9D_OT" -Description "$($vmname)_$((get-date).ToString('yyyyMMdd'))_AUTODEL9D_OT" -RunAsync
# Upgrade VM Hardware: 
    Set-VM -VM $vmname -Version v13 -RunAsync
# (Re-)start my VM: 
    $vm | Start-VM -RunAsync
# Update the VMTools (automatically): 
    $vm | Update-Tools -RunAsync
# Mount the VMTools iso (manual install): 
    $vm | Mount-Tools
# Dismount the VMTools iso: 
    $vm | Dismount-Tools

# Don’t forget to dismount at the end, otherwise you’ll have Thierry on your back Monday morning.
# Get the current VM infos (before the update): 
    Get-VM -name $vmname | Select Name,Version,Tools*


# I still use vSphere to track the status/progress of my clones.
