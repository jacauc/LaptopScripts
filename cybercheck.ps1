$ErrorActionPreference = "SilentlyContinue" 
cls
Write-Host -ForegroundColor Yellow @"
        FGP PCN CYBERSECURITY TOOLS
        ---------------------------

This script is to be executed AFTER all the periodic cyber checks was done on this machine.
Technical Contact for the script: Jacques Aucamp (AUCJ)
____________________________________________________________________________________________


"@ 


$successful = Read-Host "Type YES to confirm all Cyber Checks was completed? (YES/NO)"
$todaysdate = (Get-Date -UFormat "%d %b %Y")

if ($successful -eq "yes") {
    (New-ItemProperty HKLM:\Software\TCO -Name LastCyberCheck -Value $todaysdate -Force) | out-null

    $cai = Read-Host "Please enter the CAI of person who validated this machine on" $todaysdate 
    (New-ItemProperty HKLM:\Software\TCO -Name LastCheckCAI -Value $cai -Force) | out-null
}

Invoke-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\bginfo.lnk"
