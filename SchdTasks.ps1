$cred_ci = Get-Credential -credential CI\ke351adm
$cred_oa = Get-Credential -credential OAAD\ke351admin
$oa = dsquery computer forestroot -d oa.pnrad.net -limit 0 -o rdn
$ci = dsquery computer forestroot -d ci.dom -limit 0 -o rdn
$oa_filtered = $oa | ?{$_ -notmatch 'PC'} | ?{$_ -notmatch 'TS'}| Sort-Object
$ci_filtered = $ci | ?{$_ -notmatch 'PC'} | Sort-Object

foreach ($computer in $ci_filtered) {
  $hostname = $computer.SubString(1, $computer.Length - 2)
  $p = ping -n 2 -w 100 $hostname
  foreach ($line in $p) {
    if ($line.Trim().Contains("Reply from ")) {
      $a = Get-WmiObject -class Win32_OperatingSystem -computerName $hostname -credential $cred_ci | Select-Object CSName,Caption,CSDVersion
	  $b = $a.CSName.trim() + ";" + $a.Caption.trim() +";"+ $a.CSDVersion.trim() 
	  $b
	  $b | Out-File C:\Temp\GetSP_All.csv -append
	  break
	}
  }
}
foreach ($computer in $oa) {
  $hostname = $computer.SubString(1, $computer.Length - 2)
  $p = ping -n 2 -w 100 $hostname
  foreach ($line in $p) {
    if ($line.Trim().Contains("Reply from ")) {
      $a = Get-WmiObject -class Win32_OperatingSystem -computerName $hostname -credential $cred_ci | Select-Object CSName,Caption,CSDVersion
	  $b = $a.CSName.trim() + ";" + $a.Caption.trim() +";"+ $a.CSDVersion.trim() 
	  $b
	  $b | Out-File C:\Temp\GetSP_All.csv -append
	  break
	}
  }
}
