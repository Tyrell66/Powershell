function Get-FragmentationPercent
{
    param ($strReport, [bool] $bGetAnalysis=$true)
    begin
    {
        $bInAnalysis = $false
        $bInDefrag = $false
        foreach ($line in $strReport)
        {
            if ($line -match “Analysis Report”)
            {
                $bInDefrag = $false;
                $bInAnalysis = $true;
            }
            if ($line -match “Defragmentation Report”)
            {
                $bInAnalysis = $false;
                $bInDefrag = $true;
            }

            if ($line -match “(?<percentfragmented>\d+)%\sFragmented\s”)
            {
                if (($bInAnalysis -and $bGetAnalysis) -or ($bInDefrag -and !$bGetAnalysis))
                {
                    return $matches[“percentFragmented”]
                }
            }
        }
        return 0
    }
}

$dLimit = [double]$args[0]
foreach ($drive in Get-WMIObject Win32_LogicalDisk -filter "DriveType = 3")
{
    $strDriveLetter = $drive.DeviceID
    $strReport = defrag $strDriveLetter -a
    $dFragPercent = [double] (Get-FragmentationPercent $strReport)

    if ($dFragPercent -gt $dLimit)
    {
        echo “Drive $strDriveLetter defragmenting:”
        echo “    Before:  $dFragPercent% fragmented.”
        $strDefragReport = defrag $strDriveLetter
        $dNewFrag = Get-FragmentationPercent $strDefragReport $false
        echo “    After:  $dNewFrag% fragmented.”                   
    }
    else
    {   
        echo “Drive $strDriveLetter does not need defragmented ($dFragPercent% fragmented)”
    } 
}