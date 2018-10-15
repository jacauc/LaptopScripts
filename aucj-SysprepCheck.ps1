###   Utility to check if Sysprep or Maintenance is Necessary 
### Technical Contact for the script: Jacques Aucamp (AUCJ)

Add-Type -AssemblyName PresentationCore,PresentationFramework
$ErrorActionPreference = "SilentlyContinue" 


function Get-ActivationStatus {
[CmdletBinding()]
 param(
 [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
 [string]$DNSHostName = $Env:COMPUTERNAME
 )
 process {
 try {
 $wpa = Get-WmiObject SoftwareLicensingProduct -ComputerName $DNSHostName `
 -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
 -Property LicenseStatus -ErrorAction Stop
 } catch {
 $status = New-Object ComponentModel.Win32Exception ($_.Exception.ErrorCode)
 $wpa = $null 
 }
 $out = New-Object psobject -Property @{
 ComputerName = $DNSHostName;
 Status = [string]::Empty;
 }
 if ($wpa) {
 :outer foreach($item in $wpa) {
 switch ($item.LicenseStatus) {
 0 {$out.Status = "Unlicensed"}
 1 {$out.Status = "Licensed"; break outer}
 2 {$out.Status = "Out-Of-Box Grace Period"; break outer}
 3 {$out.Status = "Out-Of-Tolerance Grace Period"; break outer}
 4 {$out.Status = "Non-Genuine Grace Period"; break outer}
 5 {$out.Status = "Notification"; break outer}
 6 {$out.Status = "Extended Grace"; break outer}
 default {$out.Status = "Unknown value"}
 }
 }
 } else { $out.Status = $status.Message }
 $out
 }
}

$mystat = Get-ActivationStatus  | select -ExpandProperty Status

If ($mystat.ToString() -ne "Licensed") {
    [System.Windows.MessageBox]::Show("Windows is not activated. Connect to internet and run 'slmgr /ato' command.", "FGP PCN Sysprep Message");
}


cls

 

$serial = ((gwmi win32_bios).SerialNumber)
$newcompname = "FGPPCN-" + $serial
$adminname = ((Get-CimInstance win32_useraccount | Where-Object {$_.Sid -Like "*-500"}).Name)
$newadminname = "!" + $newcompname



if (($adminname -notlike $newadminname) -or ($env:COMPUTERNAME -notlike $newcompname)){
  [System.Windows.MessageBox]::Show("The sysprep utility needs to be executed on this machine!", "FGP PCN Sysprep Message");
}
 
$LastCyberCheck = [datetime](Get-ItemProperty "HKLM:\Software\TCO").LastCyberCheck

$TodayDate = [datetime]::Today 

$TimeSinceLastCyberCheck = $TodayDate - $LastCyberCheck

if ($TimeSinceLastCyberCheck.Days -gt 20) {
    [System.Windows.MessageBox]::Show("It has been " +$TimeSinceLastCyberCheck.Days +" days since the last PCN Cybersecurity Scan of this computer. `nPlease request FGP PCN team Cybercheck and Baseline Update `nContact x2481 or fgppcnat@tengizchevroil.com for more information.", "FGP PCN Cybersecurity Message");
}








 
