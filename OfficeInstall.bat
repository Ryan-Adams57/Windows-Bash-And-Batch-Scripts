@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =====================================================
REM CONFIGURATION
REM =====================================================
set SOURCE=\\Server\Share\Office
set SETUP=%SOURCE%\setup.exe
set CONFIG=%SOURCE%\configuration.xml
set LOGFILE=C:\Windows\Temp\OfficeInstall.log
set OFFICEPATH1=C:\Program Files\Microsoft Office\root\Office16
set OFFICEPATH2=C:\Program Files (x86)\Microsoft Office\root\Office16

echo ===================================================== >> %LOGFILE%
echo %DATE% %TIME% - Starting Office installation script >> %LOGFILE%

REM =====================================================
REM CHECK NETWORK SHARE ACCESSIBILITY
REM =====================================================
if not exist "%SETUP%" (
    echo %DATE% %TIME% - ERROR: Cannot access %SETUP% >> %LOGFILE%
    echo Network path not accessible. Exiting. >> %LOGFILE%
    exit /b 1
)

REM =====================================================
REM CHECK IF OFFICE IS ALREADY INSTALLED
REM =====================================================
if exist "%OFFICEPATH1%\WINWORD.EXE" (
    echo %DATE% %TIME% - Office already installed (64-bit). Exiting. >> %LOGFILE%
    exit /b 0
)

if exist "%OFFICEPATH2%\WINWORD.EXE" (
    echo %DATE% %TIME% - Office already installed (32-bit). Exiting. >> %LOGFILE%
    exit /b 0
)

echo %DATE% %TIME% - Office not detected. Starting installation... >> %LOGFILE%

REM =====================================================
REM INSTALL OFFICE SILENTLY
REM =====================================================
start /wait "" "%SETUP%" /configure "%CONFIG%"
set EXITCODE=%ERRORLEVEL%

echo %DATE% %TIME% - Setup finished with exit code %EXITCODE% >> %LOGFILE%

if NOT "%EXITCODE%"=="0" (
    echo %DATE% %TIME% - ERROR: Office installation failed. >> %LOGFILE%
    exit /b %EXITCODE%
)

echo %DATE% %TIME% - Office installation completed successfully. >> %LOGFILE%
exit /b 0