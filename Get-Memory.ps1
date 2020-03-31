get-process | Where-Object {$_.ProcessName -match "firefox|iexpl|chrome|chromium|brave"} | Group-Object -Property ProcessName | Format-Table Name, @{n='Mem (KB)';e={'{0:N0}' -f (($_.Group|Measure-Object WorkingSet -Sum).Sum / 1KB)};a='right'} -AutoSize
configuration Name {
    # One can evaluate expressions to get the node list
    # E.g: $AllNodes.Where("Role -eq Web").NodeName
    node ("Node1","Node2","Node3")
    {
        # Call Resource Provider
        # E.g: WindowsFeature, File
        WindowsFeature FriendlyName
        {
            Ensure = "Present"
            Name = "Feature Name"
        }

        File FriendlyName
        {
            Ensure = "Present"
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
            Type = "Directory"
            DependsOn = "[WindowsFeature]FriendlyName"
        }
    }
}