[CmdletBinding()]
param([string] $TempRoot = $env:RUNNER_TEMP)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($TempRoot) -or -not (Test-Path -LiteralPath $TempRoot -PathType Container)) { throw 'TempRoot must be supplied or RUNNER_TEMP must name an existing directory.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$scripts = Split-Path -Parent $MyInvocation.MyCommand.Path
$updater = Join-Path (Split-Path -Parent $scripts) 'update-radiant.ps1'
$installer = Join-Path (Split-Path -Parent $scripts) 'install-radiant.ps1'
$generator = Join-Path (Split-Path -Parent $scripts) 'write-distribution-manifest.ps1'
$repo = Split-Path -Parent (Split-Path -Parent $scripts)
$source = Join-Path $repo 'build/install/radiant'
if (-not (Test-Path -LiteralPath (Join-Path $source 'bin/radiant.bat') -PathType Leaf)) { throw 'Run installDist before the updater tests.' }

$root = Join-Path $TempRoot ('radiant-updater-tests-' + [guid]::NewGuid().ToString('N'))
$currentSha = 'c' * 40
$newSha = 'a' * 40
$repositoryId = 424242
$oldOutput = $env:RADIANT_TEST_OUTPUT
$oldMockRoot = $env:RADIANT_MOCK_ROOT
$oldMockMode = $env:RADIANT_MOCK_MODE

function Assert([bool] $Condition, [string] $Message) { if (-not $Condition) { throw "Assertion failed: $Message" } }
function Invoke-Manifest([string] $Distribution, [string] $Commit) {
    & $generator -DistributionPath $Distribution -CommitSha $Commit -Version '1.0-SNAPSHOT' -RequiredJavaMajor 24 | Out-Null
}
function Copy-Tree([string] $Name) {
    $destination = Join-Path $root $Name
    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
    return $destination
}
function Write-RunDocument([string] $Path, [string] $Sha, [string] $Repository = 'JuanCarlosLF/radiant-dev-tools', [string] $Event = 'push', [string] $Branch = 'develop', [string] $WorkflowPath = '.github/workflows/ci-distribution.yml', [string] $Conclusion = 'success') {
    $run = [ordered]@{
        database_id = 200
        id = 200
        path = $WorkflowPath
        event = $Event
        head_branch = $Branch
        status = 'completed'
        conclusion = $Conclusion
        head_sha = $Sha
        created_at = '2026-10-29T13:00:00Z'
        head_repository = @{ id = $repositoryId; full_name = $Repository }
        run_number = 200
    }
    @{ workflow_runs = @($run) } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -NoNewline
}
function Write-RunPair([string] $Path) {
    $current = [ordered]@{ id = 199; path = '.github/workflows/ci-distribution.yml'; event = 'push'; head_branch = 'develop'; status = 'completed'; conclusion = 'success'; head_sha = $currentSha; created_at = '2026-10-29T12:00:00Z'; head_repository = @{ id = $repositoryId; full_name = 'JuanCarlosLF/radiant-dev-tools' }; run_number = 199 }
    $new = [ordered]@{ id = 200; path = '.github/workflows/ci-distribution.yml'; event = 'push'; head_branch = 'develop'; status = 'completed'; conclusion = 'success'; head_sha = $newSha; created_at = '2026-10-29T13:00:00Z'; head_repository = @{ id = $repositoryId; full_name = 'JuanCarlosLF/radiant-dev-tools' }; run_number = 200 }
    @{ workflow_runs = @($new, $current) } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -NoNewline
}
function Write-ArtifactDocument([string] $Path, [string] $Sha, [bool] $Expired = $false, [string] $Name = 'radiant-dev', [int] $RunId = 200) {
    $artifact = [ordered]@{
        id = 300
        name = $Name
        expired = $Expired
        size_in_bytes = 1
        workflow_run = @{ id = $RunId; repository_id = $repositoryId; head_repository_id = $repositoryId; head_sha = $Sha }
    }
    @{ artifacts = @($artifact) } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -NoNewline
}
function Write-MockGh {
    $mock = Join-Path $root 'mock-gh.ps1'
    @'
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Arguments)
$root = $env:RADIANT_MOCK_ROOT
if ($env:RADIANT_MOCK_MODE -eq 'timeout') { Start-Sleep -Seconds 3; exit 1 }
$repoId = 424242
$unknown = @($Arguments | Where-Object { $_ -like '--*' })
if ($unknown.Count -gt 0) { exit 9 }
$endpoint = @($Arguments | Where-Object { $_ -like 'repos/*' })[0]
if ($endpoint -eq 'repos/JuanCarlosLF/radiant-dev-tools') { '{"id":424242,"full_name":"JuanCarlosLF/radiant-dev-tools"}'; exit 0 }
if ($endpoint -like '*head_sha=*') { Get-Content -LiteralPath (Join-Path $root 'active-runs.json') -Raw; exit 0 }
if ($endpoint -like '*/actions/workflows/*/runs*') { Get-Content -LiteralPath (Join-Path $root 'runs.json') -Raw; exit 0 }
if ($endpoint -like '*/actions/runs/*/artifacts*') { Get-Content -LiteralPath (Join-Path $root 'artifacts.json') -Raw; exit 0 }
if ($endpoint -like '*/actions/artifacts/*/zip') {
    $bytes = [IO.File]::ReadAllBytes((Join-Path $root 'artifact.zip'))
    $stream = [Console]::OpenStandardOutput(); $stream.Write($bytes, 0, $bytes.Length); $stream.Flush(); $stream.Dispose()
    exit 0
}
exit 3
'@ | Set-Content -LiteralPath $mock -NoNewline
    return $mock
}
function Run-Updater([string] $Install, [string] $Gh, [int] $Timeout = 5) {
    & $updater -InstallRoot $Install -CurrentCommit (Pointer $Install) -GhPath $Gh -TimeoutSeconds $Timeout 2>$null | Out-Null
}
function Pointer([string] $Install) { return (Get-Content -LiteralPath (Join-Path $Install 'active.txt') -TotalCount 1) }
function Create-Zip([string] $Distribution, [string] $ZipPath) { if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }; Compress-Archive -Path (Join-Path $Distribution '*') -DestinationPath $ZipPath -Force }
function Create-UnsafeZip([string] $ZipPath, [string] $EntryName) {
    if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
    $archive = [IO.Compression.ZipFile]::Open($ZipPath, [IO.Compression.ZipArchiveMode]::Create)
    try { $entry = $archive.CreateEntry($EntryName); $writer = New-Object IO.StreamWriter($entry.Open()); $writer.Write('unsafe'); $writer.Dispose() } finally { $archive.Dispose() }
}
function Create-CollisionZip([string] $ZipPath) {
    if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
    $archive = [IO.Compression.ZipFile]::Open($ZipPath, [IO.Compression.ZipArchiveMode]::Create)
    try { foreach ($name in @('bin/file.txt', 'BIN/file.txt')) { $entry = $archive.CreateEntry($name); $writer = New-Object IO.StreamWriter($entry.Open()); $writer.Write('collision'); $writer.Dispose() } } finally { $archive.Dispose() }
}
function Reset-Mock([string] $Sha = $newSha) {
    $env:RADIANT_MOCK_MODE = ''
    Write-RunDocument (Join-Path $root 'runs.json') $Sha
    Write-RunDocument (Join-Path $root 'active-runs.json') $currentSha
    Write-ArtifactDocument (Join-Path $root 'artifacts.json') $Sha
}
function CaseValue([hashtable] $Case, [string] $Name, [string] $Default) { if ($Case.ContainsKey($Name)) { return [string]$Case[$Name] }; return $Default }
function Assert-Preserved([string] $Install, [string] $Expected) { Assert ((Pointer $Install) -ceq $Expected) "active pointer changed unexpectedly from $Expected to $(Pointer $Install)" }
function Assert-OldCli([string] $Install) {
    $env:RADIANT_TEST_OUTPUT = Join-Path $root 'old-cli-output.txt'
    Remove-Item -LiteralPath $env:RADIANT_TEST_OUTPUT -Force -ErrorAction SilentlyContinue
    & (Join-Path $Install 'bin/radiant.cmd') | Out-Null
    $captured = @(Get-Content -LiteralPath $env:RADIANT_TEST_OUTPUT)
    Assert ($captured.Count -gt 0 -and $captured[0] -like 'OLD-CWD=*') 'the previous CLI remained runnable after the failed update'
}

