# Runs every check and saves the output to build_logs\verify.log.
#   powershell -ExecutionPolicy Bypass -File tool\verify.ps1
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $root 'build_logs'
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir 'verify.log'
Set-Content -Path $log -Value "NetPulse verification $(Get-Date -Format s)" -Encoding utf8
$script:failed = @()

function Log($text) {
    Write-Host $text
    Add-Content -Path $log -Value $text -Encoding utf8
}

function Step($name, $dir, $command) {
    Log "`n=== $name ==="
    Push-Location (Join-Path $root $dir)
    cmd /c "$command 2>&1" | ForEach-Object { Log $_ }
    $code = $LASTEXITCODE
    Pop-Location
    Log "exit code: $code"
    if ($code -ne 0) { $script:failed += $name }
}

Step 'flutter version' '.' 'flutter --version'
Step 'pub get' '.' 'flutter pub get'
Step 'example pub get' 'example' 'flutter pub get'
Step 'analyze' '.' 'flutter analyze'
Step 'unit tests' '.' 'flutter test'
Step 'example tests' 'example' 'flutter test'
Step 'build Android' 'example' 'flutter build apk --debug'
Step 'Kotlin tests' 'example\android' 'gradlew.bat :netpulse_connectivity_sdk:testDebugUnitTest'
Step 'publish dry run' '.' 'dart pub publish --dry-run'

$summary = if ($script:failed.Count) { "FAILED: $($script:failed -join ', ')" } else { 'ALL STEPS PASSED' }
Log "`n$summary"
