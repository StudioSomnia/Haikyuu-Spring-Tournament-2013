@echo off
rem ====================================================================
rem  Haikyuu: Spring Tournament 2013  -  launcher
rem
rem  Play:            run.bat
rem  AI stress test:  run.bat --autotest
rem  Input test:      run.bat --matchtest
rem  Screen test:     run.bat --uitest
rem
rem  If Godot is not found automatically, set HYK_GODOT to the full path
rem  of a Godot 4 executable before running this file.
rem ====================================================================
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

set "HEADLESS="
for %%A in (--autotest --matchtest --uitest) do (
    if /i "%~1"=="%%A" set "HEADLESS=1"
)

set "GODOT_GUI="
set "GODOT_CONSOLE="

if defined HYK_GODOT if exist "%HYK_GODOT%" (
    echo %HYK_GODOT% | findstr /i "_console.exe" >nul
    if errorlevel 1 (
        set "GODOT_GUI=%HYK_GODOT%"
    ) else (
        set "GODOT_CONSOLE=%HYK_GODOT%"
    )
)

if not defined GODOT_GUI if not defined GODOT_CONSOLE call :search_winget
if not defined GODOT_GUI if not defined GODOT_CONSOLE call :search_common
if not defined GODOT_GUI if not defined GODOT_CONSOLE call :search_path

if not defined GODOT_GUI set "GODOT_GUI=%GODOT_CONSOLE%"
if not defined GODOT_CONSOLE set "GODOT_CONSOLE=%GODOT_GUI%"

if not defined GODOT_GUI (
    echo.
    echo   Could not find a Godot 4 executable.
    echo.
    echo   Install Godot 4.x from https://godotengine.org/download
    echo   or point HYK_GODOT at the executable, for example:
    echo.
    echo       set HYK_GODOT=C:\Godot\Godot_v4.7.2-stable_win64.exe
    echo.
    pause
    exit /b 1
)

set "GODOT=%GODOT_GUI%"
if defined HEADLESS set "GODOT=%GODOT_CONSOLE%"

echo.
echo   HAIKYUU - Spring Tournament 2013
echo   Godot:   %GODOT%
echo   Project: %PROJECT_DIR%
echo.

if defined HEADLESS (
    "%GODOT%" --headless --path "%PROJECT_DIR%" -- %*
    exit /b %ERRORLEVEL%
)

start "" "%GODOT%" --path "%PROJECT_DIR%" %*
exit /b 0

rem --------------------------------------------------------------------
rem  Search helpers
rem --------------------------------------------------------------------

:search_winget
for /d %%P in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do call :scan_dir "%%~P"
for /d %%P in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do call :scan_folder "%%~P"
exit /b 0

:search_common
for %%R in (
    "%LOCALAPPDATA%\Programs\Godot"
    "%LOCALAPPDATA%\Godot"
    "%ProgramFiles%\Godot"
    "%ProgramFiles%\Godot Engine"
    "%ProgramFiles(x86)%\Godot"
    "C:\Godot"
    "C:\Tools\Godot"
) do call :scan_folder "%%~R"
exit /b 0

:search_path
for %%N in (godot4.exe godot.exe Godot_v4.exe) do (
    if not defined GODOT_GUI (
        for /f "delims=" %%W in ('where %%N 2^>nul') do if not defined GODOT_GUI set "GODOT_GUI=%%W"
    )
)
exit /b 0

rem Scans one folder and every direct subfolder (versions / zips unpacked).
:scan_folder
if not exist "%~1" exit /b 0
call :scan_dir "%~1"
for /d %%S in ("%~1\*") do call :scan_dir "%%~S"
exit /b 0

:scan_dir
if not exist "%~1" exit /b 0
for %%E in ("%~1\Godot_v*_win64.exe") do (
    if not defined GODOT_GUI if exist "%%~E" set "GODOT_GUI=%%~E"
)
for %%E in ("%~1\Godot_v*_win64_console.exe") do (
    if not defined GODOT_CONSOLE if exist "%%~E" set "GODOT_CONSOLE=%%~E"
)
exit /b 0
