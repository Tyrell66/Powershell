Get-CimInstance -ComputerName BRUTUS1,BRUTUS2,BRUTUS3,... -ClassName win32_product | Select-Object PSComputerName, Name, InstallDate | Out-GridView
