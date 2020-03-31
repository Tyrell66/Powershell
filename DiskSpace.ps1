$outData = @("")
$server = $args[0]
$dataFromServer = Get-WmiObject Win32_Volume -ComputerName $server | Select-Object SystemName,Label,Name,DriveLetter,DriveType,Capacity,Freespace

foreach ($currline in $dataFromServer) {
    if ((-not $currline.name.StartsWith("\\")) -and ($currline.Drivetype -ne 5)) {
        [float]$tempfloat = ($currline.Freespace / 1000000) / ($currline.Capacity / 1000000)
        $temppercent = [math]::round(($tempfloat * 100),2)
        add-member -InputObject $currline -MemberType NoteProperty -name FreePercent -value "$temppercent %"
		[float]$tempfloat = ($currline.Capacity / 1Gb)
		$tempCapacityInGB = [math]::round($tempfloat, 3)
        add-member -InputObject $currline -MemberType NoteProperty -name CapacityInGB -value "$tempCapacityInGB"
        $outData = $outData + $currline
    }
}

$outData | Select-Object SystemName,Label,Name,CapacityInGB,FreePercent | sort-object -property FreePercent | format-table -autosize