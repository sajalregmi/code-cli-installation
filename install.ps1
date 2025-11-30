#!/usr/bin/env pwsh

# Exit on error
$ErrorActionPreference = "Stop"

$EXE_NAME = "arkios-code.exe"

# Detect OS
$OS_TYPE = if ($IsWindows -or $env:OS -match "Windows") { "Windows" }
           elseif ($IsMacOS) { "Darwin" }
           elseif ($IsLinux) { "Linux" }
           else { "Unknown" }

Write-Host "Detected OS: $OS_TYPE"

# Set installation directory
if ($OS_TYPE -eq "Windows") {
    $INSTALL_DIR = Join-Path $HOME ".arkios\code\bin"
} else {
    Write-Host "Error: This is the Windows installer. Use install.sh for macOS/Linux."
    exit 1
}

# Set download URL - Windows binary
$DOWNLOAD_URL = "https://storage.googleapis.com/executable-arkios/Arkios-Code-Windows/arkios-code-windows.exe"

$INSTALL_PATH = Join-Path $INSTALL_DIR $EXE_NAME

# Create installation directory if it doesn't exist
Write-Host "Ensuring installation directory exists..."
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

# Download the binary
Write-Host "Downloading $EXE_NAME..."
$TMP_FILE = Join-Path $env:TEMP $EXE_NAME

try {
    # Use Invoke-WebRequest (curl alias in PowerShell)
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TMP_FILE -UseBasicParsing
} catch {
    Write-Host "Error: Download failed - $_"
    exit 1
}

# Install the binary
Write-Host "Installing to $INSTALL_PATH..."
Copy-Item -Path $TMP_FILE -Destination $INSTALL_PATH -Force
Remove-Item -Path $TMP_FILE -Force

# No need for chmod on Windows - .exe files are executable by default

Write-Host ""
Write-Host "Installation complete!"
Write-Host "Arkios Code installed to $INSTALL_PATH"
Write-Host ""

# PATH configuration
Write-Host "Configuring PATH..."

# Get current user PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Check if already in PATH
if ($currentPath -like "*$INSTALL_DIR*") {
    Write-Host "  PATH already configured"
    Write-Host ""
    Write-Host "Run 'arkios-code' to get started!"
} else {
    # Add to user PATH (no admin rights required)
    $newPath = "$INSTALL_DIR;$currentPath"

    try {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "Added to user PATH"
        Write-Host ""
        Write-Host "PATH configured successfully!"
        Write-Host ""
        Write-Host "To use arkios-code in this terminal session, run:"
        Write-Host "  `$env:Path = `"$INSTALL_DIR;`$env:Path`""
        Write-Host ""
        Write-Host "Or open a new terminal and run: arkios-code"
    } catch {
        Write-Host "Warning: Cannot update PATH - $_"
        Write-Host ""
        Write-Host "Please add manually:"
        Write-Host "  1. Open System Properties > Environment Variables"
        Write-Host "  2. Add to User PATH: $INSTALL_DIR"
    }
}

