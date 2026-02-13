@echo off
net session >nul 2>&1
if %errorLevel% == 0 (
    net stop wuauserv
    net stop cryptSvc
    net stop bits
    net stop msiserver
    ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
    ren C:\Windows\System32\catroot2 catroot2.old
    net start wuauserv
    net start cryptSvc
    net start bits
    net start msiserver
    echo Windows Update components reset.
    pause
) else (
    echo Error: Please run as Administrator.
    pause
)