# Audit final release artifacts vs source fixes
$ErrorActionPreference = 'Stop'
$Root = 'D:\devCursor\pinokio-ru\pinokio'
$Out = Join-Path $Root 'dist-win-ru'
$Unpacked = Join-Path $Out 'win-unpacked'
$AsarCli = Join-Path $Root 'node_modules\@electron\asar\bin\asar.js'
$Work = Join-Path $env:TEMP 'pinokio-release-audit'
$Asar = Join-Path $Unpacked 'resources\app.asar'

Write-Host '=== artifacts ==='
Get-ChildItem $Out -File -ErrorAction SilentlyContinue | ForEach-Object {
  '{0:N1} MB  {1}  {2}' -f ($_.Length/1MB), $_.LastWriteTime.ToString('s'), $_.Name
}

Write-Host '=== unpacked gates ==='
foreach ($c in @('Pinokio.exe','resources\assets\icon_small.png','resources\assets\icon.ico','resources\app.asar','resources\app.asar.unpacked')) {
  $p = Join-Path $Unpacked $c
  if (Test-Path $p) { Write-Host "OK $c ($((Get-Item $p).Length))" } else { Write-Host "FAIL missing $c" }
}

$conpty = Get-ChildItem (Join-Path $Unpacked 'resources\app.asar.unpacked') -Recurse -Filter 'conpty.node' -EA SilentlyContinue | Select-Object -First 1
$sql = Get-ChildItem (Join-Path $Unpacked 'resources\app.asar.unpacked') -Recurse -Filter 'better_sqlite3.node' -EA SilentlyContinue | Select-Object -First 1
if ($conpty) { Write-Host "OK conpty" } else { Write-Host 'FAIL conpty' }
if ($sql) { Write-Host "OK sqlite" } else { Write-Host 'FAIL sqlite' }

$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $Unpacked 'Pinokio.exe'))
Write-Host "exe Product=$($vi.ProductName) Company=$($vi.CompanyName) Ver=$($vi.FileVersion)"

if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force -Path $Work | Out-Null
Set-Location $Work
& node.exe $AsarCli extract-file $Asar main.js
$main = Get-Content (Join-Path $Work 'main.js') -Raw
$src = Get-Content (Join-Path $Root 'main.js') -Raw

Write-Host '=== AUMID ==='
if ($src -match 'computer\.pinokio') { Write-Host 'OK source has computer.pinokio' } else { Write-Host 'FAIL source missing AUMID' }
if ($main -match 'computer\.pinokio') { Write-Host 'OK release asar has computer.pinokio' } else { Write-Host 'FAIL release asar STALE — no AUMID fix' }
if ($main -match "setAppUserModelId\('Pinokio'\)") { Write-Host 'FAIL release still setAppUserModelId(Pinokio)' }

Write-Host ("asarMB={0:N1}" -f ((Get-Item $Asar).Length/1MB))
Write-Host ("pkgVer=" + (Get-Content (Join-Path $Root 'package.json') -Raw | ConvertFrom-Json).version)
