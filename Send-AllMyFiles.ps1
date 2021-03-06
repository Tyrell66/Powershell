# Check to see we have all the arguments
if($args.Count -lt 1)
{
Write-Host "Use: Send-AllMyFiles.ps1 <Path>"
Write-Host
Write-Host " <Path>: Full path for the folder which contains the files"
Write-Host
exit
}
 
$FullPath=$args[0]
 
#Get an Outlook application object
$o = New-Object -com Outlook.Application
 
$files = Get-ChildItem $FullPath
$j = $files.Count 
for ($i=0; $i -lt $files.Count; $i++) {

$mail = $o.CreateItem(0)
 
#2 = High importance message
$mail.importance = 2
 
$mail.subject = "This is the subject of the mail "
$mail.body = "This is the body of the email. It has been automatically generated by a script."
 
#separate multiple recipients with a ";"
$mail.To = 'olivier.theizen@clearstream.com'
#$mail.CC = <OTHER RECIPIENT 1>;<OTHER RECIPIENT 2>
 
# Iterate over all files and only add the ones that have an .html extension
 
$outfileName = $files[$i].FullName
$outfileNameExtension = $files[$i].Extension
 
# if the extension is the one we want, add to attachments
#if($outfileNameExtension -eq ".html")
#{
$mail.subject += " $($i+1)/$j"
$mail.Attachments.Add($outfileName);
$mail.Send()
Start-Sleep 2
$mail = ''
}
 
#$mail.Send()
 
# give time to send the email

 
# quit Outlook
$o.Quit()
 
#end the script
exit