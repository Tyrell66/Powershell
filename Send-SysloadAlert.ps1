<#
.Synopsis
   Sends an alert using sysload's sldalert.exe
.DESCRIPTION
   Sends an alert to the Sysload Console if the agent is correctly installed & licemsed in thedefault directory
.EXAMPLE
   Send-SysloadAlert -AlertName "XXX_Reboot" -Priority 34 -Message "Server was rebooted around $(Get-Date)"
.EXAMPLE
   Send-SysloadAlert -AlertName "XXX_SOS" -Priority 66 -Message "Titanic is starting to sink" -State "begin"
.NOTES
  Author: Dimitri
  Version: 1.0
  Date: 10-Apr-2018

#>
function Send-SysloadAlert
{
    [CmdletBinding()]
    [OutputType([boolean])]
    Param
    (
        # AlertName is the name of the alert limited to 12 chars
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateLength(1,12)]
        [string]$AlertName,
        # Message is the text of the alert (50 characters)
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                  Position=1)]
        [ValidateLength(1,50)]
        [string]
        $Message,
        # Priority is the priority of the alert *this is internally normalized*
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [ValidateRange(1,100)]
        [int]
        $Priority,
        # State is the state of the alert: Begin, End or PONCtual
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [ValidateSet("begin","end","ponct")]                
        [string]$State = "ponct"
        
    )

    $sysloadDir = Join-Path $env:ProgramFiles "sysload"
    $sysloadCollectorDir = Join-Path $sysloadDir "sldrmd"
    $sldalert = Join-Path $sysloadCollectorDir "sldalert.exe"

    $output = & $sldalert -t $AlertName -m $Message -p $Priority -s $State
    if ($?) {
    # command executed, does the output contain some error message?
            if (Select-String -inputobject $output -pattern 'err=' -Quiet ) {
                    return $false
                }
            else {
            return $true
            }
    # unable to launch sldalert.exe, etc.
       else {
         return $false
       }
       }

}
