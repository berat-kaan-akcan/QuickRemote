# setup_env.ps1
# This script adds necessary paths for QuickRemote project to the User PATH environment variable.

$pathsToAdd = @(
    "C:\Users\Berat_Kaan_Akcan\AppData\Local\Android\sdk\platform-tools",
    "C:\Users\Berat_Kaan_Akcan\Desktop\QuickRemote"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$isModified = $false

foreach ($path in $pathsToAdd) {
    if ($currentPath -notlike "*$path*") {
        Write-Host "Adding to PATH: $path"
        $currentPath = "$currentPath;$path"
        $isModified = $true
    } else {
        Write-Host "Already in PATH: $path"
    }
}

if ($isModified) {
    [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
    Write-Host "Environment variables updated successfully."
    Write-Host "UNKNOWN: You may need to restart your terminal or IDE for changes to take effect." -ForegroundColor Yellow
} else {
    Write-Host "No changes needed."
}

# Verify (This only checks the registry/future sessions, not the current one immediately for external commands)
Write-Host "`nCurrent User PATH:"
$newPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath -split ";" | ForEach-Object { if ($_ -in $pathsToAdd) { Write-Host "Verified: $_" -ForegroundColor Green } }
