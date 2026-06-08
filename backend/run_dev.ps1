param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
$BackendDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $BackendDir
$EnvPath = Join-Path $BackendDir ".env"

if (Test-Path $EnvPath) {
    foreach ($rawLine in Get-Content $EnvPath) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) {
            continue
        }
        if ($line.StartsWith("export ")) {
            $line = $line.Substring(7).Trim()
        }
        $parts = $line.Split("=", 2)
        $key = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        if ($key) {
            Set-Item -Path "Env:$key" -Value $value
        }
    }
    Write-Host "Loaded backend/.env"
} else {
    Write-Host "backend/.env not found. Copy backend/.env.example to backend/.env to enable intraday NAV URLs."
}

Set-Location $RepoRoot
py -m uvicorn backend.app.main:app --reload --host $HostName --port $Port
