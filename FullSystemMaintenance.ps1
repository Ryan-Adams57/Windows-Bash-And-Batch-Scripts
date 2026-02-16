# ==========================================
# WINDOWS 11 WEEKEND MAINTENANCE SCRIPT
# Runs ONLY Wednesday & Sunday
# ==========================================

# -------------------------------
# CHECK DAY (Wednesday or Sunday)
# -------------------------------
$today = (Get-Date).DayOfWeek
if ($today -ne "Wednesday" -and $today -ne "Sunday") {
    Write-Host "This script only runs on Wednesday and Sunday."
    Exit
}

# -------------------------------
# ENSURE ADMIN
# -------------------------------
If (-NOT ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run as Administrator!" -ForegroundColor Red
    Exit
}

Write-Host "Starting Wednesday/Sunday System Maintenance..." -ForegroundColor Cyan

# -------------------------------
# BROWSER PROCESS LIST
# -------------------------------
$browserProcesses = "chrome","msedge","firefox","iexplore"

# -------------------------------
# OPEN BROWSERS (Triggers Extension Updates)
# -------------------------------
Start-Process "chrome.exe" -ErrorAction SilentlyContinue
Start-Process "msedge.exe" -ErrorAction SilentlyContinue
Start-Process "firefox.exe" -ErrorAction SilentlyContinue
Start-Process "iexplore.exe" -ErrorAction SilentlyContinue

Start-Sleep -Seconds 20

# -------------------------------
# FORCE BROWSER UPDATE CHECK
# -------------------------------
Start-Process "chrome.exe" "--check-for-update-interval=1" -ErrorAction SilentlyContinue
Start-Process "msedge.exe" "--check-for-update-interval=1" -ErrorAction SilentlyContinue

Start-Sleep -Seconds 10

# -------------------------------
# CLOSE ALL BROWSERS
# -------------------------------
foreach ($proc in $browserProcesses) {
    Get-Process $proc -ErrorAction SilentlyContinue | Stop-Process -Force
}

Start-Sleep -Seconds 5

# -------------------------------
# CLEAR GOOGLE CHROME DATA
# -------------------------------
Write-Host "Clearing Chrome Data..."
$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
if (Test-Path $chromePath) {
    Get-ChildItem $chromePath -Directory | ForEach-Object {
        Remove-Item "$($_.FullName)\History" -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Cookies" -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Web Data" -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\DownloadMetadata" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Extension State\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# -------------------------------
# CLEAR MICROSOFT EDGE DATA
# -------------------------------
Write-Host "Clearing Edge Data..."
$edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
if (Test-Path $edgePath) {
    Get-ChildItem $edgePath -Directory | ForEach-Object {
        Remove-Item "$($_.FullName)\History" -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Cookies" -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Web Data" -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\DownloadMetadata" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$($_.FullName)\Extension State\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# -------------------------------
# CLEAR FIREFOX DATA
# -------------------------------
Write-Host "Clearing Firefox Data..."
$firefoxProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles\" -Directory -ErrorAction SilentlyContinue
foreach ($profile in $firefoxProfiles) {
    Remove-Item "$($profile.FullName)\places.sqlite" -Force -ErrorAction SilentlyContinue
    Remove-Item "$($profile.FullName)\cookies.sqlite" -Force -ErrorAction SilentlyContinue
    Remove-Item "$($profile.FullName)\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$($profile.FullName)\storage\default\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$($profile.FullName)\extension-settings.json" -Force -ErrorAction SilentlyContinue
}

# -------------------------------
# CLEAR INTERNET EXPLORER DATA
# (Deprecated in Windows 11)
# -------------------------------
Write-Host "Clearing Internet Explorer Data..."
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255

# -------------------------------
# WINDOWS UPDATE (ALL TYPES)
# -------------------------------
Write-Host "Running Windows Update..."

Install-Module PSWindowsUpdate -Force -Confirm:$false -ErrorAction SilentlyContinue
Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue

Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction SilentlyContinue

# Backup & Cleanup Windows Update Components
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# -------------------------------
# MICROSOFT STORE UPDATES
# -------------------------------
Write-Host "Updating Microsoft Store Apps..."
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" `
-ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" -ErrorAction SilentlyContinue |
Invoke-CimMethod -MethodName UpdateScanMethod -ErrorAction SilentlyContinue

# -------------------------------
# WINDOWS SECURITY INTELLIGENCE UPDATE
# -------------------------------
Write-Host "Updating Security Intelligence..."
Update-MpSignature -ErrorAction SilentlyContinue

# -------------------------------
# DELETE TEMP FILES
# -------------------------------
Write-Host "Deleting TEMP files..."
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Delete Windows Error Reports
Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue

# -------------------------------
# EMPTY RECYCLE BIN
# -------------------------------
Write-Host "Emptying Recycle Bin..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# -------------------------------
# SYSTEM CLEANUP (Storage Equivalent)
# -------------------------------
Write-Host "Running System Cleanup..."
cleanmgr /verylowdisk

Write-Host "Wednesday/Sunday Maintenance Complete!" -ForegroundColor Green
