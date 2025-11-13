param(
  [string]$VenvDir = "venv",
  [int]$AppPort = 5000
)

# ensure folders exist
if (-not (Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" | Out-Null }
if (-not (Test-Path "reports")) { New-Item -ItemType Directory -Path "reports" | Out-Null }

# Use venv python directly (avoids activate/ExecutionPolicy issues)
$venvPython = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
  Write-Host "ERROR: venv python not found at $venvPython"
  exit 1
}

# Start app and redirect stdout and stderr to separate files (PowerShell requires different targets)
$stdout = "logs\app_stdout.log"
$stderr = "logs\app_stderr.log"
$p = Start-Process -FilePath $venvPython -ArgumentList "app.py" -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr

# Write PID (use a file so cleanup can find it)
$p.Id | Out-File -FilePath app.pid -Encoding ascii

# Wait for health endpoint
$timeout = 15
$i = 0
while ($i -lt $timeout) {
  try {
    Invoke-RestMethod -UseBasicParsing -Uri ("http://127.0.0.1:{0}/health" -f $AppPort) -TimeoutSec 2
    Write-Host "App is up"
    break
  } catch {
    Start-Sleep -Seconds 1
    $i++
  }
}
if ($i -ge $timeout) {
  Write-Host "App failed to start within timeout. Dumping logs:"
  Write-Host "----- STDOUT -----"
  Get-Content $stdout -ErrorAction SilentlyContinue
  Write-Host "----- STDERR -----"
  Get-Content $stderr -ErrorAction SilentlyContinue
  exit 1
}
