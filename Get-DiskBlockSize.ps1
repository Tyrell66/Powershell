$time = (Get-Date).Adddays(-(90))
$servers = (Get-ADComputer -Properties * -Filter {LastLogonTimeStamp -ge $time} -SearchBase "OU=Servers,DC=btmldom,DC=lux").name
foreach ($s in $servers) {Get-WmiObject -Class Win32_volume -Filter "FileSystem='NTFS'" -ComputerName $s -ErrorAction SilentlyContinue | Select-Object SystemName, Name, Label, BlockSize | Format-Table -AutoSize}
