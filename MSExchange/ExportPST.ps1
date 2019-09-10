<#
Export all mailboxes one after another.
First Phase
#>

#$List = Get-Mailbox -ResultSize Unlimited | Where {$_.Database -like "CustomerDB*"}
$List = 'an0050', 'an0051'
#$listArchive = 'ab123', 'cd456'
#$from = Get-Date -Year '2018' -Month '04' -Day '14' -Hour '00' -Minute '00' -Second '00'
#$upto = Get-Date -Year '2018' -Month '07' -Day '31' -Hour '23' -Minute '59' -Second '59'
$i = 1

$csv = "C:\Admin\1stPhase-4.csv"

Foreach ($item in $list)
{
    Write-Host (Get-Date)
    Write-Host "Processing $item ($i of $($List.Length))"
    $strFileName = "\\anoexc02\PSTEXPORT$\$($item).pst"
    Write-Host "Checking if $strFileName exists, and if it does, deleting it"
    If (Test-Path $strFileName)
    {
        Remove-Item $strFileName
    }
    # $req = New-MailboxExportRequest -Mailbox $item -ContentFilter "((Received -ge '$from') -and (Received -le '$upto'))" -AcceptLargeDataLoss -ExcludeDumpster -BadItemLimit 200000 -BatchName "$($item)-3rdPhase-v1" -FilePath "$strFileName"
    $req = New-MailboxExportRequest -Mailbox $item -AcceptLargeDataLoss -ExcludeDumpster -BadItemLimit 200000 -BatchName "$($item)-3rdPhase-v1" -FilePath "$strFileName"
    Write-Host "Request for $item submitted: $($req.Name)"
    Write-Host "Export to $($req.FilePath)"
    $TotalSize = (Get-MailboxStatistics -Identity $item).TotalItemSize.Value
    Write-Host $TotalSize
    
    $resume = 1
    Do {
        Write-Host "Resume #$($resume)"
        $req | Resume-MailboxExportRequest
        Start-Sleep -Seconds 10
        $Status = (Get-MailboxExportRequestStatistics -Identity $req.RequestGuid).Status
        $resume++
    }
    While ($Status -eq 'Queued')
    Write-Host "Request now InProgress..."

    Do { 
        $Percent = (Get-MailboxExportRequestStatistics -Identity $req.RequestGuid).PercentComplete
        $Status = (Get-MailboxExportRequestStatistics -Identity $req.RequestGuid).Status
        Write-Progress "Export of $item is in progress." -Status "Export $Percent% complete" -PercentComplete "$Percent"
        Start-Sleep -Seconds 10
       }
    While (($Percent -ne 100) -and ($Status -eq 'InProgress'))
    
    $logfile = "C:\Admin\$($item)-3rdPhase-v1.log"
    Start-Sleep -Seconds 10
    Write-Host "Saving Export Request to $logfile"
    $r = Get-MailboxExportRequestStatistics -Identity $req.RequestGuid -IncludeReport
    $r | Format-List | Out-File $logfile
    Add-Content -Path $csv -Value "$($r.SourceMailboxIdentity),$($r.FilePath),$($r.Name),$($r.BatchName),$($r.ContentFilter),$($r.SourceDatabase),$($r.Status),$($r.QueuedTimestamp),$($r.CompletionTimestamp),$($r.OverallDuration),$($r.EstimatedTransferSize),$($r.BytesTransferred),$TotalSize"
    $i++
    Write-Host "+++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++"
}

<#  No Archive in this environment +++++++++++++

$csv = "C:\Admin\2ndPhase-Archive-v4.csv"

Foreach ($item in $listArchive)
{
    # $item = $item.Alias
    Write-Host (Get-Date)
    Write-Host "Processing $item ($i of $($ListArchive.Length))"    
    $strFileName = "\\saltmbxa01\PST$\Customer\UpTo20180731\$($item)_Archive.pst"
    Write-Host "Checking if $strFileName exists, and if it does, deleting it"
    If (Test-Path $strFileName)
    {
        Remove-Item $strFileName
    }
    $req = New-MailboxExportRequest -BatchName "$($item)-2ndPhase-Archive-v4" -IsArchive -ContentFilter "((Received -ge '$from') -and (Received -le '$upto'))" -Mailbox $item -AcceptLargeDataLoss -ExcludeDumpster -BadItemLimit 200000 -FilePath "$strFileName"
    Write-Host "Request for $item submitted: $($req.Name)"
    Write-Host "Export to $($req.FilePath)"
    $TotalSize = (Get-MailboxStatistics -Archive -Identity $item).TotalItemSize.Value
    Write-Host $TotalSize
    
    $resume = 1
    Do {
        Write-Host "Resume #$($resume)"
        $req | Resume-MailboxExportRequest
        Start-Sleep -Seconds 10
        $Status = (Get-MailboxExportRequestStatistics -Identity $req.RequestGuid).Status
        $resume++
    }
    While ($Status -eq 'Queued')
    Write-Host "Request now InProgress..."

    Do { 
        $Percent = (Get-MailboxExportRequestStatistics -Identity $req.RequestGuid).PercentComplete
        $Status = (Get-MailboxExportRequestStatistics -Identity $req.RequestGuid).Status
        Write-Progress "Export of $item (Archive) is in progress." -Status "Export $Percent% complete" -PercentComplete "$Percent"
        Start-Sleep -Seconds 10
       }
    While (($Percent -ne 100) -and ($Status -eq 'InProgress'))
    
    $logfile = "C:\Admin\$($item)-2ndPhase-Archive-v4.log"
    Start-Sleep -Seconds 10
    Write-Host "Saving Export Request to $logfile"
    $r = Get-MailboxExportRequestStatistics -Identity $req.RequestGuid -IncludeReport
    $r | Format-List | Out-File $logfile
    Add-Content -Path $csv -Value "$($r.SourceMailboxIdentity),$($r.FilePath),$($r.Name),$($r.BatchName),$($r.ContentFilter),$($r.SourceDatabase),$($r.Status),$($r.QueuedTimestamp),$($r.CompletionTimestamp),$($r.OverallDuration),$($r.EstimatedTransferSize),$($r.BytesTransferred),$TotalSize"
    $i++
    Write-Host "+++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++ +++"
}

#>
