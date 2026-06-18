# REGENT auto-sync: mirrors the working file into the repo and pushes to GitHub.
# Runs silently via a Windows Scheduled Task every 5 min. Logs to sync.log.

# NOTE: ErrorActionPreference stays at 'Continue' on purpose. git writes normal
# progress text to stderr; under 'Stop' that would be misreported as a failure.
$ErrorActionPreference = 'Continue'
$git    = 'C:\Program Files\Git\cmd\git.exe'
$repo   = 'C:\Users\TOBERU\Desktop\regent'
$source = 'C:\Users\TOBERU\Desktop\king\regent.html'   # your working file (edit this one)
$target = Join-Path $repo 'index.html'
$log    = Join-Path $repo 'sync.log'

function Log($m){ "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File $log -Append -Encoding utf8 }

# 1) Pull the latest working file into the repo (if it changed)
if (Test-Path $source) {
  if (-not (Test-Path $target) -or
      (Get-FileHash $source).Hash -ne (Get-FileHash $target).Hash) {
    Copy-Item $source $target -Force
    Log "Updated index.html from working file."
  }
}

# 2) Commit + push only if something actually changed
& $git -C $repo add -A | Out-Null
$status = & $git -C $repo status --porcelain
if ($status) {
  & $git -C $repo commit -m "Auto-sync: update site $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-Null
  $pushOutput = (& $git -C $repo push origin main 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -eq 0) {
    Log "Pushed changes to GitHub."
  } else {
    Log "Push FAILED (exit $LASTEXITCODE): $pushOutput"
  }
}
