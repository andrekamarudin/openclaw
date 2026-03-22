Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module Posh-SSH

$repoRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $repoRoot '.env'

if (-not (Test-Path $envPath)) {
	throw "Missing .env at $envPath"
}

function Get-DotEnvMap {
	param([string]$Path)

	$map = @{}
	foreach ($line in Get-Content -Path $Path) {
		if ([string]::IsNullOrWhiteSpace($line)) { continue }
		if ($line.TrimStart().StartsWith('#')) { continue }
		$parts = $line -split '=', 2
		if ($parts.Count -ne 2) { continue }
		$map[$parts[0].Trim()] = $parts[1]
	}
	return $map
}

$envMap = Get-DotEnvMap -Path $envPath

$requiredKeys = @(
	'CONTABO_MY_SERVER_IP_ADDRESS',
	'CONTABO_MY_SERVER_PASSWORD',
	'OPENCLAW_REMOTE_SSH_USER',
	'OPENCLAW_REMOTE_ROOT_DIR',
	'OPENCLAW_REMOTE_REPO_DIR',
	'OPENCLAW_GATEWAY_TOKEN',
	'TELEGRAM_BOT_TOKEN'
)

foreach ($key in $requiredKeys) {
	if (-not $envMap.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($envMap[$key])) {
		throw "Missing required key in .env: $key"
	}
}

$hostName = $envMap['CONTABO_MY_SERVER_IP_ADDRESS']
$userName = $envMap['OPENCLAW_REMOTE_SSH_USER']
$remoteRootDir = $envMap['OPENCLAW_REMOTE_ROOT_DIR']
$remoteRepoDir = $envMap['OPENCLAW_REMOTE_REPO_DIR']

$securePassword = ConvertTo-SecureString $envMap['CONTABO_MY_SERVER_PASSWORD'] -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

$bootstrapScript = @"
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl git gettext-base

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
fi

mkdir -p '$remoteRootDir' /opt/src /root/.openclaw

if [ ! -d '$remoteRepoDir/.git' ]; then
  git clone https://github.com/andrekamarudin/my_openclaw.git '$remoteRepoDir'
else
  git -C '$remoteRepoDir' fetch origin
  git -C '$remoteRepoDir' reset --hard origin/master
fi
"@

$session = $null

try {
	Write-Host "Connecting to $hostName ..."
	$session = New-SSHSession -ComputerName $hostName -Credential $credential -AcceptKey -ConnectionTimeout 20

	Write-Host 'Bootstrapping host packages and repo ...'
	$bootstrapResult = Invoke-SSHCommand -SSHSession $session -Command $bootstrapScript -TimeOut 120000
	if ($bootstrapResult.ExitStatus -ne 0) {
		throw ($bootstrapResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Uploading local .env to remote /opt/openclaw/.env ...'
	Set-SCPItem -SSHSession $session -LocalFile $envPath -RemotePath "$remoteRootDir/.env"

	Write-Host 'Running deploy from GitHub repo + local .env ...'
	$deployCommand = "bash '$remoteRepoDir/infra_assets/scripts/deploy-openclaw.sh'"
	$deployResult = Invoke-SSHCommand -SSHSession $session -Command $deployCommand -TimeOut 180000
	if ($deployResult.ExitStatus -ne 0) {
		throw ($deployResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Checking health on new VPS ...'
	$healthResult = Invoke-SSHCommand -SSHSession $session -Command "curl -sf http://127.0.0.1:18789/healthz" -TimeOut 30000
	if ($healthResult.ExitStatus -ne 0) {
		throw 'New OpenClaw instance did not become healthy.'
	}

	Write-Host 'New OpenClaw instance is healthy. Stopping old OpenClaw on vikunja-prod to avoid Telegram bot duplication ...'
	ssh vikunja-prod "cd /opt/openclaw && docker compose stop openclaw-gateway openclaw-cli || true" | Out-Null

	Write-Host ''
	Write-Host 'Deployment complete.'
	Write-Host "OpenClaw is now running on $hostName with local .env and GitHub repo as the sources of truth."
}
finally {
	if ($session) {
		Remove-SSHSession -SSHSession $session | Out-Null
	}
}