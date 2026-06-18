# REGENT auto-sync: mirrors the working file into the repo and pushes to GitHub.
# Runs silently via a Windows Scheduled Task. Logs to sync.log.

$ErrorActionPreference = 'Stop'
$git    = 'C:\Program Files\Git\cmd\git.exe'
$repo   = 'C:\Users\TOBERU\Desktop\regent'
$source = 'C:\Users\TOBERU\Desktop\king\regent.html'   # your working file (edit this one)
$target = Join-Path $repo 'index.html'
$log    = Join-Path $repo 'sync.log'

function Log($m){ "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File $log -Append -Encoding utf8 }

try {
  Set-Location $repo

  # 1) Pull the latest working file into the repo (if it changed)
  if (Test-Path $source) {
    if (-not (Test-Path $target) -or
        (Get-FileHash $source).Hash -ne (Get-FileHash $target).Hash) {
      Copy-Item $source $target -Force
      Log "Updated index.html from working file."
    }
  }

  # 2) Commit + push only if something actually changed
  & $git add -A
  $status = & $git status --porcelain
  if ($status) {
    & $git commit -m "Auto-sync: update site $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-Null
    & $git push origin main 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Log "Pushed changes to GitHub." }
    else { Log "Push FAILED (exit $LASTEXITCODE) - check credentials." }
  }
}
catch { Log "ERROR: $($_.Exception.Message)" }
