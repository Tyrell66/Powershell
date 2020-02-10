get-vm clrapp05 | Shutdown-VMGuest
Get-VM clrapp05 | Get-NetworkAdapter | Set-NetworkAdapter -StartConnected $false
