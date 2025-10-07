
@echo off
setlocal enabledelayedexpansion
echo goofy
REM Check for argument
if "%~1"=="" (
    echo Usage: %~nx0 [-a ^| -n ^| -u]
    echo.
    echo   -a    Run all installations and update Neovim config
    echo   -n    Update only Neovim config
    echo   -u    Update this script from the remote repository
    exit /b 1
)

REM Define repo variables (used in multiple places)
set REPO_URL=https://github.com/CooperDSimpson/my-configs.git
set LOCAL_REPO_DIR=%USERPROFILE%\my-configs

REM Handle -a argument: do everything
if /I "%~1"=="-a" goto do_all

REM Handle -n argument: update only Neovim config
if /I "%~1"=="-n" goto do_nvim

REM Handle -u argument: update this script
if /I "%~1"=="-u" goto do_update_script

echo Unknown argument: %1
echo Usage: %~nx0 [-a ^| -n ^| -u]
exit /b 1


:do_all
echo running all installations and updates...

echo installing clangd
winget install clangd  --accept-package-agreements --accept-source-agreements

echo installing python
winget install python  --accept-package-agreements --accept-source-agreements

echo installing nodejs
winget install OpenJS.NodeJS  --accept-package-agreements --accept-source-agreements

echo installing Git.Git
winget install Git.Git  --accept-package-agreements --accept-source-agreements

echo installing nasm
winget install NASM.NASM  --accept-package-agreements --accept-source-agreements

echo installing nvim
winget install nvim --accept-package-agreements --accept-source-agreements 

REM fallthrough to Neovim config update
goto do_nvim_update


:do_nvim
echo updating Neovim config only...
goto do_nvim_update


:do_nvim_update
REM Define paths
set NVIM_CONFIG_DIR=%LOCALAPPDATA%\nvim
set DEST_FILE=%NVIM_CONFIG_DIR%\init.lua
set CLANGD_DEST=C:\.clangd

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo Git is not installed or not in PATH. Please install Git first.
    pause
    exit /b 1
)

REM Clone repo if it doesn't exist
if not exist "%LOCAL_REPO_DIR%\.git" (
    echo Cloning my-configs repo...
    git clone %REPO_URL% "%LOCAL_REPO_DIR%"
) else (
    echo my-configs repo already exists, pulling latest changes...
    cd "%LOCAL_REPO_DIR%"
    git pull
)

REM Make sure Neovim config directory exists
if not exist "%NVIM_CONFIG_DIR%" (
    echo Creating Neovim config directory...
    mkdir "%NVIM_CONFIG_DIR%"
)

REM Copy init.lua from repo to Neovim config folder
echo Copying init.lua to Neovim config folder...
copy /Y "%LOCAL_REPO_DIR%\init.lua" "%DEST_FILE%"

REM Copy .clangd file to C:\
echo Copying .clangd file to C:\
copy /Y "%LOCAL_REPO_DIR%\.clangd" "C:\.clangd"

REM If we came here from -n, skip MSYS2 and finish
if /I "%~1"=="-n" goto end

REM MSYS2 install and update section

setlocal

rem Define MSYS2 path
set MSYS2_ROOT=C:\msys64
set MSYS2_BASH=%MSYS2_ROOT%\usr\bin\bash.exe

rem Check if MSYS2 is installed
if not exist "%MSYS2_BASH%" (
    echo MSYS2 not found. Installing via winget...
    winget install --id=MSYS2.MSYS2 -e --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo Failed to install MSYS2. Exiting.
        exit /b 1
    )
) else (
    echo MSYS2 found at %MSYS2_ROOT%
)

rem Update MSYS2 core system and package database
echo Updating MSYS2 system and package database...
"%MSYS2_BASH%" -lc "pacman -Syuu --noconfirm"

rem Install packages in MSYS2 environment (msys)
echo Installing base msys packages...
"%MSYS2_BASH%" -lc "pacman -S --needed --noconfirm base-devel git vim"

rem Install mingw64 toolchain and clang (clang64 is clang inside mingw64)
echo Installing mingw64 toolchain and clang...
"%MSYS2_BASH%" -lc "pacman -S --needed --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-clang"

rem Optional: Install other common mingw64 packages
echo Installing extra mingw64 packages...
"%MSYS2_BASH%" -lc "pacman -S --needed --noconfirm mingw-w64-x86_64-cmake mingw-w64-x86_64-ninja mingw-w64-x86_64-python mingw-w64-x86_64-glfw"

echo MSYS2 environment setup complete!

goto end


:do_update_script
echo Updating this script from the remote repository...

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo Git is not installed or not in PATH. Please install Git first.
    pause
    exit /b 1
)

REM Clone repo if it doesn't exist
if not exist "%LOCAL_REPO_DIR%\.git" (
    echo Cloning my-configs repo...
    git clone %REPO_URL% "%LOCAL_REPO_DIR%"
) else (
    echo my-configs repo already exists, pulling latest changes...
    cd "%LOCAL_REPO_DIR%"
    git pull
)

REM Copy setup-things.bat from repo to current script's directory
set SCRIPT_DIR=%~dp0
echo Copying setup-things.bat to %SCRIPT_DIR%
copy /Y "%LOCAL_REPO_DIR%\setup-things.bat" "%SCRIPT_DIR%"

echo Update complete. Please rerun the updated script if needed.

goto end


:end
echo done.
exit /b 0

