param(
    [string]$EnvPath = "backend\.env",
    [switch]$NoEnvFile
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

function Import-DotEnv {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "Env file not found: $Path"
        Write-Host "Copy backend\.env.example to backend\.env to enable live intraday URLs."
        return
    }

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
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

    Write-Host "Loaded $Path"
}

if (-not $NoEnvFile) {
    Import-DotEnv -Path (Join-Path $RepoRoot $EnvPath)
}

py backend\scripts\smoke_00631l_live.py
exit $LASTEXITCODE
