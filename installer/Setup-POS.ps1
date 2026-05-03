<#
Installs the LAN hub bundle on Windows machine "A".

Prereqs (run separately):
   cd client ; flutter pub get ; flutter build windows

Parameters:
    -RepoRoot  Path containing client/, server/, installer/
    -Target    Deployment root (default C:\POS)

Notes:
  - Never overwrites an existing database: C:\POS\data\pos.db is only created by the server at runtime.
  - Robocopy excludes server\data from the payload; reinstalls keep the live DB.
#>

[CmdletBinding()]
param(
  [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
  [string]$Target = "C:\POS"
)

$ErrorActionPreference = "Stop"

function Write-Step($m) { Write-Host "[installer] $m" -ForegroundColor Cyan }

$serverSrc = Join-Path $RepoRoot "server"
$clientBuild = Join-Path $RepoRoot "client\build\windows\x64\runner\Release"

if (-not (Test-Path $serverSrc)) { throw "server/ missing at $serverSrc" }

Write-Step "Creating folders under $Target"
New-Item -ItemType Directory -Force -Path (Join-Path $Target "server") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target "client") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target "data") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target "backups") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target "logs") | Out-Null

Write-Step "Copying Node server bundle (server\data is excluded — will not touch $Target\data\pos.db)"
robocopy $serverSrc (Join-Path $Target "server") /MIR `
  /XF .env *.log `
  /XD node_modules logs data backups | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy(server) failed rc=$LASTEXITCODE" }

if (Test-Path $clientBuild) {
  Write-Step "Copying Flutter Windows Release build"
  robocopy $clientBuild (Join-Path $Target "client") /MIR | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy(client) failed rc=$LASTEXITCODE" }
} else {
  Write-Warning "Flutter Release build not found at $clientBuild — skip client payload"
}

$configDest = Join-Path $Target "config.json"
if (-not (Test-Path $configDest)) {
  Copy-Item (Join-Path $PSScriptRoot "config.sample.json") $configDest -Force
  Write-Step "Wrote $configDest — set required_token before production"
}

$serverWorking = Join-Path $Target "server"
Write-Step "npm install --omit=dev in $serverWorking"
Push-Location $serverWorking
try {
  npm install --omit=dev
} finally {
  Pop-Location
}

Write-Step "PM2 install (global) when missing"
$pm2 = Get-Command pm2 -ErrorAction SilentlyContinue
if (-not $pm2) {
  npm install -g pm2
}

Write-Step "PM2 start pos-server + save process list"
Push-Location $serverWorking
try {
  $env:POS_CONFIG_PATH = $configDest
  $env:NODE_ENV = "production"
  pm2 delete pos-server 2>$null | Out-Null
  pm2 start ecosystem.config.cjs
  pm2 save
} finally {
  Pop-Location
}

Write-Step @"
Done. From an Administrator PowerShell (once per machine), run:
  pm2 startup
Then re-run when shown:
  pm2 save

Launch `$Target\client\pos.exe` after setting LAN IP and the same Bearer token as in config.json → Flutter secure storage (`PosHubAuth.setBearerToken`).
"@
