@echo off
setlocal enabledelayedexpansion

set "steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
set "steamcmd_dir=%~dp0steamcmd"
set "server_dir=%steamcmd_dir%\steamapps\common\SCP Secret Laboratory Dedicated Server"
set "total_steps=3"
set "current_step=0"
set "progress=0"
set "spinner=0"

title Northwood SCP:SL Server Creator

set "bar_filled=#"
set "bar_empty=-"
set "spinner_chars=|\-/"

if not exist "%steamcmd_dir%" mkdir "%steamcmd_dir%"
cd /d "%steamcmd_dir%"

call :initialize_display
call :install_steamcmd
call :download_server
call :complete_display

:show_wiki_prompt
echo.
choice /c yn /n /m "Open official server guide? (Y/N): "
if errorlevel 2 exit /b
start "" "https://nwbooktest.itsgamertime.xyz/books/servers"
exit /b

:install_steamcmd
call :update_progress "Installing SteamCMD..."
if exist "steamcmd.exe" (
    set /a "current_step+=1"
    exit /b
)
if not exist "steamcmd.zip" (
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%steamcmd_url%' -OutFile 'steamcmd.zip'"
)
if not exist "steamcmd.exe" (
    powershell -Command "Expand-Archive -Path 'steamcmd.zip' -DestinationPath '%steamcmd_dir%' -Force"
)
set /a "current_step+=1"
exit /b

:download_server
call :update_progress "Downloading SCP:SL Server..."
if exist "%server_dir%" (
    set /a "current_step+=1"
    exit /b
)
start "" /WAIT "%steamcmd_dir%\steamcmd.exe" +login anonymous +app_update 996560 validate +quit
if not exist "%server_dir%\LocalAdmin.exe" (
    echo.
    echo ERROR: Failed to download LocalAdmin.exe!
    echo Check SteamCMD output above for errors
    timeout /t 5
    exit /b 1
)
set /a "current_step+=1"
exit /b

:initialize_display
cls
echo ==================================================
echo      Northwood SCP:SL Server Creator
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
echo      Northwood SCP:SL Server Creator
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
echo      Northwood SCP:SL Server Creator
echo --------------------------------------------------
echo                     Progress                     
echo.                                                 
echo  Current Task: Installation Complete!            
echo  [########################################] 100%% 
echo ==================================================
timeout /t 2 >nul
goto :show_wiki_prompt