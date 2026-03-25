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
	'OPENCLAW_REMOTE_REPO_DIR'
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
$remoteInfisicalDir = '/opt/infisical'

$archivePath = Join-Path $env:TEMP 'my_openclaw-infisical.tar'

if (Test-Path $archivePath) {
	Remove-Item $archivePath -Force
}

Push-Location $repoRoot
try {
	tar.exe --exclude=.git --exclude=.venv --exclude=__pycache__ --exclude=.env -cf $archivePath .
}
finally {
	Pop-Location
}

$securePassword = ConvertTo-SecureString $envMap['CONTABO_MY_SERVER_PASSWORD'] -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

$bootstrapScript = "set -euo pipefail; export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install -y ca-certificates curl git gettext-base certbot python3-certbot-nginx; if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; systemctl enable --now docker; fi; mkdir -p '$remoteRootDir' '$remoteInfisicalDir' /opt/src"

$session = $null

try {
	Write-Host "Connecting to $hostName ..."
	$session = New-SSHSession -ComputerName $hostName -Credential $credential -AcceptKey -ConnectionTimeout 20

	Write-Host 'Bootstrapping host packages and directories ...'
	$bootstrapResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $bootstrapScript -TimeOut 120000)
	if ($bootstrapResult.ExitStatus -ne 0) {
		throw ($bootstrapResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Uploading working tree snapshot ...'
	Set-SCPItem -ComputerName $hostName -Credential $credential -Path $archivePath -Destination '/tmp/' -NewName 'my_openclaw-infisical.tar' -AcceptKey -Force

	Write-Host 'Extracting working tree snapshot on Contabo ...'
	$extractCommand = "rm -rf '$remoteRepoDir'; mkdir -p '$remoteRepoDir'; tar -xf /tmp/my_openclaw-infisical.tar -C '$remoteRepoDir'; rm -f /tmp/my_openclaw-infisical.tar"
	$extractResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $extractCommand -TimeOut 120000)
	if ($extractResult.ExitStatus -ne 0) {
		throw ($extractResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Deploying Infisical ...'
	$deployCommand = "bash '$remoteRepoDir/infra_assets/scripts/deploy-infisical.sh'"
	$deployResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $deployCommand -TimeOut 300000)
	if ($deployResult.ExitStatus -ne 0) {
		throw ($deployResult.Output -join [Environment]::NewLine)
	}

	Write-Host 'Checking Infisical backend health ...'
	$healthCommand = @'
bash -lc 'set -a; . "{0}/.env"; set +a; PORT=${{INFISICAL_BIND_PORT:-8081}}; for attempt in $(seq 1 30); do if curl -sf "http://127.0.0.1:$PORT/api/status"; then exit 0; fi; sleep 5; done; exit 1'
'@ -f $remoteRootDir
	$healthResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $healthCommand -TimeOut 180000)
	if ($healthResult.ExitStatus -ne 0) {
		throw 'Infisical backend did not become healthy in time.'
	}

	Write-Host 'Checking public HTTPS endpoint ...'
	$httpsCommand = "curl -skI https://$($envMap['INFISICAL_DOMAIN'])"
	$httpsResult = Get-SshResult (Invoke-SSHCommand -SSHSession $session -Command $httpsCommand -TimeOut 30000)
	if ($httpsResult.ExitStatus -ne 0) {
		Write-Host 'WARNING: HTTPS check failed. The backend is up, but nginx/certbot may still need attention.'
	}

	Write-Host ''
	Write-Host 'Deployment complete.'
	Write-Host "Infisical should now be reachable at $($envMap['INFISICAL_SITE_URL'])."
}
finally {
	if (Test-Path $archivePath) {
		Remove-Item $archivePath -Force
	}
	if ($session) {
		Remove-SSHSession -SSHSession $session | Out-Null
	}
}