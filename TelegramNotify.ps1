
$ErrorActionPreference = "SilentlyContinue" 
$notificationType = $args[0];

# AUCJ - 09 Oct 2018 
# Notify Telegram Group on certain events in Windows Event Log - as a scheduled task
# IMPORTANT! Please add your own Telegram Bot chat ID to the following variables.

#Valid Command Line Arguments:
#  1. DefUpdated
#  2. VirusFound
#  3. ScanFinished
#  4. USBConnected
#  5. USBRemoved






 
# Set up Telegram Bot
$tokenID = "123456789:ABC-DEFghIJkLMNOPqrstUvWxYZ"
$chatID = "-098765432" 
$virusChatID = "-987654321"
# Note: group ID's typically start with a minus sign



########## Set up some globals #######################

#reset the description fields
$desc1 = ""
$desc2 = ""
$desc3 = ""
$desc4 = ""
$desc5 = ""

# obtain computer IP address
$ip = (Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address).IPAddressToString


# obtain serial number
$serial = ((gwmi win32_bios).SerialNumber)

# obtain computername
$compname = $Env:COMPUTERNAME

# obtain username - This is removed because the task will always return the username context it is running under
#$username = $env:USERNAME


#obtain connected SSID
$ssid = (Get-NetConnectionProfile).Name

# Obtain cybercheck information
$LastCyberCheck = [datetime](Get-ItemProperty "HKLM:\Software\TCO").LastCyberCheck
$TodayDate = [datetime]::Today
$TimeSinceLastCyberCheck = ($TodayDate - $LastCyberCheck).Days
$LastCyberCheckCAI = (Get-ItemProperty "HKLM:\Software\TCO").LastCheckCAI


# obtain PCN image version
$KioskVersion = [String](Get-ItemProperty "HKLM:\Software\TCO").KioskVersion


# find all USB drives and letters
$usbvols = Get-Disk |where BusType -eq USB |Get-Partition |Get-Volume
$myDrives = [System.Text.StringBuilder]::new()
foreach ($i in $usbvols) {
    [void]$myDrives.Append("%0A             ")
    [void]$myDrives.Append($i.DriveLetter)
    [void]$myDrives.Append(": ")
    [void]$myDrives.Append($i.FileSystemLabel)
   # [void]$myDrives.Append("%0A")
}

#find current definition date
$defdate = (Get-WinEvent -FilterHashtable @{LogName='Application';ID=7} -MaxEvents 1).Message.Trim()
$defdate = $defdate.Split(":")[1].split(".")[0].trim()
$defdate = $defdate.substring(0,6)
$defdate = [datetime]::ParseExact($defdate, "yyMMdd", $null)
$defdate = $defdate.ToString("dd-MMM-yyyy")
       
######################################################





##### Construct message details based on event type ######
switch ( $notificationType )
{
    "DefUpdated" {
        $desc1 = "*AV definition Updated*"
        $desc2 = (Get-WinEvent -FilterHashtable @{LogName='Application';ID=7} -MaxEvents 1).Message.Trim()
    }

    "VirusFound" {
        $desc1 = "*! ! ! ! ! ! ! ! ! ! VIRUS FOUND ! ! ! ! ! ! ! ! ! !*"
        $desc2 = (Get-WinEvent -FilterHashtable @{LogName='Application';ID=51} -MaxEvents 1).Message.Trim()
        
        #make a nice long message to get the attention
        #For ($x =1;$x -lt 300; $x++) {
        #    $desc3 = $desc3 + "!-"
        #}

        #send notification of virus to different group to ensure attention.
        $chatID = $virusChatID
    }
 
    "ScanFinished" {
         #Get scan start time
        $scanStart= (Get-WinEvent -FilterHashtable @{LogName='Application';ID=3} -MaxEvents 1).TimeCreated
        #get scan finish time
        $scanFinish= (Get-WinEvent -FilterHashtable @{LogName='Application';ID=2} -MaxEvents 1).Timecreated

        $desc1 = "*Scan Completed*"
        $desc2 = "*Scan Started:* " + $scanStart.ToString().Trim()
        $desc3 = "*ScanTimeTaken:* " + ($scanFinish - $scanStart).Seconds.ToString() + " Seconds"

        #get scan results
        $desc5 = (Get-WinEvent -FilterHashtable @{LogName='Application';ID=2} -MaxEvents 1).Message.Trim()
    }
    "USBConnected" {
        $desc1 = "*USB Drive Connected*"
        $connectedDrive = Get-Disk |where BusType -eq USB
        $desc2 = "             *Serial:* " + $connectedDrive.SerialNumber
        $desc3 = "             *Name:* " + $connectedDrive.FriendlyName
        $desc4 = "             *Size:* " + [System.Math]::Round($connectedDrive.Size/1GB,1).ToString() + "GB"
    }
    "USBRemoved" {
            $desc1 = (Get-WinEvent -FilterHashtable @{LogName='Application';ID=999} -MaxEvents 1).Message.Trim()
    }
 

}
######################################################






####### Combine Strings  (Use * for BOLD, Use %0A for new line) ###############

$fullTelegramString = `
    "*IP:* " + $ip + "%0A" +
    "*Serial:* " + $serial + "%0A" +
    "*ComputerName:* " + $compname + "%0A" +
    "*SSID:* " + $ssid + "%0A" +
    "*LastCyberCheckAge:* " + $TimeSinceLastCyberCheck + " days" + "%0A" +
    "*LastCheckCAI:* " + $LastCyberCheckCAI + "%0A" +
    "*KioskVersion:* " + $KioskVersion + "%0A" +
    "*DefinitionDate:* " + $defdate + "%0A" +
    "*USB Partitions:* " + $myDrives.ToString() + "%0A" +
    "%0A" +
    $desc1 + "%0A" +
    $desc2 + "%0A" +
    $desc3 + "%0A" +
    $desc4 + "%0A" +
    $desc5 + "%0A" 
    `
######################################################





#remove special chars from telegram string
$fullTelegramString = $fullTelegramString.replace("_", "\\_").replace("[", "\\[")



curl "https://api.telegram.org/bot$tokenID/sendMessage?chat_id=$chatID&parse_mode=Markdown&text=*PCN Kiosk Activity* %0A$fullTelegramString"

 
 
