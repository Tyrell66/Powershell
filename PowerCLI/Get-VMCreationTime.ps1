# source: https://www.virtualvmx.com/2017/12/vm-creation-date-time-from-powercli.html?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed:+Virtualvmx+(Virtualvmx)

function Get-VMCreationTime {
   $vms = get-vm
   $vmevts = @()
   $vmevt = new-object PSObject
   foreach ($vm in $vms) {
      #Progress bar:
      $foundString = "       Found: "+$vmevt.name+"   "+$vmevt.createdTime+"   "+$vmevt.IPAddress+"   "+$vmevt.createdBy
      $searchString = "Searching: "+$vm.name
      $percentComplete = $vmevts.count / $vms.count * 100
      write-progress -activity $foundString -status $searchString -percentcomplete $percentComplete

      $evt = get-vievent $vm | sort createdTime | select -first 1
      $vmevt = new-object PSObject
      $vmevt | add-member -type NoteProperty -Name createdTime -Value $evt.createdTime
      $vmevt | add-member -type NoteProperty -Name name -Value $vm.name
      $vmevt | add-member -type NoteProperty -Name IPAddress -Value $vm.Guest.IPAddress
      $vmevt | add-member -type NoteProperty -Name createdBy -Value $evt.UserName
      #uncomment the following lines to retrieve the datastore(s) that each VM is stored on
      #$datastore = get-datastore -VM $vm
      #$datastore = $vm.HardDisks[0].Filename | sed 's/\[\(.*\)\].*/\1/' #faster than get-datastore
      #$vmevt | add-member -type NoteProperty -Name Datastore -Value $datastore
      $vmevts += $vmevt
      #$vmevt #uncomment this to print out results line by line
   }
   $vmevts | sort createdTime
}
