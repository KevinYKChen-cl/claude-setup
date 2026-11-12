# Open the Scotty beads board at http://127.0.0.1:3197 (usage reporting off).
#   scotty           add the current repo (if it has .beads) to the board and open it
#   scotty <repo>    same for that repo
# Starts the server unless one is already running; Ctrl+C stops it.
param([string]$Repo)

$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:3197'
$app = Join-Path $env:LOCALAPPDATA 'Programs\bead-me-up-scotty'

function Test-Up {
    try { Invoke-RestMethod "$base/api/projects" -TimeoutSec 2 | Out-Null; $true } catch { $false }
}

if (-not $Repo -and (Test-Path '.beads')) { $Repo = (Get-Location).Path }
if ($Repo) { $Repo = (Resolve-Path $Repo).Path }

$server = $null
if (-not (Test-Up)) {
    $env:BD_BIN = Join-Path $HOME '.local\bin\bd.exe'
    $env:NEXT_TELEMETRY_DISABLED = '1'
    $next = Join-Path $app 'node_modules\next\dist\bin\next'
    $server = Start-Process node -ArgumentList "`"$next`"", 'start', '-H', '127.0.0.1', '-p', '3197' `
        -WorkingDirectory $app -NoNewWindow -PassThru
    for ($i = 0; -not (Test-Up); $i++) {
        if ($server.HasExited -or $i -ge 60) { throw 'Scotty did not start; is port 3197 in use?' }
        Start-Sleep -Milliseconds 500
    }
}

$url = $base
if ($Repo) {
    # Scotty only reads BEADS_REPO while it has no saved projects, so add the repo through its API.
    try {
        $project = Invoke-RestMethod "$base/api/projects" -Method Post -ContentType 'application/json' `
            -Body (@{ path = $Repo } | ConvertTo-Json)
        $url = "$base/p/$($project.id)"
    } catch {
        Write-Host "Could not add $Repo to the board (no .beads? run /ticket-flow there first)." -ForegroundColor Yellow
    }
}
Write-Host "Scotty: $url"
if ($server) {
    Write-Host 'Ctrl+C to stop.'
    $server.WaitForExit()
} else {
    Write-Host 'The server was already running in another terminal.'
}
