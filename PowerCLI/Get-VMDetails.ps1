get-vm VMName
Get-Vm VMName | Get-hardDisk | FL
Get-Vm VMName | Get-NetworkAdapter | FL
Get-Vm VMName | Select-Object -ExpandProperty Notes
