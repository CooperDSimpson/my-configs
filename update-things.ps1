<#
.SYNOPSIS
  Setup script for installing packages and updating configs.

.DESCRIPTION
  Supports three modes:
    -a : Install all packages and update Neovim config
    -n : Update only Neovim config
    -u : Update this script from the remote repository

.EXAMPLE
  .\setup-things.ps1 -a
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("-a", "-n", "-u")]
    [string]$Mode
)

# Variables
$RepoUrl = "https://github.com/CooperDSimpson/my-configs.git"
$LocalRepoDir = "$env:USERPROFILE\my-configs"
$NvimConfigDir = "$env:LOCALAPPDATA\nvim"
$DestFile = Join-Path $NvimConfigDir "init.lua"
$ClangdDest = "C:\.clangd"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

function Check-Git {
    try {
        git --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Clone-Or-Pull-Repo {
    if (-not (Test-Path "$LocalRepoDir\.git")) {
        Write-Host "Cloning my-configs repo..."
        git clone $RepoUrl $LocalRepoDir
    } else {
        Write-Host "my-configs repo already exists, pulling latest changes..."
        Push-Location $LocalRepoDir
        git pull
        Pop-Location
    }
}

function Install-Package-Winget {
    param(
        [string]$PackageId
    )
    Write-Host "Installing $PackageId via winget..."
    winget install $PackageId --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to install $PackageId"
    }
}

function Update-Neovim-Config {
    if (-not (Check-Git)) {
        Write-Error "Git is not installed or not in PATH. Please install Git first."
        exit 1
    }

    Clone-Or-Pull-Repo

    if (-not (Test-Path $NvimConfigDir)) {
        Write-Host "Creating Neovim config directory..."
        New-Item -ItemType Directory -Path $NvimConfigDir | Out-Null
    }

    Write-Host "Copying init.lua to Neovim config folder..."
    Copy-Item -Path (Join-Path $LocalRepoDir "init.lua") -Destination $DestFile -Force

    Write-Host "Copying .clangd file to C:\"
    Copy-Item -Path (Join-Path $LocalRepoDir ".clangd") -Destination $ClangdDest -Force
}

function Install-Or-Update-MSYS2 {
    $Msys2Root = "C:\msys64"
    $Msys2Bash = Join-Path $Msys2Root "usr\bin\bash.exe"

    if (-not (Test-Path $Msys2Bash)) {
        Write-Host "MSYS2 not found. Installing via winget..."
        winget install --id=MSYS2.MSYS2 -e --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install MSYS2. Exiting."
            exit 1
        }
    } else {
        Write-Host "MSYS2 found at $Msys2Root"
    }

    Write-Host "Updating MSYS2 system and package database..."
    & $Msys2Bash -lc "pacman -Syuu --noconfirm"

    Write-Host "Installing base msys packages..."
    & $Msys2Bash -lc "pacman -S --needed --noconfirm base-devel git vim"

    Write-Host "Installing mingw64 toolchain and clang..."
    & $Msys2Bash -lc "pacman -S --needed --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-clang"

    Write-Host "Installing extra mingw64 packages..."
    & $Msys2Bash -lc "pacman -S --needed --noconfirm mingw-w64-x86_64-cmake mingw-w64-x86_64-ninja mingw-w64-x86_64-python"

    Write-Host "MSYS2 environment setup complete!"
}

function Update-Script {
    if (-not (Check-Git)) {
        Write-Error "Git is not installed or not in PATH. Please install Git first."
        exit 1
    }

    Clone-Or-Pull-Repo

    Write-Host "Copying setup-things.ps1 to $ScriptDir"
    Copy-Item -Path (Join-Path $LocalRepoDir "setup-things.ps1") -Destination $ScriptDir -Force

    Write-Host "Update complete. Please rerun the updated script if needed."
}

switch ($Mode.ToLower()) {
    "-a" {
        Write-Host "Running all installations and updates..."

        Install-Package-Winget "clangd"
        Install-Package-Winget "python"
        Install-Package-Winget "OpenJS.NodeJS"
        Install-Package-Winget "Git.Git"
        Install-Package-Winget "NASM.NASM"
        Install-Package-Winget "nvim"

        Update-Neovim-Config

        Install-Or-Update-MSYS2

        break
    }
    "-n" {
        Write-Host "Updating Neovim config only..."
        Update-Neovim-Config
        break
    }
    "-u" {
        Write-Host "Updating this script from the remote repository..."
        Update-Script
        break
    }
    default {
        Write-Error "Unknown argument: $Mode"
        Write-Host "Usage: .\setup-things.ps1 [-a | -n | -u]"
        exit 1
    }
}

Write-Host "done."
exit 0
