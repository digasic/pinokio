param(
  [Parameter(Mandatory = $true)][string]$LogPath,
  [int]$PollMs = 2000
)
$ErrorActionPreference = 'Continue'
New-Item -ItemType File -Path $LogPath -Force | Out-Null
$seen = @{}
while ($true) {
  Start-Sleep -Milliseconds $PollMs
  Get-CimInstance Win32_Process -Filter "Name='OpenWith.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($seen.ContainsKey($_.ProcessId)) { return }
    $seen[$_.ProcessId] = $true
    $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($_.ParentProcessId)" -ErrorAction SilentlyContinue
    $line = "$(Get-Date -Format o) OpenWith pid=$($_.ProcessId) cmd=$($_.CommandLine) parent=$($_.ParentProcessId)/$($parent.Name) parentCmd=$($parent.CommandLine)"
    Add-Content -Path $LogPath -Value $line
    # Kill so build UI isn't blocked by modal dialogs
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
}
