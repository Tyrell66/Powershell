Invoke-Command -ComputerName lupdwdc01, lupdwdc02 -ScriptBlock {
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4740
} | FL TimeCreated, Message
}

## Source: https://theposhwolf.com/howtos/Get-ADUserLockouts/
