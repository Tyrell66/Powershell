$obj = @();$obj2 = @(); $obj3 = @();$obj4 = @()

foreach ($vmname in $vmsname)
{
$vm = Get-VM -name $vmname

if ((Get-Snapshot $vm).name -like "SNP*") {

$obj = New-Object PSObject
$obj | Add-Member NoteProperty Vmname $vmname
$obj | Add-Member NoteProperty Snapname (Get-Snapshot $vm).name 
$obj | Add-Member NoteProperty Description (Get-Snapshot $vm).description
$obj2+=$obj
$obj2 | export-csv -append  $path\vm_snp.txt
}  
