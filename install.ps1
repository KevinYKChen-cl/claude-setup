# Install my Claude Code setup on this Windows machine. Safe to run again: finished parts are skipped.
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1 -TestRoot C:\temp\try   # install into a test folder instead
param([string]$TestRoot)

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

Step 'Global rules: ~/.claude/CLAUDE.md'
$claudeMd = Join-Path $ClaudeDir 'CLAUDE.md'
$source = Join-Path $Repo 'CLAUDE.md'
if ((Test-Path $claudeMd) -and ((Get-FileHash $claudeMd).Hash -eq (Get-FileHash $source).Hash)) {
    Write-Host 'already up to date'
} else {
    if (Test-Path $claudeMd) {
        $backup = "$claudeMd.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item $claudeMd $backup
        Write-Host "old file backed up to $backup"
    }
    Copy-Item $source $claudeMd -Force
    $Done += 'CLAUDE.md'
    Write-Host 'installed'
}

Step 'Skill: ticket-flow'
Copy-Folder (Join-Path $Repo 'skills\ticket-flow') (Join-Path $SkillsDir 'ticket-flow')
Write-Host 'installed'

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
    if (Test-Path $ScottyDir) { Remove-Item $ScottyDir -Recurse -Force }
    Native git clone -q --depth 1 --branch $ScottyTag https://github.com/brendan-appstart/bead-me-up-scotty.git $ScottyDir
    $head = (git -C $ScottyDir rev-parse HEAD).Trim()
    if ($head -ne $ScottyCommit) { throw "Scotty $ScottyTag is $head, expected $ScottyCommit" }
    Push-Location $ScottyDir
    try {
        Native npm ci --no-audit --no-fund
        Native npm run build
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

Step 'Done'
if ($Done) { Write-Host "Installed or updated: $($Done -join ', ')" } else { Write-Host 'Everything was already up to date.' }
if ($pathChanged) { Write-Host 'Open a new terminal so bd and scotty are found.' }
Write-Host 'Start a new Claude Code session to pick up the rules and skills. In a repo, type /ticket-flow.'
