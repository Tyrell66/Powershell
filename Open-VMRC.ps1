function Open-VMRC {
    <#
      .Synopsis
      Function to replicate Open-VMConsoleWindow but use the VMware Remote Console Application
      .Description
      Connect to the virtual machine using the currently connected server object.
      .Example
      Get-VM "MyVM" | Open-VMRC
      .Parameter VirtualMachine
      Virtual Machine object 
    #>
    #[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)][VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]$vm 
    )
    $ServiceInstance = Get-View -Id ServiceInstance
    $SessionManager = Get-View -Id $ServiceInstance.Content.SessionManager
    $vmrcURI = "vmrc://clone:" + ($SessionManager.AcquireCloneTicket()) + "@" + $global:DefaultVIServer.Name + "/?moid=" + $vm.ExtensionData.MoRef.Value
    Start-Process -FilePath $vmrcURI
}
