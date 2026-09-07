# Kill OpenWith spam + leftover Pinokio; no _tmp wrappers.
$ErrorActionPreference = 'Continue'
Get-Process -Name 'OpenWith','Pinokio' -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host "KILL $($_.ProcessName) pid=$($_.Id)"
  Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Write-Host 'done kill'
