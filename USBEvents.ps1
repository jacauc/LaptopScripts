
$ErrorActionPreference = "SilentlyContinue" 
Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
#write-host (get-date -format s) " Beginning script…"
[system.diagnostics.eventlog]::CreateEventSource("FGPPCN","Application")
do{
    $newEvent = Wait-Event -SourceIdentifier volumeChange
    $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
    $eventTypeName = switch($eventType) {
        1 {"Configuration changed"}
        2 {"Device arrival"}
        3 {"Device removal"}
        4 {"docking"}
    }
    #write-host (get-date -format s) " Event detected = " $eventTypeName
    if ($eventType -eq 2) {
            $usbdrives = Get-Disk |where BusType -eq USB

            $usbvols = $usbdrives |Get-Partition |Get-Volume
            $myDrives = [System.Text.StringBuilder]::new()
            foreach ($i in $usbvols) {
                [void]$myDrives.Append("`n")
                [void]$myDrives.Append($i.DriveLetter)
                [void]$myDrives.Append(": ")
                [void]$myDrives.Append($i.FileSystemLabel)
            }
            [void]$myDrives.Append("`n")

            [void]$myDrives.Append(($usbdrives | Format-List | Out-String))
            Write-EventLog -LogName "Application" -Source "FGPPCN" -EventID 1000 -EntryType Information -Message "USB Drive Connected $mydrives" -Category 1 -RawData 10,20
            
    }
    if ($eventType -eq 3) {
            $usbdrives = Get-Disk |where BusType -eq USB

            $usbvols = $usbdrives |Get-Partition |Get-Volume
            $myDrives = [System.Text.StringBuilder]::new()
            [void]$myDrives.Append("`nThe following drives remain connected:")
            foreach ($i in $usbvols) {
                [void]$myDrives.Append("`n")
                [void]$myDrives.Append($i.DriveLetter)
                [void]$myDrives.Append(": ")
                [void]$myDrives.Append($i.FileSystemLabel)
            }
            [void]$myDrives.Append("`n")

            [void]$myDrives.Append(($usbdrives | Format-List | Out-String))
            Write-EventLog -LogName "Application" -Source "FGPPCN" -EventID 999 -EntryType Information -Message "USB Drive Removed $mydrives" -Category 1 -RawData 10,20
    }
    Remove-Event -SourceIdentifier volumeChange
} while (1-eq 1) #Loop until next event

Unregister-Event -SourceIdentifier volumeChange
