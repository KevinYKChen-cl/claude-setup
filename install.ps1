# Install my Claude Code setup on this Windows machine. Safe to run again: finished parts are skipped.
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1 -TestRoot C:\temp\try   # install into a test folder instead
#   -AllowUnmerged         install from a branch or uncommitted changes (testing a change on this machine)
#   -OverwriteLocalEdits   replace installed copies that were edited in place (they are backed up first)
param([string]$TestRoot, [switch]$AllowUnmerged, [switch]$OverwriteLocalEdits)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar on
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Versions. Change these to upgrade, then run the script again.
$PocockCommit = '4ae2317ddb22b046e26455e4f9c9b3aaaf62212d'   # mattpocock/skills, 2026-10-31
$PocockSkills = @(
    'engineering/setup-matt-pocock-skills', 'engineering/grill-with-docs', 'productivity/grilling',
    'engineering/domain-modeling', 'engineering/to-spec', 'engineering/to-tickets', 'engineering/implement-spec',
    'engineering/implement', 'engineering/tdd', 'engineering/code-review', 'engineering/codebase-design'
)
$BdVersion = '1.3.4'
$BdSha256 = 'e66e7b66c0d1ac6a878951462edddb4a177532aff3fc22989daac115feaaef11'   # beads_1.3.4_windows_amd64.zip
$ScottyTag = 'v0.4.0'
$ScottyCommit = 'cf6dda198db15a77399d1d9e77292618a7d08fa1'
$ArchifyVersion = '3.3.2'
$ArchifySha256 = '932d915f83fdbf44796cc6b20b085455a763491306e1b8dee92047e11dddc0ea'   # archify.zip of release v3.3.2

$Repo = $PSScriptRoot
if ($TestRoot) {
    $HomeDir = Join-Path $TestRoot 'home'
    $AppDir = Join-Path $TestRoot 'localappdata'
} else {
    $HomeDir = $HOME
    $AppDir = $env:LOCALAPPDATA
}
$ClaudeDir = Join-Path $HomeDir '.claude'
$SkillsDir = Join-Path $ClaudeDir 'skills'
$BinDir = Join-Path $HomeDir '.local\bin'
$ScottyDir = Join-Path $AppDir 'Programs\bead-me-up-scotty'
$Done = @()

function Step($text) { Write-Host ''; Write-Host "== $text" -ForegroundColor Cyan }

function Native {
    # Run a native command and stop on a non-zero exit code.
    $exe, $rest = $args
    & $exe @rest
    if ($LASTEXITCODE -ne 0) { throw "failed ($LASTEXITCODE): $($args -join ' ')" }
}

