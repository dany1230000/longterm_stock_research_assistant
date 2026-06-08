param(
    [string]$FlutterBin = "C:\src\flutter-clean\bin",
    [switch]$SkipSmoke
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
Set-Location $RepoRoot

if (Test-Path -LiteralPath $FlutterBin) {
    $env:PATH = "$FlutterBin;$env:PATH"
    Write-Host "Prepended Flutter SDK: $FlutterBin"
}
else {
    Write-Host "Flutter SDK path not found: $FlutterBin"
    Write-Host "Continuing with Flutter from PATH."
}

function Invoke-CheckedStep {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host ""
    Write-Host "== $Name =="
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Invoke-CheckedStep "flutter analyze" { flutter analyze }
Invoke-CheckedStep "flutter test" { flutter test }
Invoke-CheckedStep "flutter build web" { flutter build web }
Invoke-CheckedStep "backend tests" { py -m unittest discover -s backend\tests }

if (-not $SkipSmoke) {
    Invoke-CheckedStep "00631L live smoke" { & .\scripts\00631l_daily_smoke.ps1 }
}

Invoke-CheckedStep "git diff --check" { git diff --check }

Write-Host ""
Write-Host "00631L release validation finished."
