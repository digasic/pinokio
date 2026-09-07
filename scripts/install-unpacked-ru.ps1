# Install digasic RU release.
# Prefer NSIS Setup (sets Start Menu AUMID=computer.pinokio). Fallback: copy win-unpacked.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File pinokio\scripts\install-unpacked-ru.ps1
#   powershell -ExecutionPolicy Bypass -File pinokio\scripts\install-unpacked-ru.ps1 -UnpackedOnly

param([switch]$UnpackedOnly)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Join-Path $Root 'dist-win-ru\win-unpacked'
$setup = Join-Path $Root 'dist-win-ru\Pinokio-RU-Setup.exe'
$dst = Join-Path $env:LOCALAPPDATA 'Programs\Pinokio'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

Write-Host '=== kill OpenWith / Pinokio ==='
Get-Process -Name 'OpenWith','Pinokio' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

if (-not $UnpackedOnly -and (Test-Path $setup)) {
  Write-Host "NSIS silent install: $setup"
  # electron-builder NSIS: /S silent, /D=dir must be last and without quotes quirks
  $p = Start-Process -FilePath $setup -ArgumentList @('/S', "/D=$dst") -Wait -PassThru
  if ($p.ExitCode -ne 0) {
    Write-Host "WARN NSIS exit=$($p.ExitCode) — fallback to unpacked copy"
  } else {
    $exe = Join-Path $dst 'Pinokio.exe'
    if (-not (Test-Path $exe)) { throw "NSIS finished but missing $exe" }
    $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
    Write-Host "Installed via NSIS Product=$($vi.ProductName) Ver=$($vi.FileVersion)"
    Write-Host "Shortcut expected under $startMenu (AUMID from appId computer.pinokio)"
    Write-Host 'DONE install-unpacked-ru (nsis)'
    exit 0
  }
}

if (-not (Test-Path (Join-Path $src 'Pinokio.exe'))) {
  throw "missing $src\Pinokio.exe — run scripts\dist-win-ru.ps1 first"
}

if (Test-Path $dst) {
  Write-Host "Removing $dst"
  Remove-Item -LiteralPath $dst -Recurse -Force
}
New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
Write-Host "Copy $src -> $dst"
Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force

$exe = Join-Path $dst 'Pinokio.exe'
$appIco = Join-Path $dst 'app.ico'
$ico = Join-Path $dst 'resources\assets\icon.ico'
if (Test-Path $ico) { Copy-Item $ico $appIco -Force }

$lnk = Join-Path $startMenu 'Pinokio.lnk'
$sh = New-Object -ComObject WScript.Shell
$sc = $sh.CreateShortcut($lnk)
$sc.TargetPath = $exe
$sc.WorkingDirectory = $dst
$sc.IconLocation = "$(if (Test-Path $appIco) { $appIco } else { $exe }),0"
$sc.Description = 'Pinokio (Russian UI)'
$sc.Save()
Write-Host 'WARN unpacked copy: Start .lnk may lack AUMID — use Setup.exe when possible'

$protoCmd = 'HKCU:\Software\Classes\pinokio\shell\open\command'
New-Item -Path $protoCmd -Force | Out-Null
Set-ItemProperty -Path $protoCmd -Name '(default)' -Value "`"$exe`" `"%1`""
Set-ItemProperty -Path 'HKCU:\Software\Classes\pinokio' -Name '(default)' -Value 'URL:pinokio' -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Classes\pinokio' -Name 'URL Protocol' -Value '' -ErrorAction SilentlyContinue

$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
Write-Host "Installed Product=$($vi.ProductName) Company=$($vi.CompanyName) Ver=$($vi.FileVersion)"
Write-Host 'DONE install-unpacked-ru (copy)'