function New-TempDir {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ("claude-setup-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir | Out-Null
    $dir
}

function Copy-Folder($from, $to) {
    if (Test-Path $to) { Remove-Item $to -Recurse -Force }
    Copy-Item $from $to -Recurse
}

function Git-Out {
    # A git command's output in this repo, or $null when it fails.
    $ErrorActionPreference = 'Continue'   # Windows PowerShell turns a native command's stderr into an error under Stop
    $out = & git -C $Repo @args 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    ($out -join "`n").Trim()
}

function Test-Committed($file, $repoPath) {
    # True when the file's content was committed to this repo at some point (the same bytes git would store for
    # $repoPath). An installed copy always is; a copy edited in place is not.
    $blob = Git-Out hash-object "--path=$repoPath" $file
    if (-not $blob) { return $false }
    $ErrorActionPreference = 'Continue'
    & git -C $Repo cat-file -e $blob 2>$null
    $LASTEXITCODE -eq 0
}

Step 'Checking tools'
$missing = @()
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $missing += 'Git (winget install Git.Git)' }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    $missing += 'Node.js 20 or newer (winget install OpenJS.NodeJS.LTS)'
} elseif ([int]((node --version).TrimStart('v').Split('.')[0]) -lt 20) {
    $missing += "Node.js 20 or newer (found $(node --version); winget upgrade OpenJS.NodeJS.LTS)"
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { $missing += 'npm (comes with Node.js)' }
if ($missing) {
    Write-Host 'Missing tools. Install them, open a new terminal, and run this script again:' -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host 'Note: Claude Code (claude) is not on PATH. The setup still installs; install Claude Code to use it.' -ForegroundColor Yellow
}
New-Item -ItemType Directory -Force -Path $SkillsDir, $BinDir | Out-Null

Step 'This repo: only what is merged into main'
$branch = Git-Out rev-parse --abbrev-ref HEAD
$repoHead = Git-Out rev-parse HEAD
if (-not $repoHead) { throw "$Repo is not a git clone. Clone the repo (see README) and run install.ps1 from the clone." }
$dirty = Git-Out status --porcelain
$null = Git-Out fetch -q origin main
$originMain = Git-Out rev-parse origin/main
$problems = @()
if ($branch -ne 'main') { $problems += "on branch '$branch', not main" }
if ($dirty) { $problems += 'uncommitted changes:'; $problems += ($dirty -split "`n" | ForEach-Object { "    $_" }) }
if ($originMain -and $repoHead -ne $originMain -and $branch -eq 'main') { $problems += 'main is not the same as origin/main (git pull, or push first)' }
if ($problems) {
    if (-not $AllowUnmerged) {
        Write-Host 'Stopped: this installs only main as merged on GitHub, and this checkout is' -ForegroundColor Yellow
        $problems | ForEach-Object { Write-Host "  $_" }
        Write-Host 'Switch to main and git pull. To try a branch on this machine, run again with -AllowUnmerged.'
        exit 1
    }
    Write-Host 'Installing anyway (-AllowUnmerged):' -ForegroundColor Yellow
    $problems | ForEach-Object { Write-Host "  $_" }
}
Write-Host "commit $($repoHead.Substring(0, 7)) on $branch"

# What claude-setup installed last time on this machine: where the repo was and at which commit.
$recordFile = Join-Path $ClaudeDir 'claude-setup.json'
$record = $null
if (Test-Path $recordFile) { $record = Get-Content $recordFile -Raw | ConvertFrom-Json }
if ($record -and $record.commit -and $record.commit -ne $repoHead) {
    $stat = Git-Out diff --stat $record.commit $repoHead -- CLAUDE.md skills install.ps1
    if ($stat) {
        Write-Host "Changed since the last install ($($record.commit.Substring(0, 7))):"
        $stat -split "`n" | ForEach-Object { Write-Host "  $_" }
    } elseif ($null -eq $stat) {
        Write-Host "The last install was from commit $($record.commit.Substring(0, 7)), which this clone does not have."
    }
}

# The files this repo installs: the global rules and every folder in skills/.
$managed = @([pscustomobject]@{ Name = 'CLAUDE.md'; Source = (Join-Path $Repo 'CLAUDE.md'); Target = (Join-Path $ClaudeDir 'CLAUDE.md') })
foreach ($dir in Get-ChildItem (Join-Path $Repo 'skills') -Directory) {
    $managed += [pscustomobject]@{ Name = "skills/$($dir.Name)"; Source = $dir.FullName; Target = (Join-Path $SkillsDir $dir.Name) }
}

Step 'Installed copies edited in place'
# A copy in ~/.claude whose content was never committed here was edited there. Installing would replace it, so
# stop and say which, unless told to overwrite. Edits belong in this repo (AGENTS.md says how).
$edited = @()
foreach ($m in $managed) {
    if (-not (Test-Path $m.Target)) { continue }
    if ((Get-Item $m.Target).PSIsContainer) {
        foreach ($f in Get-ChildItem $m.Target -Recurse -File) {
            $rel = $f.FullName.Substring($m.Target.Length + 1) -replace '\\', '/'
            if (-not (Test-Committed $f.FullName "$($m.Name)/$rel")) { $edited += "$($m.Name)/$rel" }
        }
    } elseif (-not (Test-Committed $m.Target $m.Name)) {
        $edited += $m.Name
    }
}
if ($edited) {
    if (-not $OverwriteLocalEdits) {
        Write-Host 'Stopped: these installed files in ~/.claude differ from anything committed to this repo:' -ForegroundColor Yellow
        $edited | ForEach-Object { Write-Host "  $_" }
        Write-Host 'To keep an edit, make it in this repo (branch and PR, see AGENTS.md), then install again.'
        Write-Host 'To discard them, run again with -OverwriteLocalEdits; they are backed up first.'
        exit 1
    }
    $backupDir = Join-Path $ClaudeDir "backups\claude-setup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    foreach ($m in $managed) {
        if (Test-Path $m.Target) { Copy-Item $m.Target (Join-Path $backupDir ($m.Name -replace '/', '_')) -Recurse }
    }
    Write-Host "overwriting; the old copies are backed up in $backupDir" -ForegroundColor Yellow
} else {
    Write-Host 'none'
}

Step 'Global rules and skills from this repo'
foreach ($m in $managed) {
    if ((Get-Item $m.Source).PSIsContainer) {
        Copy-Folder $m.Source $m.Target
    } else {
        Copy-Item $m.Source $m.Target -Force
    }
    Write-Host "installed $($m.Name)"
}
$Done += ($managed | ForEach-Object { $_.Name }) -join ', '

