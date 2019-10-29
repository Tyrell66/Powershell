Get-Vm | Get-Snapshot | Sort-Object Created | Select VM, Name, @{Name="Created";Expression={$_.Created.ToString("yyyy-MM-dd")}} 
