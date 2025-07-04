@echo off
setlocal enabledelayedexpansion

:: Configuration
set "steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
set "steamcmd_dir=%~dp0steamcmd"
set "server_dir=%~dp0SCP-SL-Server"
set "total_steps=5"
set "current_step=0"
set "progress=0"
set "spinner=0"
set "beta_params="
set "version_file=%server_dir%\version.info"

title Northwood SCP:SL Server Manager

:: UI Settings
set "bar_filled=#"
set "bar_empty=-"
set "spinner_chars=|\-/"

:: Create directories
if not exist "%steamcmd_dir%" mkdir "%steamcmd_dir%"
if not exist "%server_dir%" mkdir "%server_dir%"
cd /d "%~dp0"

:: Check existing installation
if exist "%server_dir%\LocalAdmin.exe" (
    if exist "%version_file%" (
        set /p "current_version=" < "%version_file%"
    ) else (
        set "current_version=Public Release (Current Game Version)"
    )
    goto :management_menu
)

:: Main installation flow
call :initialize_display
call :install_steamcmd
call :select_version
call :download_server
call :complete_display
call :post_install_prompt
goto :management_menu

:install_steamcmd
call :update_progress "Installing SteamCMD..."
if exist "%steamcmd_dir%\steamcmd.exe" (
    set /a "current_step+=1"
    exit /b
)

if not exist "%steamcmd_dir%\steamcmd.zip" (
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%steamcmd_url%' -OutFile '%steamcmd_dir%\steamcmd.zip'"
)

if not exist "%steamcmd_dir%\steamcmd.exe" (
    powershell -Command "Expand-Archive -Path '%steamcmd_dir%\steamcmd.zip' -DestinationPath '%steamcmd_dir%' -Force"
)
set /a "current_step+=1"
exit /b

:select_version
echo.
echo ===== Version Selection =====
echo 1. Public Release (Current Game Version)
echo 2. Public Testing
echo 3. Experimental
echo 4. Custom Beta Code
choice /c 1234 /n /m "Select version [1-4]: "
set "beta_code="
if errorlevel 4 (
    set /p "beta_code=Enter beta code: "
    set "beta_params=-beta %beta_code%"
    set "current_version=%beta_code%"
) else if errorlevel 3 (
    set "beta_params=-beta experimental"
    set "current_version=Experimental"
) else if errorlevel 2 (
    set "beta_params=-beta publictesting"
    set "current_version=Public Testing"
) else (
    set "beta_params="
    set "current_version=Public Release (Current Game Version)"
)
echo %current_version% > "%version_file%"
exit /b

:download_server
call :update_progress "Downloading Server..."
start "" /wait "%steamcmd_dir%\steamcmd.exe" +force_install_dir "%server_dir%" +login anonymous %beta_params% +app_update 996560 validate +quit
if not exist "%server_dir%\LocalAdmin.exe" (
    echo ERROR: Server installation failed!
    timeout /t 5
    exit /b 1
)
set /a "current_step+=1"
exit /b

:management_menu
cls
echo ===== Server Management =====
echo Current Version: %current_version%
echo.
echo 1. Check for updates
echo 2. Change version
echo 3. Open documentation
echo 4. Exit
choice /c 1234 /n /m "Select option [1-4]: "

if errorlevel 4 exit /b
if errorlevel 3 (
    start "" "https://nwbooktest.itsgamertime.xyz/books/servers"
    goto :management_menu
)
if errorlevel 2 (
    call :select_version
    call :update_server
    goto :management_menu
)
if errorlevel 1 (
    call :update_server
    goto :management_menu
)

:update_server
call :update_progress "Checking for updates..."
set "temp_file=%temp%\version.tmp"
dir "%server_dir%\LocalAdmin.exe" > "%temp_file%"

start "" /wait "%steamcmd_dir%\steamcmd.exe" +force_install_dir "%server_dir%" +login anonymous %beta_params% +app_update 996560 validate +quit

dir "%server_dir%\LocalAdmin.exe" > "%temp_file%.new"
fc "%temp_file%" "%temp_file%.new" >nul
if errorlevel 1 (
    echo Update successful!
    echo %current_version% > "%version_file%"
) else (
    echo Server is already up to date!
)
del "%temp_file%" "%temp_file%.new" 2>nul
timeout /t 2 >nul
exit /b

:initialize_display
cls
echo ==================================================
echo      Northwood SCP:SL Server Manager
echo --------------------------------------------------
echo                     Progress                     
echo.                                                 
echo  Current Task: Initializing...                   
echo  [----------------------------------------]   0%% 
echo ==================================================
exit /b

:update_progress
set "task_description=%~1"
set /a "progress=(current_step * 100) / total_steps"
set /a "filled=(progress * 40) / 100"
set "progress_bar="
for /l %%i in (1,1,%filled%) do set "progress_bar=!progress_bar!%bar_filled%"
set /a "remaining=40 - filled"
for /l %%i in (1,1,%remaining%) do set "progress_bar=!progress_bar!%bar_empty%"
set /a "spinner=(spinner + 1) %% 4"
for %%a in ("%spinner_chars%") do (
    set "spinner_str=%%~a"
    call set "spinner_char=%%spinner_str:~%spinner%,1%%"
)
cls
echo ==================================================
echo      Northwood SCP:SL Server Manager
echo --------------------------------------------------
echo                     Progress                     
echo.                                                 
echo  Current Task: %task_description% %spinner_char%  
echo  [%progress_bar%] %progress%%%
echo ==================================================
exit /b

:complete_display
cls
echo ==================================================
echo      Installation Complete!                      
echo --------------------------------------------------
echo  Installed Version: %current_version%
echo  Install Location:  %server_dir%
echo  [########################################] 100%% 
echo ==================================================
timeout /t 3 >nul
exit /b

:post_install_prompt
echo.
choice /c yn /n /m "Would you like to open the official guide? (Y/N): "
if errorlevel 2 exit /b
start "" "https://techwiki.scpslgame.com/books/server-guides"
exit /b