Step "archify $ArchifyVersion (used by code-tour)"
$archifyDir = Join-Path $SkillsDir 'archify'
$archifySkill = Join-Path $archifyDir 'SKILL.md'
$archifyMarker = Join-Path $SkillsDir 'ARCHIFY_VERSION.txt'
$manualOnly = 'disable-model-invocation: true'
if ((Test-Path $archifySkill) -and (Test-Path $archifyMarker) -and
    (Select-String -Path $archifyMarker -SimpleMatch "archify $ArchifyVersion," -Quiet) -and
    (Select-String -Path $archifySkill -SimpleMatch $manualOnly -Quiet)) {
    Write-Host 'already installed'
} else {
    $tmp = New-TempDir
    try {
        $zip = Join-Path $tmp 'archify.zip'
        Invoke-WebRequest -UseBasicParsing -OutFile $zip `
            "https://github.com/tt-a1i/archify/releases/download/v$ArchifyVersion/archify.zip"
        $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        if ($hash -ne $ArchifySha256) { throw "archify download checksum mismatch: $hash" }
        Expand-Archive $zip (Join-Path $tmp 'out')
        Copy-Folder (Join-Path $tmp 'out\archify') $archifyDir
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Manual only: archify's long description stays out of every session's context and it never starts
    # on its own. code-tour reads its files and runs its CLI directly; /archify still works when typed.
    $text = [IO.File]::ReadAllText($archifySkill)
    if (-not $text.Contains($manualOnly)) {
        $text = ([regex]'(?m)^name: archify\r?$').Replace($text, "name: archify`n$manualOnly", 1)
        if (-not $text.Contains($manualOnly)) { throw "could not mark $archifySkill as manual only" }
        [IO.File]::WriteAllText($archifySkill, $text, (New-Object Text.UTF8Encoding $false))
    }
    Native node (Join-Path $archifyDir 'bin\archify.mjs') doctor
    Set-Content -Path $archifyMarker -Value "archify $ArchifyVersion, installed $(Get-Date -Format yyyy-MM-dd)" -Encoding ASCII
    $Done += "archify $ArchifyVersion"
    Write-Host 'installed, checksum OK, manual only'
}

