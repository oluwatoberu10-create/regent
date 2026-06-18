# REGENT instant sync-on-save daemon.
# Watches the working file (and repo HTML) and runs sync.ps1 the moment they change.
# Launched hidden at logon by the scheduled task; debounces rapid saves.

$ErrorActionPreference = 'Continue'
$repo     = 'C:\Users\TOBERU\Desktop\regent'
$syncPath = Join-Path $repo 'sync.ps1'
$workDir  = 'C:\Users\TOBERU\Desktop\king'
$log      = Join-Path $repo 'sync.log'
function Log($m){ "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File $log -Append -Encoding utf8 }

# --- single-instance guard: never run two watchers at once ---
$mutex = New-Object System.Threading.Mutex($false, 'Global\REGENT_AutoSync_Watcher')
if (-not $mutex.WaitOne(0)) { exit }   # another watcher already running

Log "Watcher started (instant sync-on-save)."

# --- watch the working file ---
$w1 = New-Object IO.FileSystemWatcher $workDir, 'regent.html'
$w1.NotifyFilter = [IO.NotifyFilters]'LastWrite,Size,FileName'
$w1.IncludeSubdirectories = $false
$w1.EnableRaisingEvents = $true

# --- also watch the repo's HTML (in case index.html is edited directly) ---
$w2 = New-Object IO.FileSystemWatcher $repo, '*.html'
$w2.NotifyFilter = [IO.NotifyFilters]'LastWrite,Size,FileName'
$w2.IncludeSubdirectories = $false
$w2.EnableRaisingEvents = $true

$global:REGENT_pending = $false
$onChange = { $global:REGENT_pending = $true }
foreach ($w in @($w1, $w2)) {
  Register-ObjectEvent $w Changed -Action $onChange | Out-Null
  Register-ObjectEvent $w Created -Action $onChange | Out-Null
  Register-ObjectEvent $w Renamed -Action $onChange | Out-Null
}

# --- main loop: debounce, then sync ---
while ($true) {
  Start-Sleep -Milliseconds 600
  if ($global:REGENT_pending) {
    $global:REGENT_pending = $false
    Start-Sleep -Milliseconds 1200      # let a burst of saves settle
    $global:REGENT_pending = $false     # absorb events fired during the wait
    & $syncPath                         # one sync pass (copy + commit + push)
  }
}
