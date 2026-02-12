@echo off
title DISHA LAB MASTER SETUP
setlocal EnableExtensions EnableDelayedExpansion

:: -------------------------------------------------------
:: CONFIG
:: -------------------------------------------------------

set "ZIP_URL=https://github.com/SohamKore/word/releases/download/v1/@Disha.zip"
set "WALL_URL=https://raw.githubusercontent.com/SohamKore/word/main/wallpaper.png"

:: IMPORTANT CHANGE
set "CONTENT=C:\@Disha"

set "TEMP=C:\disha_setup_tmp"
set "ZIPFILE=%TEMP%\disha.zip"
set "WALLFILE=C:\Windows\Web\Wallpaper\disha.png"

:: -------------------------------------------------------
:: Admin check
:: -------------------------------------------------------

net session >nul 2>&1
if %errorlevel% neq 0 (
 echo Run this script as Administrator.
 pause
 exit /b
)

:: -------------------------------------------------------
:: Temp folder
:: -------------------------------------------------------

if not exist "%TEMP%" mkdir "%TEMP%"

:: -------------------------------------------------------
:: Download ZIP (GitHub Release)
:: -------------------------------------------------------

echo Downloading notes package...
curl -L "%ZIP_URL%" -o "%ZIPFILE%"

if not exist "%ZIPFILE%" (
 echo ZIP download failed.
 pause
 exit /b
)

:: -------------------------------------------------------
:: Extract to temp
:: -------------------------------------------------------

echo Extracting ZIP...
powershell -NoProfile -Command "Expand-Archive -Force '%ZIPFILE%' '%TEMP%'"

:: -------------------------------------------------------
:: Move @Disha to C:\ (keep names unchanged)
:: -------------------------------------------------------

echo Moving @Disha to C:\ ...

if exist "C:\@Disha" (
    echo Existing C:\@Disha found. Skipping move.
) else (
    if exist "%TEMP%\@Disha" (
        move "%TEMP%\@Disha" "C:\" >nul
    ) else (
        echo @Disha folder not found in ZIP.
        pause
        exit /b
    )
)

:: -------------------------------------------------------
:: Verify structure
:: -------------------------------------------------------

if not exist "%CONTENT%\@ NOTES" (
 echo Extraction failed or structure incorrect.
 pause
 exit /b
)

:: -------------------------------------------------------
:: Download wallpaper
:: -------------------------------------------------------

echo Downloading wallpaper...
curl -L "%WALL_URL%" -o "%WALLFILE%"

:: -------------------------------------------------------
:: NTFS permissions
:: Users can open, read, copy. No modify / delete.
:: -------------------------------------------------------

echo Applying NTFS permissions...

icacls "%CONTENT%" /inheritance:r

icacls "%CONTENT%" /grant:r "SYSTEM:(OI)(CI)F"
icacls "%CONTENT%" /grant:r "Administrators:(OI)(CI)F"
icacls "%CONTENT%" /grant:r "Users:(OI)(CI)RX"
icacls "%CONTENT%" /grant:r "Users:(OI)(CI)RX"
icacls "%CONTENT%" /grant "Users:(CI)RX"


:: -------------------------------------------------------
:: Enforced wallpaper (machine policy)
:: -------------------------------------------------------

echo Enforcing wallpaper...

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" ^
 /v Wallpaper /t REG_SZ /d "%WALLFILE%" /f

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" ^
 /v WallpaperStyle /t REG_SZ /d 2 /f

RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

:: -------------------------------------------------------
:: Time sync now
:: -------------------------------------------------------

w32tm /resync /force >nul 2>&1


:: -------------------------------------------------------
:: Helper scripts for SYSTEM tasks
:: -------------------------------------------------------

set "SYS_SCRIPTS=C:\disha_sys"
if not exist "%SYS_SCRIPTS%" mkdir "%SYS_SCRIPTS%"

:: ---- time sync
:: ---- updated time sync in %SYS_SCRIPTS%\time_sync.cmd
:: ---- updated time sync with network check
>"%SYS_SCRIPTS%\time_sync.cmd" (
echo @echo off
echo title DISHA - Time Sync
echo echo Waiting for internet...
echo :waitnet
echo ping -n 1 8.8.8.8 ^>nul 2^>^&1
echo if errorlevel 1 goto waitnet
echo.
echo echo Internet detected.
echo echo Setting India time zone...
echo tzutil /s "India Standard Time"
echo.
echo echo Restarting time service...
echo net stop w32time ^>nul 2^>^&1
echo net start w32time ^>nul 2^>^&1
echo.
echo echo Syncing time...
echo w32tm /resync /force ^>nul 2^>^&1
echo.
echo if errorlevel 1 msg * "DISHA LAB : Time synchronization FAILED."
echo if not errorlevel 1 msg * "DISHA LAB : System time synchronized successfully."
)

:: ---- cleanup
>"%SYS_SCRIPTS%\cleanup.cmd" (
 echo del /q /f /s "%TEMP%\*" 2^>nul
 echo for /d %%%%i in ^("%TEMP%\*"^) do rd /s /q "%%%%i" 2^>nul
 echo powershell -NoProfile -Command "Clear-RecycleBin -Force"
)

:: ---- startup junk heal (simple safe version)
>"%SYS_SCRIPTS%\startup_clean.cmd" (
 echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f
)

:: ---- shutdown warn
>"%SYS_SCRIPTS%\shutdown_warn.cmd" (
 echo msg * "Lab PCs will shutdown in 5 minutes. Please save your work."
)

:: ---- shutdown force
>"%SYS_SCRIPTS%\shutdown_force.cmd" (
 echo shutdown /s /f /t 0
)

:: -------------------------------------------------------
:: Scheduled tasks (SYSTEM / highest)
:: -------------------------------------------------------

echo Creating SYSTEM scheduled tasks...

schtasks /create /f ^
 /tn "DISHA_TimeSync_Startup" ^
 /sc onstart ^
 /ru SYSTEM ^
 /rl highest ^
 /tr "%SYS_SCRIPTS%\time_sync.cmd"

schtasks /create /f ^
 /tn "DISHA_Cleanup_Startup" ^
 /sc onstart ^
 /ru SYSTEM ^
 /rl highest ^
 /tr "%SYS_SCRIPTS%\cleanup.cmd"

schtasks /create /f ^
 /tn "DISHA_StartupHeal_Login" ^
 /sc onlogon ^
 /ru SYSTEM ^
 /rl highest ^
 /tr "%SYS_SCRIPTS%\startup_clean.cmd"

schtasks /create /f ^
 /tn "DISHA_Shutdown_Warn" ^
 /sc daily /st 21:55 ^
 /ru SYSTEM ^
 /rl highest ^
 /tr "%SYS_SCRIPTS%\shutdown_warn.cmd"

schtasks /create /f ^
 /tn "DISHA_Shutdown_Force" ^
 /sc daily /st 22:00 ^
 /ru SYSTEM ^
 /rl highest ^
 /tr "%SYS_SCRIPTS%\shutdown_force.cmd"

:: -------------------------------------------------------
:: High performance power plan
:: -------------------------------------------------------

powercfg -setactive SCHEME_MIN

:: -------------------------------------------------------
:: Cleanup temp
:: -------------------------------------------------------

rd /s /q "%TEMP%"

echo.
echo ---------------------------------------
echo DISHA LAB SETUP COMPLETED SUCCESSFULLY
echo ---------------------------------------
echo Please restart this PC once.
pause
