@echo off
net session >nul 2>&1
if %errorLevel% == 0 (
    net stop spooler
    del /Q /F /S "%systemroot%\System32\Spool\Printers\*.*"
    net start spooler
    echo Print Spooler cleared and restarted.
    pause
) else (
    echo Error: Please run as Administrator.
    pause
)