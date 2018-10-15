###   Utility to prep PCN Commissioning laptops by Jacques Aucamp (AUCJ) - Oct 2018

$ErrorActionPreference = "SilentlyContinue" 
cls





Write-Host -ForegroundColor Yellow @"
        FGP PCN SYSPREP TOOL
        ---------------------------

This script is to be executed AFTER restoring the master PCN image on this machine.
Technical Contact for the script: Jacques Aucamp (AUCJ)
____________________________________________________________________________________________


"@ 
 

$serial = ((gwmi win32_bios).SerialNumber)
$newcompname = "FGPPCN-" + $serial
$adminname = ((Get-CimInstance win32_useraccount | Where-Object {$_.Sid -Like "*-500"}).Name)
$newadminname = "!" + $newcompname


if ($adminname -notlike $newadminname) {
  Rename-LocalUser -Name $adminname -NewName $newadminname
}
 Enable-LocalUser $newadminname

if ($env:COMPUTERNAME -notlike $newcompname) {
  Rename-Computer -NewName $newcompname
}

& cscript.exe "c:\windows\system32\slmgr.vbs" /ato




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


[System.Windows.MessageBox]::Show("It is highly recommended to reboot the computer now.", "FGP PCN Sysprep Message");



net start w32time
w32tm /resync /force







 