Step "Pocock skills ($($PocockCommit.Substring(0, 7)))"
$pocockMarker = Join-Path $SkillsDir 'POCOCK_VERSION.txt'
$haveAll = -not ($PocockSkills | Where-Object { -not (Test-Path (Join-Path $SkillsDir (Split-Path $_ -Leaf))) })
if ($haveAll -and (Test-Path $pocockMarker) -and (Select-String -Path $pocockMarker -SimpleMatch $PocockCommit.Substring(0, 7) -Quiet)) {
    Write-Host 'already installed'
} else {
    $tmp = New-TempDir
    try {
        Native git clone -q https://github.com/mattpocock/skills.git (Join-Path $tmp 'skills')
        Native git -C (Join-Path $tmp 'skills') checkout -q $PocockCommit
        foreach ($skill in $PocockSkills) {
            Copy-Folder (Join-Path $tmp "skills\skills\$skill") (Join-Path $SkillsDir (Split-Path $skill -Leaf))
        }
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    Set-Content -Path $pocockMarker -Value "mattpocock/skills $PocockCommit, installed $(Get-Date -Format yyyy-MM-dd)" -Encoding ASCII
    $Done += "Pocock skills ($($PocockSkills.Count))"
    Write-Host "installed $($PocockSkills.Count) skills"
}

Step "beads: bd $BdVersion"
$bd = Join-Path $BinDir 'bd.exe'
if ((Test-Path $bd) -and ((& $bd version) -match "bd version $([regex]::Escape($BdVersion)) ")) {
    Write-Host 'already installed'
} else {
    $tmp = New-TempDir
    try {
        $zip = Join-Path $tmp 'beads.zip'
        Invoke-WebRequest -UseBasicParsing -OutFile $zip `
            "https://github.com/gastownhall/beads/releases/download/v$BdVersion/beads_${BdVersion}_windows_amd64.zip"
        $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        if ($hash -ne $BdSha256) { throw "bd download checksum mismatch: $hash" }
        Expand-Archive $zip (Join-Path $tmp 'out')
        Copy-Item (Join-Path $tmp 'out\bd.exe') $bd -Force
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    $Done += "bd $BdVersion"
    Write-Host "installed, checksum OK: $(& $bd version)"
}

Step "Scotty board $ScottyTag"
$scottyMarker = Join-Path $ScottyDir '.claude-setup-version'
$env:NEXT_TELEMETRY_DISABLED = '1'
if ((Test-Path $scottyMarker) -and ((Get-Content $scottyMarker) -eq $ScottyCommit)) {
    Write-Host 'already installed'
} else {
    # A running board holds files in this folder: deleting it would stop halfway and leave Scotty broken.
    $running = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -and $_.CommandLine -like "*$ScottyDir*" }
    if ($running) {
        throw "Scotty is running (PID $(($running | ForEach-Object { $_.ProcessId }) -join ', ')). Close the board, then run this script again."
    }
    if (Test-Path $ScottyDir) { Remove-Item $ScottyDir -Recurse -Force }
    Native git clone -q --depth 1 --branch $ScottyTag https://github.com/brendan-appstart/bead-me-up-scotty.git $ScottyDir
    $scottyHead = (git -C $ScottyDir rev-parse HEAD).Trim()
    if ($scottyHead -ne $ScottyCommit) { throw "Scotty $ScottyTag is $scottyHead, expected $ScottyCommit" }
    Push-Location $ScottyDir
    try {
        Native npm ci --no-audit --no-fund
        # Next.js refuses the first build of a version it lists as having a known security vulnerability, and
        # allows the same build again right after that reminder. Scotty $ScottyTag pins one (Next.js 16.4.1)
        # and has no newer release yet, so build again once and say so. Upgrade Scotty when it ships a fix.
        $log = Join-Path $ScottyDir 'claude-setup-build.log'
        cmd /c "npm run build > `"$log`" 2>&1"
        if ($LASTEXITCODE -ne 0 -and (Select-String -Path $log -SimpleMatch 'known security vulnerability' -Quiet)) {
            Write-Host "Warning: Next.js reports a known security vulnerability in the version Scotty $ScottyTag uses. Building again as Next.js allows; upgrade Scotty when a fixed release is out." -ForegroundColor Yellow
            cmd /c "npm run build > `"$log`" 2>&1"
        }
        if ($LASTEXITCODE -ne 0) { Get-Content $log -Tail 30; throw "Scotty build failed ($LASTEXITCODE); log: $log" }
    } finally {
        Pop-Location
    }
    # An empty POSTHOG_KEY turns Scotty's usage reporting off.
    Set-Content -Path (Join-Path $ScottyDir '.env') -Value "POSTHOG_KEY=`nNEXT_TELEMETRY_DISABLED=1" -Encoding ASCII
    Set-Content -Path $scottyMarker -Value $ScottyCommit -Encoding ASCII
    $Done += "Scotty $ScottyTag"
    Write-Host 'installed'
}
# The usage-statistics switch in Scotty's settings, kept off.
$scottyConfig = Join-Path $HomeDir '.config\bead-me-up-scotty'
New-Item -ItemType Directory -Force -Path $scottyConfig | Out-Null
Set-Content -Path (Join-Path $scottyConfig 'telemetry.json') -Value '{"enabled":false}' -NoNewline -Encoding ASCII
foreach ($file in 'scotty.cmd', 'scotty.ps1') { Copy-Item (Join-Path $Repo "bin\$file") (Join-Path $BinDir $file) -Force }
Write-Host 'telemetry off; scotty command in ~/.local/bin'

Step 'PATH'
$pathChanged = $false
if ($TestRoot) {
    Write-Host 'test install: PATH not changed'
} else {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -contains $BinDir) {
        Write-Host '~/.local/bin already on PATH'
    } else {
        [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';'), $BinDir) -join ';'), 'User')
        $pathChanged = $true
        Write-Host 'added ~/.local/bin to your user PATH'
    }
}

Step 'Record'
# Where this repo is on this machine and what it installed: the global rules tell agents to edit the repo,
# not the copies, and find it here.
$remote = Git-Out remote get-url origin
$recordJson = [ordered]@{
    repo        = $Repo
    remote      = $remote
    branch      = $branch
    commit      = $repoHead
    installedAt = (Get-Date -Format s)
    installs    = @($managed | ForEach-Object { $_.Name })
} | ConvertTo-Json
[IO.File]::WriteAllText($recordFile, $recordJson, (New-Object Text.UTF8Encoding $false))
Write-Host "wrote $recordFile"

Step 'Done'
if ($Done) { Write-Host "Installed or updated: $($Done -join ', ')" } else { Write-Host 'Everything was already up to date.' }
if ($pathChanged) { Write-Host 'Open a new terminal so bd and scotty are found.' }
Write-Host 'Start a new Claude Code session to pick up the rules and skills. In a repo, type /ticket-flow; to explain a repo or a change, type /code-tour.'
