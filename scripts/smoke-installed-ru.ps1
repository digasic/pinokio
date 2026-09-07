# Smoke installed Pinokio RU. Usage:
#   powershell -ExecutionPolicy Bypass -File pinokio\scripts\smoke-installed-ru.ps1

$ErrorActionPreference = 'Continue'
$exe = Join-Path $env:LOCALAPPDATA 'Programs\Pinokio\Pinokio.exe'
$log = 'C:\pinokio\logs\stdout.txt'
$url = 'http://127.0.0.1:42000/home?mode=settings'

if (-not (Test-Path $exe)) { throw "missing $exe" }

Get-Process -Name 'OpenWith','Pinokio' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
if (Test-Path $log) { Clear-Content $log -ErrorAction SilentlyContinue }

Write-Host "START $exe"
Start-Process -FilePath $exe

$html = $null
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Seconds 2
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
    $html = $r.Content
    if ($html.Length -gt 2000) { break }
  } catch {
    Write-Host "wait $i"
  }
}

if (-not $html) { throw 'HTTP never came up' }

$need = @('Мои приложения', 'Язык', 'Настройки', '__PINOKIO_I18N__')
$bad = @('ENVIRВКЛ', 'Could not locate the bindings', 'conpty.node', 'MODULE_NOT_FOUND')
foreach ($s in $need) {
  if ($html.Contains($s)) { Write-Host "OK HIT $s" } else { Write-Host "FAIL MISS $s" }
}
foreach ($s in $bad) {
  if ($html.Contains($s)) { Write-Host "FAIL BAD in html: $s" }
}

Write-Host '=== log errors ==='
if (Test-Path $log) {
  $errs = Select-String -Path $log -Pattern 'Could not locate the bindings|conpty\.node|MODULE_NOT_FOUND|better_sqlite3' -ErrorAction SilentlyContinue
  if ($errs) {
    $errs | Select-Object -Last 15 | ForEach-Object { Write-Host "ERR $($_.Line)" }
    throw 'natives still failing in stdout.txt'
  } else {
    Write-Host 'OK no sqlite/conpty errors in stdout.txt'
  }
} else {
  Write-Host 'WARN no stdout.txt yet'
}

$ow = Get-Process -Name OpenWith -ErrorAction SilentlyContinue
if ($ow) {
  Write-Host "FAIL OpenWith still running: $($ow.Id -join ',')"
  $ow | Stop-Process -Force
} else {
  Write-Host 'OK no OpenWith'
}

Write-Host 'DONE smoke-installed-ru'
