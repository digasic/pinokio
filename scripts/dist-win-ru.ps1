# Production Windows RU build for digasic/pinokio.
# Rebuilds Electron natives, packs NSIS+portable, asserts afterPack gates.
#
# IMPORTANT: do NOT pass a standalone --config JSON that replaces package.json "build"
# (that drops extraResources/afterPack/nsis/files). Override only via -c.key=value.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File D:\devCursor\pinokio-ru\pinokio\scripts\dist-win-ru.ps1
#   powershell -ExecutionPolicy Bypass -File ...\dist-win-ru.ps1 -DirOnly

param(
  [switch]$DirOnly,
  [switch]$SkipRebuild
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "=== dist-win-ru @ $Root ==="
Write-Host "node=$(node -v) npm=$(npm -v)"

Get-Process -Name 'Pinokio' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

if (-not (Test-Path (Join-Path $Root 'node_modules\electron-builder'))) {
  throw 'electron-builder missing. Run: npm install (WITHOUT --ignore-scripts) in pinokio/'
}

if (-not $SkipRebuild) {
  Write-Host '=== patch node-pty SpectreMitigation (MSB8040) ==='
  & node.exe (Join-Path $Root 'scripts\patch-natives-gyp.js')

  Write-Host '=== electron-builder install-app-deps (Electron ABI natives) ==='
  & .\node_modules\.bin\electron-builder.cmd install-app-deps
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'WARN install-app-deps failed — re-patch vcxproj and retry'
    & node.exe (Join-Path $Root 'scripts\patch-natives-gyp.js')
    & .\node_modules\.bin\electron-builder.cmd install-app-deps
  }
  if ($LASTEXITCODE -ne 0) { throw "install-app-deps failed: $LASTEXITCODE" }

  $needles = @(
    'node_modules\pinokiod\node_modules\@homebridge\node-pty-prebuilt-multiarch\build\Release\conpty.node',
    'node_modules\@homebridge\node-pty-prebuilt-multiarch\build\Release\conpty.node',
    'node_modules\pinokiod\node_modules\better-sqlite3\build\Release\better_sqlite3.node',
    'node_modules\better-sqlite3\build\Release\better_sqlite3.node'
  )
  $foundPty = $false
  $foundSql = $false
  foreach ($n in $needles) {
    $p = Join-Path $Root $n
    if (Test-Path $p) {
      Write-Host "OK $n ($((Get-Item $p).Length) bytes)"
      if ($n -match 'conpty') { $foundPty = $true }
      if ($n -match 'better_sqlite3') { $foundSql = $true }
    }
  }
  if (-not $foundPty) { throw 'conpty.node missing after rebuild' }
  if (-not $foundSql) { throw 'better_sqlite3.node missing after rebuild' }
}

$out = Join-Path $Root 'dist-win-ru'
if (Test-Path $out) {
  Write-Host "Cleaning $out"
  Remove-Item -LiteralPath $out -Recurse -Force
}

Write-Host '=== ensure winCodeSign cache (no symlink priv) ==='
$seed = Join-Path $Root 'scripts\seed-wincodesign.ps1'
if (Test-Path $seed) {
  & powershell.exe -ExecutionPolicy Bypass -File $seed
}

# Merge overrides onto package.json build — never replace via --config file
$ebArgs = @(
  '--win', '--x64',
  '--publish', 'never',
  '-c.directories.output=dist-win-ru',
  '-c.win.signAndEditExecutable=false'
)
if ($DirOnly) { $ebArgs += '--dir' }

$env:CSC_IDENTITY_AUTO_DISCOVERY = 'false'

# Kill leftover OpenWith before build; monitor during build (yml/blockmap have no assoc → OpenWith)
Get-Process -Name 'OpenWith' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
$openWithLog = Join-Path $Root 'dist-win-ru-openwith-watch.log'
$watchScript = Join-Path $Root 'scripts\watch-openwith-during-build.ps1'
$watchProc = $null
if (Test-Path $watchScript) {
  $watchProc = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $watchScript, '-LogPath', $openWithLog
  ) -PassThru -WindowStyle Hidden
  Write-Host "OpenWith watchdog pid=$($watchProc.Id) log=$openWithLog"
}