try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $mock = Write-MockGh
    $current = Copy-Tree 'current'
    $env:RADIANT_TEST_OUTPUT = Join-Path $root 'child-output.txt'
    @('@echo off', 'setlocal DisableDelayedExpansion', '>%RADIANT_TEST_OUTPUT% (', ' echo OLD-CWD=[%CD%]', ' echo ARG1=[%~1]', ' echo ARG2=[%~2]', ' echo ARG3=[%~3]', ')', 'exit /b 7') | Set-Content -LiteralPath (Join-Path $current 'bin/radiant.bat')
    Invoke-Manifest $current $currentSha
    $install = Join-Path $root 'install'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $install | Out-Null
    [IO.File]::WriteAllText((Join-Path $install 'bin/radiant.cmd'), 'legacy launcher')
    $bootstrapFailed = $false
    try { & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $install | Out-Null } catch { $bootstrapFailed = $true }
    Assert $bootstrapFailed 'legacy stable launcher requires explicit bootstrap permission'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $install -AllowStableLauncherUpgrade | Out-Null
    $new = Copy-Tree 'new'
    @('@echo off', 'setlocal DisableDelayedExpansion', '>%RADIANT_TEST_OUTPUT% (', ' echo UPDATED-CWD=[%CD%]', ' echo UPDATED-ARG1=[%~1]', ' echo UPDATED-ARG2=[%~2]', ' echo UPDATED-ARG3=[%~3]', ')', 'exit /b 7') | Set-Content -LiteralPath (Join-Path $new 'bin/radiant.bat')
    Set-Content -LiteralPath (Join-Path $new 'runtime/binary-proof.txt') -Value 'binary payload survived stdout capture' -NoNewline
    $injectionMarker = Join-Path $root 'downloaded-installer-executed.txt'
    Add-Content -LiteralPath (Join-Path $new 'runtime/install-radiant.ps1') -Value "`nSet-Content -LiteralPath '$injectionMarker' -Value 'executed'`n"
    Invoke-Manifest $new $newSha
    Create-Zip $new (Join-Path $root 'artifact.zip')
    Write-RunPair (Join-Path $root 'runs.json')
    Write-ArtifactDocument (Join-Path $root 'artifacts.json') $newSha
    $env:RADIANT_MOCK_ROOT = $root

    Run-Updater $install $mock
    Assert-Preserved $install $newSha
    Assert ((Get-Content -LiteralPath (Join-Path $install "versions/$newSha/runtime/binary-proof.txt") -Raw) -ceq 'binary payload survived stdout capture') 'binary artifact payload was preserved'
    Assert (-not (Test-Path -LiteralPath $injectionMarker)) 'the downloaded installer was never executed'
    $caller = New-Item -ItemType Directory -Path (Join-Path $root 'caller') -Force
    Push-Location $caller.FullName
    try { & (Join-Path $install 'bin/radiant.cmd') 'quoted argument' 'second argument' 'bang! value'; $exitCode = $LASTEXITCODE } finally { Pop-Location }
    Assert ($exitCode -eq 7) 'stable launcher preserved the new child exit code'
    $captured = @(Get-Content -LiteralPath $env:RADIANT_TEST_OUTPUT)
    Assert ($captured[0] -ceq "UPDATED-CWD=[$($caller.FullName)]") 'updated child received caller CWD'
    Assert ($captured[1] -ceq 'UPDATED-ARG1=[quoted argument]' -and $captured[2] -ceq 'UPDATED-ARG2=[second argument]' -and $captured[3] -ceq 'UPDATED-ARG3=[bang! value]') 'updated child received exact arguments'

    $sameInstall = Join-Path $root 'same'
    & $installer -DistributionPath $new -ExpectedCommitSha $newSha -InstallRoot $sameInstall | Out-Null
    Write-RunDocument (Join-Path $root 'runs.json') $newSha
    Run-Updater $sameInstall $mock
    Assert-Preserved $sameInstall $newSha

    $tamperedInstallerInstall = Join-Path $root 'tampered-installer'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $tamperedInstallerInstall | Out-Null
    Add-Content -LiteralPath (Join-Path $tamperedInstallerInstall "versions/$currentSha/runtime/install-radiant.ps1") -Value "`nSet-Content -LiteralPath '$injectionMarker' -Value 'executed'`n"
    Reset-Mock; Run-Updater $tamperedInstallerInstall $mock; Assert-Preserved $tamperedInstallerInstall $currentSha; Assert-OldCli $tamperedInstallerInstall

    $invalidUpdaterInstall = Join-Path $root 'invalid-updater'
    & $installer -DistributionPath $new -ExpectedCommitSha $newSha -InstallRoot $invalidUpdaterInstall | Out-Null
    Add-Content -LiteralPath (Join-Path $invalidUpdaterInstall "versions/$newSha/runtime/update-radiant.ps1") -Value "`nSet-Content -LiteralPath '$injectionMarker' -Value 'executed'`n"
    Remove-Item -LiteralPath $injectionMarker -Force -ErrorAction SilentlyContinue
    & (Join-Path $invalidUpdaterInstall 'bin/radiant.cmd') | Out-Null
    Assert (-not (Test-Path -LiteralPath $injectionMarker)) 'the stable wrapper rejected an updater whose hash no longer matched the manifest'

    $historyInstall = Join-Path $root 'history-over-100'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $historyInstall | Out-Null
    $history = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt 100; $i++) {
        $sha = if ($i -eq 99) { $newSha } else { ('{0:x40}' -f (1000 + $i)) }
        $history.Add([ordered]@{ id = 1000 + $i; path = '.github/workflows/ci-distribution.yml'; event = 'push'; head_branch = 'develop'; status = 'completed'; conclusion = 'success'; head_sha = $sha; created_at = '2026-10-29T14:00:00Z'; head_repository = @{ id = $repositoryId; full_name = 'JuanCarlosLF/radiant-dev-tools' } })
    }
    @{ workflow_runs = $history.ToArray() } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'runs.json') -NoNewline
    Write-RunDocument (Join-Path $root 'active-runs.json') $currentSha
    Write-ArtifactDocument (Join-Path $root 'artifacts.json') $newSha -RunId 1099
    Run-Updater $historyInstall $mock
    Assert-Preserved $historyInstall $newSha

    foreach ($case in @(
        @{ Name = 'missing gh'; Gh = (Join-Path $root 'missing-gh.exe') },
        @{ Name = 'wrong repo'; Repository = 'someone/fork' },
        @{ Name = 'wrong branch'; Branch = 'feature' },
        @{ Name = 'wrong event'; Event = 'pull_request' },
        @{ Name = 'wrong workflow'; WorkflowPath = '.github/workflows/other.yml' },
        @{ Name = 'invalid sha'; Sha = 'not-a-sha' },
        @{ Name = 'failed run'; Conclusion = 'failure' }
    )) {
        $candidate = Join-Path $root $case.Name
        & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $candidate | Out-Null
        if ($case.Name -eq 'missing gh') { Run-Updater $candidate $case.Gh } else {
            Write-RunDocument (Join-Path $root 'runs.json') (CaseValue $case 'Sha' $newSha) (CaseValue $case 'Repository' 'JuanCarlosLF/radiant-dev-tools') (CaseValue $case 'Event' 'push') (CaseValue $case 'Branch' 'develop') (CaseValue $case 'WorkflowPath' '.github/workflows/ci-distribution.yml') (CaseValue $case 'Conclusion' 'success')
            Run-Updater $candidate $mock
        }
        Assert-Preserved $candidate $currentSha
        Assert-OldCli $candidate
    }

    $timeoutInstall = Join-Path $root 'timeout'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $timeoutInstall | Out-Null
    Reset-Mock; $env:RADIANT_MOCK_MODE = 'timeout'; Run-Updater $timeoutInstall $mock 1; Assert-Preserved $timeoutInstall $currentSha; Assert-OldCli $timeoutInstall

    $missingArtifactInstall = Join-Path $root 'missing-artifact'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $missingArtifactInstall | Out-Null
    Reset-Mock; @{ artifacts = @() } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'artifacts.json') -NoNewline; Run-Updater $missingArtifactInstall $mock; Assert-Preserved $missingArtifactInstall $currentSha; Assert-OldCli $missingArtifactInstall

    foreach ($entry in @('../escape.txt', '/rooted.txt', 'bin/file.txt', 'BIN/file.txt')) {
        $unsafeInstall = Join-Path $root ('unsafe-' + [guid]::NewGuid().ToString('N'))
        & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $unsafeInstall | Out-Null
        Reset-Mock; Create-UnsafeZip (Join-Path $root 'artifact.zip') $entry; Run-Updater $unsafeInstall $mock; Assert-Preserved $unsafeInstall $currentSha; Assert-OldCli $unsafeInstall
    }
    $collisionInstall = Join-Path $root 'collision'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $collisionInstall | Out-Null
    Reset-Mock; Create-CollisionZip (Join-Path $root 'artifact.zip'); Run-Updater $collisionInstall $mock; Assert-Preserved $collisionInstall $currentSha; Assert-OldCli $collisionInstall

    $tamperedInstall = Join-Path $root 'tampered'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $tamperedInstall | Out-Null
    Reset-Mock; $bad = Copy-Tree 'bad-artifact'; Invoke-Manifest $bad $currentSha; Create-Zip $bad (Join-Path $root 'artifact.zip'); Run-Updater $tamperedInstall $mock; Assert-Preserved $tamperedInstall $currentSha; Assert-OldCli $tamperedInstall

    $lockedInstall = Join-Path $root 'locked'
    & $installer -DistributionPath $current -ExpectedCommitSha $currentSha -InstallRoot $lockedInstall | Out-Null
    $lock = New-Object IO.FileStream -ArgumentList @((Join-Path $lockedInstall '.update.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try { Reset-Mock; Run-Updater $lockedInstall $mock; Assert-Preserved $lockedInstall $currentSha; Assert-OldCli $lockedInstall } finally { $lock.Dispose() }
    Write-Output 'Updater and stable launcher functional tests: passed'
} finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $oldOutput) { Remove-Item Env:RADIANT_TEST_OUTPUT -ErrorAction SilentlyContinue } else { $env:RADIANT_TEST_OUTPUT = $oldOutput }
    if ($null -eq $oldMockRoot) { Remove-Item Env:RADIANT_MOCK_ROOT -ErrorAction SilentlyContinue } else { $env:RADIANT_MOCK_ROOT = $oldMockRoot }
    if ($null -eq $oldMockMode) { Remove-Item Env:RADIANT_MOCK_MODE -ErrorAction SilentlyContinue } else { $env:RADIANT_MOCK_MODE = $oldMockMode }
}
