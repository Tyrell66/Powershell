$ou = [ADSI]"LDAP://OU=Computers,DC=Bat,DC=ci,DC=dom"
foreach ($child in $ou.psbase.Children) {
	if ($child.ObjectCategory -like '*computer*') {
		Write-Host $child.Name
	}
}