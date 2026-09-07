$ErrorActionPreference = 'Continue'
# Capture WHO starts OpenWith over next 90s while we poke likely triggers
Write-Host '=== baseline kill ==='
Get-Process OpenWith -EA SilentlyContinue | Stop-Process -Force
Get-Process Pinokio -EA SilentlyContinue | Stop-Process -Force
Start-Sleep 1

# Reproduce runtime path: background mode toast+openExternal
$cfg = Join-Path $env:USERPROFILE '.pinokio\config.json'
$bak = "$cfg.bak-openwith-test"
Copy-Item $cfg $bak -Force
$j = Get-Content $cfg -Raw | ConvertFrom-Json
$prevMode = $j.mode
$j.mode = 'background'
($j | ConvertTo-Json -Depth 10) | Set-Content $cfg -Encoding UTF8
Write-Host "mode set background (was $prevMode)"

$exe = Join-Path $env:LOCALAPPDATA 'Programs\Pinokio\Pinokio.exe'
Write-Host "START $exe"
Start-Process $exe
Start-Sleep 8

$ows = Get-CimInstance Win32_Process -Filter "Name='OpenWith.exe'" -EA SilentlyContinue
Write-Host "OpenWith count=$(@($ows).Count)"
foreach ($o in @($ows)) {
  Write-Host "OW pid=$($o.ProcessId) cmd=$($o.CommandLine) parent=$($o.ParentProcessId)"
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($o.ParentProcessId)" -EA SilentlyContinue
  Write-Host "  parent name=$($p.Name) cmd=$($p.CommandLine)"
}

# Also check Pinokio children
Get-CimInstance Win32_Process -EA SilentlyContinue |
  Where-Object { $_.ParentProcessId -in @(Get-Process Pinokio -EA SilentlyContinue | Select-Object -ExpandProperty Id) } |
  ForEach-Object { Write-Host "child $($_.Name) $($_.CommandLine)" }

Get-Process OpenWith,Pinokio -EA SilentlyContinue | Stop-Process -Force
# restore mode
Copy-Item $bak $cfg -Force
Write-Host "restored mode from bak"
