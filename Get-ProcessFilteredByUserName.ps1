Get-Process -IncludeUserName | Where-Object {$_.UserName -eq "KRYPTON\Elizabeth" } | Format-Table Id, Name, mainWindowTitle,UserName -AutoSize
