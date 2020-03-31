$a = Get-Content .\AllOAADComputers.txt
$b = $a | % { $_.Trim() }
for ($i=0;$i -le $b.Count;$i+=4)  {
  @$c=(($b[$i],$b[$i+1],$b[$i+2]) -join ";")
  Add-Content -Path .\AllOAADComputers.csv $c
 } 