[CmdletBinding()]
Param (
    [int32]$Count = 5,
    [Parameter(ValueFromPipeline=$true)]
    [string]$Computer = "10.238.249.126",
    [int32]$Port = 7500,
    [string]$LogPath = "D:\Admin\conlog.csv",
    [int32]$Sleep = 60
)

#$Connection = @()
#Test if path exists, if not, create it
If (-not (Test-Path (Split-Path $LogPath) -PathType Container))
{   Write-Verbose "Folder doesn't exist $(Split-Path $LogPath), creating..."
    New-Item (Split-Path $LogPath) -ItemType Directory | Out-Null
}

#Test if log file exists, if not seed it with a header row
If (-not (Test-Path $LogPath))
{   Write-Verbose "Log file doesn't exist: $($LogPath), creating..."
    Add-Content -Value '"TimeStamp","Source","Destination","IPV4Address","Port","Status"' -Path $LogPath
}

#Log collection loop
Write-Verbose "Beginning PortQry monitoring of $Computer for $Count tries:"
While ($Count -gt 0)
{   $Connection = Test-NetConnection -ComputerName $Computer -Port $Port | Select @{Label="TimeStamp";Expression={Get-Date}},@{Label="Source";Expression={ $_.SourceAddress }},@{Label="Destination";Expression={ $_.ComputerName }},RemoteAddress,RemotePort,TcpTestSucceeded
    Write-verbose ($Connection | Format-List * | Out-String)
    Write-verbose ($Connection | Select TimeStamp,Source,Destination,RemoteAddress,RemotePort,TcpTestSucceeded | Format-Table -AutoSize | Out-String)
    $Result = $Connection | Select TimeStamp,Source,Destination,RemoteAddress,RemotePort,TcpTestSucceeded | ConvertTo-Csv -NoTypeInformation
    $Result[1] | Add-Content -Path $LogPath
    $Count --
    Start-Sleep -Seconds $Sleep
}