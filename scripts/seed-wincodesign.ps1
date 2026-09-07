# Seed electron-builder winCodeSign-2.6.0 cache without requiring symlink privilege.
$ErrorActionPreference = 'Continue'
$cacheRoot = Join-Path $env:LOCALAPPDATA 'electron-builder\Cache\winCodeSign'
$url = 'https://github.com/electron-userland/electron-builder-binaries/releases/download/winCodeSign-2.6.0/winCodeSign-2.6.0.7z'
$zip = Join-Path $cacheRoot 'winCodeSign-2.6.0.7z'
$dest = Join-Path $cacheRoot 'winCodeSign-2.6.0'
$sevenCandidates = @(
  (Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'node_modules\7zip-bin\win\x64\7za.exe'),
  (Join-Path $PSScriptRoot '..\node_modules\7zip-bin\win\x64\7za.exe')
)
$seven = $sevenCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $seven) { throw '7za.exe not found' }

New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
$needDownload = -not (Test-Path $zip) -or ((Get-Item $zip).Length -lt 1000)
if ($needDownload) {
  curl.exe -L --fail -o $zip $url
  if ($LASTEXITCODE -ne 0) { throw 'winCodeSign download failed' }
}

$rceditOk = Test-Path (Join-Path $dest 'rcedit-x64.exe')
if (-not $rceditOk) {
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  & $seven x -bd "-o$dest" $zip | Out-Host
  $darwinLib = Join-Path $dest 'darwin\10.12\lib'
  New-Item -ItemType Directory -Force -Path $darwinLib | Out-Null
  foreach ($n in @('libcrypto.dylib', 'libssl.dylib')) {
    $p = Join-Path $darwinLib $n
    if (-not (Test-Path $p)) { [IO.File]::WriteAllBytes($p, [byte[]]@()) }
  }
}

if (-not (Test-Path (Join-Path $dest 'rcedit-x64.exe'))) {
  throw "winCodeSign seed incomplete: $dest"
}
Write-Host "winCodeSign ready: $dest"
