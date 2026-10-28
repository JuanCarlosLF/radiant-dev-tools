[CmdletBinding()]
param(
    [string] $TempRoot = $env:RUNNER_TEMP
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$generator = Join-Path (Split-Path -Parent $scriptPath) 'write-distribution-manifest.ps1'
if ([string]::IsNullOrWhiteSpace($TempRoot)) { throw 'TempRoot must be supplied or RUNNER_TEMP must be set.' }
if (-not (Test-Path -LiteralPath $TempRoot -PathType Container)) { throw "TempRoot does not exist or is not a directory: $TempRoot" }
$root = Join-Path $TempRoot ('radiant-manifest-tests-' + [guid]::NewGuid().ToString('N'))

function Assert([bool] $Condition, [string] $Message) { if (-not $Condition) { throw "Assertion failed: $Message" } }
function ExpectFailure([scriptblock] $Action, [string] $Name) {
    try { & $Action; throw "Expected failure did not occur: $Name" } catch { if ($_.Exception.Message -notlike '*Manifest generation failed:*') { throw } }
}
function Invoke-Manifest([string] $Commit = ('a' * 40)) {
    & $generator -DistributionPath $root -CommitSha $Commit -Version '1.0-SNAPSHOT' -RequiredJavaMajor 24
}

try {
    New-Item -ItemType Directory -Path (Join-Path $root 'bin'), (Join-Path $root 'lib') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $root 'bin/radiant'), 'launcher')
    [IO.File]::WriteAllText((Join-Path $root 'bin/radiant.bat'), '@echo off')
    [IO.File]::WriteAllText((Join-Path $root 'lib/radiant-runtime.jar'), 'jar')
    [IO.File]::WriteAllText((Join-Path $root 'README.txt'), 'distribution')

    Invoke-Manifest
    $first = [IO.File]::ReadAllBytes((Join-Path $root 'manifest.json'))
    $document = Get-Content -LiteralPath (Join-Path $root 'manifest.json') -Raw | ConvertFrom-Json
    Assert ($document.schema_version -eq 1) 'schema version'
    Assert ($document.application -eq 'radiant') 'application'
    Assert ($document.commit_sha -eq ('a' * 40)) 'full lowercase commit'
    Assert ($document.required_java_major -eq 24) 'Java major'
    Assert ($document.files.Count -eq 4) 'inventory excludes only manifest.json'
    foreach ($file in $document.files) {
        $actual = Get-Item -LiteralPath (Join-Path $root $file.path)
        Assert ($file.size -eq $actual.Length) "size for $($file.path)"
        Assert ($file.sha256 -eq (Get-FileHash -LiteralPath $actual.FullName -Algorithm SHA256).Hash.ToLowerInvariant()) "hash for $($file.path)"
        Assert ($file.path -notmatch '\\|(^|/)\.\.(/|$)|^[A-Za-z]:|^/') "safe path for $($file.path)"
    }

    Invoke-Manifest
    $second = [IO.File]::ReadAllBytes((Join-Path $root 'manifest.json'))
    Assert ([Linq.Enumerable]::SequenceEqual($first, $second)) 'repeat generation is byte deterministic'

    ExpectFailure { Invoke-Manifest ([string]::new('a', 39)) } 'invalid commit'
    Remove-Item -LiteralPath (Join-Path $root 'bin/radiant.bat')
    ExpectFailure { Invoke-Manifest } 'missing launcher'
    [IO.File]::WriteAllText((Join-Path $root 'bin/radiant.bat'), '@echo off')

    $link = Join-Path $root 'unsafe-link'
    $symlinkCreated = $false
    try {
        New-Item -ItemType SymbolicLink -Path $link -Target (Join-Path $root 'lib') -ErrorAction Stop | Out-Null
        $symlinkCreated = $true
    } catch {
        $symlinkCreated = $false
    }
    if ($symlinkCreated) {
        ExpectFailure { Invoke-Manifest } 'reparse directory'
        Remove-Item -LiteralPath $link -Force
        Write-Output 'Reparse-point rejection: passed'
    } else {
        if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue }
        Write-Output 'Reparse-point rejection: skipped (symbolic links unavailable)'
    }
    Write-Output 'Manifest functional tests: passed'
} finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}