$ebCmd = Join-Path $Root 'node_modules\.bin\electron-builder.cmd'
if (-not (Test-Path $ebCmd)) { throw "missing $ebCmd" }
Write-Host ("=== electron-builder " + ($ebArgs -join ' ') + " ===")
& $ebCmd @ebArgs
$ebCode = $LASTEXITCODE

if ($watchProc -and -not $watchProc.HasExited) {
  Stop-Process -Id $watchProc.Id -Force -ErrorAction SilentlyContinue
}
Get-Process -Name 'OpenWith' -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host "WARN OpenWith still alive after build pid=$($_.Id) — killing"
  Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
if (Test-Path $openWithLog) {
  $hits = Get-Content $openWithLog -ErrorAction SilentlyContinue
  if ($hits) {
    Write-Host '=== OpenWith during build (evidence) ==='
    $hits | ForEach-Object { Write-Host $_ }
  } else {
    Write-Host 'OK OpenWith watchdog: no hits during build'
  }
}

if ($ebCode -ne 0) { throw "electron-builder failed: $ebCode" }

$unpacked = Join-Path $out 'win-unpacked'
Write-Host '=== post-build smoke paths ==='
@(
  'Pinokio.exe',
  'resources\assets\icon_small.png',
  'resources\assets\icon.ico',
  'resources\app.asar',
  'resources\app.asar.unpacked'
) | ForEach-Object {
  $p = Join-Path $unpacked $_
  if (-not (Test-Path $p)) { throw "missing $p" }
  Write-Host "OK $_"
}

$conpty = Get-ChildItem (Join-Path $unpacked 'resources\app.asar.unpacked') -Recurse -Filter 'conpty.node' -ErrorAction SilentlyContinue |
  Select-Object -First 1
$sql = Get-ChildItem (Join-Path $unpacked 'resources\app.asar.unpacked') -Recurse -Filter 'better_sqlite3.node' -ErrorAction SilentlyContinue |
  Select-Object -First 1
if (-not $conpty) { throw 'packed build missing conpty.node' }
if (-not $sql) { throw 'packed build missing better_sqlite3.node' }
Write-Host "OK packed $($conpty.FullName)"
Write-Host "OK packed $($sql.FullName)"

$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $unpacked 'Pinokio.exe'))
if ($vi.ProductName -ne 'Pinokio' -or $vi.CompanyName -eq 'GitHub, Inc.') {
  throw "exe metadata still Electron defaults: Product=$($vi.ProductName) Company=$($vi.CompanyName)"
}
Write-Host "OK exe Product=$($vi.ProductName) Company=$($vi.CompanyName) Ver=$($vi.FileVersion)"

$asarMb = (Get-Item (Join-Path $unpacked 'resources\app.asar')).Length / 1MB
Write-Host ("OK app.asar {0:N1} MB" -f $asarMb)
if ($asarMb -gt 250) { throw "app.asar too large: $asarMb MB" }

# Also verify AUMID string in asar after pack
$asarCli = Join-Path $Root 'node_modules\@electron\asar\bin\asar.js'
$tmpMain = Join-Path $env:TEMP 'pinokio-dist-main-check.js'
Push-Location (Split-Path $tmpMain)
try {
  if (Test-Path '.\main.js') { Remove-Item '.\main.js' -Force }
  & node.exe $asarCli extract-file (Join-Path $unpacked 'resources\app.asar') main.js
  $mainTxt = Get-Content '.\main.js' -Raw
  if ($mainTxt -notmatch 'computer\.pinokio') { throw 'packed asar missing computer.pinokio AUMID' }
  if ($mainTxt -match "setAppUserModelId\('Pinokio'\)") { throw 'packed asar still has wrong AUMID Pinokio' }
  Write-Host 'OK asar AUMID computer.pinokio'
} finally {
  Pop-Location
}

Get-ChildItem $out -File | ForEach-Object {
  Write-Host ("ARTIFACT {0:N1} MB  {1}" -f ($_.Length/1MB), $_.Name)
}

Write-Host 'DONE dist-win-ru'
