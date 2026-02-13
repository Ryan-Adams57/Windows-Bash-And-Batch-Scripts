@echo off
net session >nul 2>&1
if %errorLevel% == 0 (
    del /s /f /q %temp%\*.*
    rd /s /q %temp%
    md %temp%
    del /s /f /q C:\Windows\Temp\*.*
    rd /s /q C:\Windows\Temp
    md C:\Windows\Temp
    echo Temporary files cleared.
    pause
) else (
    echo Error: Please run as Administrator.
    pause
)