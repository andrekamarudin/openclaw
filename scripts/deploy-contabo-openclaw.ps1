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

function Get-SshResult {
	param([object]$Result)

	if ($Result -is [System.Array]) {
		return $Result[0]
	}

	return $Result
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

$localHead = (git -C $repoRoot rev-parse HEAD).Trim()
$originHead = (git -C $repoRoot rev-parse origin/master).Trim()

if ($localHead -ne $originHead) {
	throw 'Local HEAD does not match origin/master. Push your repo changes before deploying.'
}

$archivePath = Join-Path $env:TEMP ("my_openclaw-{0}.tar" -f $localHead)
$normalizedEnvPath = Join-Path $env:TEMP 'my_openclaw.env'
git -C $repoRoot archive --format=tar --output=$archivePath HEAD
[System.IO.File]::WriteAllText(
	$normalizedEnvPath,
	([System.IO.File]::ReadAllText($envPath) -replace "`r`n", "`n"),
	(New-Object System.Text.UTF8Encoding $false)
)

$securePassword = ConvertTo-SecureString $envMap['CONTABO_MY_SERVER_PASSWORD'] -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

$bootstrapScript = "set -euo pipefail; export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install -y ca-certificates curl git gettext-base; if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; systemctl enable --now docker; fi; mkdir -p '$remoteRootDir' /opt/src /root/.openclaw"

$session = $null

try {
	Write-Host "Connecting to $hostName ..."
	$session = New-SSHSession -ComputerName $hostName -Credential $credential -AcceptKey -ConnectionTimeout 20

	Write-Host 'Bootstrapping host packages and repo ...'
	$bootstrapResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $bootstrapScript -TimeOut 120000)
	if ($bootstrapResult.ExitStatus -ne 0) {
		throw ($bootstrapResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Uploading local .env to remote /opt/openclaw/.env ...'
	Set-SCPItem -ComputerName $hostName -Credential $credential -Path $normalizedEnvPath -Destination "$remoteRootDir/" -NewName '.env' -AcceptKey -Force

	Write-Host 'Uploading repo snapshot for the pushed origin/master commit ...'
	Set-SCPItem -ComputerName $hostName -Credential $credential -Path $archivePath -Destination '/tmp/' -NewName 'my_openclaw.tar' -AcceptKey -Force

	Write-Host 'Extracting repo snapshot and applying infra assets ...'
	$extractCommand = "rm -rf '$remoteRepoDir'; mkdir -p '$remoteRepoDir'; tar -xf /tmp/my_openclaw.tar -C '$remoteRepoDir'; rm -f /tmp/my_openclaw.tar"
	$extractResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $extractCommand -TimeOut 60000)
	if ($extractResult.ExitStatus -ne 0) {
		throw ($extractResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Running deploy from pushed repo snapshot + local .env ...'
	$deployCommand = "bash '$remoteRepoDir/infra_assets/scripts/apply-infra-assets.sh'; cd '$remoteRootDir'; docker compose pull openclaw-gateway; docker compose up -d --no-deps openclaw-gateway; chown -R 1000:1000 /root/.openclaw"
	$deployResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $deployCommand -TimeOut 180000)
	if ($deployResult.ExitStatus -ne 0) {
		throw ($deployResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Checking health on new VPS ...'
	$healthCommand = @'
bash -lc 'for attempt in $(seq 1 24); do
	if curl -sf http://127.0.0.1:18789/healthz; then
		exit 0
	fi
	sleep 5
done
exit 1'
'@
	$healthResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $healthCommand -TimeOut 130000)
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
	if (Test-Path $archivePath) {
		Remove-Item $archivePath -Force
	}
	if (Test-Path $normalizedEnvPath) {
		Remove-Item $normalizedEnvPath -Force
	}
	if ($session) {
		Remove-SSHSession -SSHSession $session | Out-Null
	}
}