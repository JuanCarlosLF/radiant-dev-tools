[CmdletBinding()]
param([string] $TempRoot = $env:RUNNER_TEMP)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($TempRoot) -or -not (Test-Path -LiteralPath $TempRoot -PathType Container)) { throw 'TempRoot must be supplied or RUNNER_TEMP must name an existing directory.' }
$scripts = Split-Path -Parent $MyInvocation.MyCommand.Path
$installer = Join-Path (Split-Path -Parent $scripts) 'install-radiant.ps1'
$generator = Join-Path (Split-Path -Parent $scripts) 'write-distribution-manifest.ps1'
$repo = Split-Path -Parent (Split-Path -Parent $scripts)
$source = Join-Path $repo 'build/install/radiant'
if (-not (Test-Path -LiteralPath (Join-Path $source 'manifest.json'))) { throw 'Run installDist before the installer tests.' }
foreach ($runtimeFile in @('runtime/install-radiant.ps1', 'runtime/update-radiant.ps1', 'runtime/radiant.cmd')) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $runtimeFile) -PathType Leaf)) { throw "Packaged runtime file is missing: $runtimeFile" }
}
$root = Join-Path $TempRoot ('radiant-installer-tests-' + [guid]::NewGuid().ToString('N'))
$commit = ([string](Get-Content -LiteralPath (Join-Path $source 'manifest.json') -Raw | ConvertFrom-Json).commit_sha)
$oldChildOutput = $env:RADIANT_TEST_OUTPUT
$oldRadiantCheck = $env:RADIANT_CHECK
function Assert([bool] $Condition, [string] $Message) { if (-not $Condition) { throw "Assertion failed: $Message" } }
function ExpectFailure([scriptblock] $Action, [string] $Name) {
    try { & $Action; throw "Expected failure did not occur: $Name" } catch { if ($_.Exception.Message -notmatch 'Radiant installation failed|ERROR:') { throw } }
}
function Copy-Distribution([string] $Name) {
    $path = Join-Path $root $Name
    Copy-Item -LiteralPath $source -Destination $path -Recurse -Force
    return $path
}
function Run-Install([string] $Distribution, [string] $Install = (Join-Path $root 'install')) {
    & $installer -DistributionPath $Distribution -ExpectedCommitSha $commit -InstallRoot $Install | Out-Null
}
function Refresh-Manifest([string] $Distribution) {
    & $generator -DistributionPath $Distribution -CommitSha $commit -Version '1.0-SNAPSHOT' -RequiredJavaMajor 24
}
try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $valid = Copy-Distribution 'valid distribution with spaces'
    $install = Join-Path $root 'install root with spaces'
    Run-Install $valid $install
    Assert (Test-Path -LiteralPath (Join-Path $install "versions\$commit\manifest.json")) 'version activated'
    Assert ((Get-Content -LiteralPath (Join-Path $install 'active.txt') -TotalCount 1) -eq $commit) 'active pointer commit'
    Run-Install $valid $install
    $heldLock = New-Object IO.FileStream -ArgumentList @((Join-Path $install '.install.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try { ExpectFailure { Run-Install $valid $install } 'concurrent installation lock' } finally { $heldLock.Dispose() }

    $wrong = Copy-Distribution 'wrong commit'
    $wrongJson = Get-Content -LiteralPath (Join-Path $wrong 'manifest.json') -Raw | ConvertFrom-Json
    $wrongJson.commit_sha = ('b' * 40)
    $wrongJson | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath (Join-Path $wrong 'manifest.json') -NoNewline
    ExpectFailure { Run-Install $wrong (Join-Path $root 'wrong-install') } 'wrong commit'

    $missing = Copy-Distribution 'missing file'
    Remove-Item -LiteralPath (Join-Path $missing 'lib/radiant-devtools-1.0-SNAPSHOT.jar')
    ExpectFailure { Run-Install $missing (Join-Path $root 'missing-install') } 'missing file'
    $missingLauncher = Copy-Distribution 'missing launcher'
    Remove-Item -LiteralPath (Join-Path $missingLauncher 'bin/radiant.bat')
    ExpectFailure { Run-Install $missingLauncher (Join-Path $root 'missing-launcher-install') } 'missing launcher'

    foreach ($case in @(
        @{ Name = 'wrong application'; Property = 'application'; Value = 'other' },
        @{ Name = 'empty version'; Property = 'version'; Value = '' },
        @{ Name = 'wrong Java'; Property = 'required_java_major'; Value = 23 }
    )) {
        $metadataCase = Copy-Distribution $case.Name
        $metadataJson = Get-Content -LiteralPath (Join-Path $metadataCase 'manifest.json') -Raw | ConvertFrom-Json
        $metadataJson.($case.Property) = $case.Value
        $metadataJson | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath (Join-Path $metadataCase 'manifest.json') -NoNewline
        ExpectFailure { Run-Install $metadataCase (Join-Path $root ($case.Name + ' install')) } $case.Name
    }
    $noJar = Copy-Distribution 'no jar'
    Get-ChildItem -LiteralPath (Join-Path $noJar 'lib') -Filter '*.jar' | Remove-Item -Force
    ExpectFailure { Run-Install $noJar (Join-Path $root 'no jar install') } 'no jar'

    $extra = Copy-Distribution 'extra file'
    [IO.File]::WriteAllText((Join-Path $extra 'extra.txt'), 'not in inventory')
    ExpectFailure { Run-Install $extra (Join-Path $root 'extra-install') } 'extra file'

    $tampered = Copy-Distribution 'tampered file'
    $tamperedBytes = [IO.File]::ReadAllBytes((Join-Path $tampered 'bin/radiant.bat'))
    $tamperedBytes[0] = $tamperedBytes[0] -bxor 1
    [IO.File]::WriteAllBytes((Join-Path $tampered 'bin/radiant.bat'), $tamperedBytes)
    ExpectFailure { Run-Install $tampered (Join-Path $root 'tampered-install') } 'hash tamper'
    [IO.File]::AppendAllText((Join-Path $install "versions\$commit\bin\radiant"), 'tamper')
    ExpectFailure { Run-Install $valid $install } 'tampered existing version'
    Assert ((Get-Content -LiteralPath (Join-Path $install 'active.txt') -TotalCount 1) -eq $commit) 'failed reinstall preserves active pointer'

    $metadata = Copy-Distribution 'bad metadata'
    $bad = Get-Content -LiteralPath (Join-Path $metadata 'manifest.json') -Raw | ConvertFrom-Json
    $bad.schema_version = 2
    $bad | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath (Join-Path $metadata 'manifest.json') -NoNewline
    ExpectFailure { Run-Install $metadata (Join-Path $root 'metadata-install') } 'schema'

    $unsafe = Copy-Distribution 'unsafe manifest'
    $unsafeJson = Get-Content -LiteralPath (Join-Path $unsafe 'manifest.json') -Raw | ConvertFrom-Json
    $unsafeJson.files[0].path = '../escape.txt'
    $unsafeJson | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath (Join-Path $unsafe 'manifest.json') -NoNewline
    ExpectFailure { Run-Install $unsafe (Join-Path $root 'unsafe-install') } 'traversal'
    $absolute = Copy-Distribution 'absolute manifest'
    $absoluteJson = Get-Content -LiteralPath (Join-Path $absolute 'manifest.json') -Raw | ConvertFrom-Json
    $absoluteJson.files[0].path = 'C:/escape.txt'
    $absoluteJson | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath (Join-Path $absolute 'manifest.json') -NoNewline
    ExpectFailure { Run-Install $absolute (Join-Path $root 'absolute-install') } 'absolute path'
    $collision = Copy-Distribution 'case collision manifest'
    $collisionJson = Get-Content -LiteralPath (Join-Path $collision 'manifest.json') -Raw | ConvertFrom-Json
    $collisionJson.files += $collisionJson.files[0]
    $collisionJson | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath (Join-Path $collision 'manifest.json') -NoNewline
    ExpectFailure { Run-Install $collision (Join-Path $root 'collision-install') } 'case collision'
    $nested = Copy-Distribution 'nested manifest'
    [IO.File]::WriteAllText((Join-Path $nested 'lib/manifest.json'), '{}')
    ExpectFailure { Run-Install $nested (Join-Path $root 'nested-manifest-install') } 'nested manifest'

    $reparse = Copy-Distribution 'reparse distribution'
    $linkCreated = $false
    $link = $null
    foreach ($linkType in @('SymbolicLink', 'Junction')) {
        if ($linkCreated) { break }
        $link = Join-Path $reparse ('linked-' + $linkType)
        try { New-Item -ItemType $linkType -Path $link -Target (Join-Path $reparse 'lib') -ErrorAction Stop | Out-Null; $linkCreated = $true } catch { }
    }
    if ($linkCreated) { ExpectFailure { Run-Install $reparse (Join-Path $root 'reparse-install') } 'reparse' }
    else { Write-Output 'Reparse-point rejection: skipped (symbolic links unavailable)' }

    $fake = Copy-Distribution 'fake child distribution'
    $childOutput = Join-Path $root 'child-output.txt'
    $env:RADIANT_TEST_OUTPUT = $childOutput
    @('@echo off', 'setlocal DisableDelayedExpansion', '>"%RADIANT_TEST_OUTPUT%" (', ' echo CWD=[%CD%]', ' echo ARG1=[%~1]', ' echo ARG2=[%~2]', ' echo ARG3=[%~3]', ')', 'exit /b 7') | Set-Content -LiteralPath (Join-Path $fake 'bin/radiant.bat')
    Refresh-Manifest $fake
    $fakeInstall = Join-Path $root 'fake install'
    Run-Install $fake $fakeInstall
    $pointerBeforeFailure = [IO.File]::ReadAllText((Join-Path $fakeInstall 'active.txt'))
    [IO.File]::WriteAllText((Join-Path $fakeInstall 'bin/radiant.cmd'), 'incompatible stable launcher')
    ExpectFailure { Run-Install $fake $fakeInstall } 'activation failure'
    Assert ([IO.File]::ReadAllText((Join-Path $fakeInstall 'active.txt')) -ceq $pointerBeforeFailure) 'activation failure preserves old pointer'
    & (Join-Path $fakeInstall "versions\$commit\bin\radiant.bat") | Out-Null
    Assert ($LASTEXITCODE -eq 7) 'old version remains runnable after activation failure'
    Copy-Item -LiteralPath (Join-Path (Split-Path -Parent $installer) 'radiant.cmd') -Destination (Join-Path $fakeInstall 'bin/radiant.cmd') -Force
    $invalidInstall = Join-Path $root 'invalid install'
    New-Item -ItemType Directory -Path (Join-Path $invalidInstall 'bin') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $fakeInstall 'bin/radiant.cmd') -Destination (Join-Path $invalidInstall 'bin/radiant.cmd')
    & (Join-Path $invalidInstall 'bin/radiant.cmd') | Out-Null
    Assert ($LASTEXITCODE -ne 0) 'invalid stable pointer fails nonzero'
    $caller = Join-Path $root 'caller cwd'
    $caller = (New-Item -ItemType Directory -Path $caller -Force).FullName
    $stable = Join-Path $fakeInstall 'bin/radiant.cmd'
    Push-Location $caller
    try { & $stable 'quoted argument' 'second argument' 'bang! value'; $exit = $LASTEXITCODE } finally { Pop-Location }
    Assert ($exit -eq 7) 'stable launcher preserves child exit code'
    $captured = @(Get-Content -LiteralPath $childOutput)
    Assert ($captured[0] -ceq "CWD=[$caller]") 'stable launcher preserves exact caller CWD'
    Assert ($captured[1] -ceq 'ARG1=[quoted argument]') 'stable launcher preserves first argument'
    Assert ($captured[2] -ceq 'ARG2=[second argument]') 'stable launcher preserves second argument'
    Assert ($captured[3] -ceq 'ARG3=[bang! value]') 'stable launcher preserves exclamation argument'

    $hostilePointer = Join-Path $fakeInstall 'active.txt'
    [IO.File]::WriteAllText($hostilePointer, "bad`"& echo INJECTED > `"$root\injected.txt`"`r`n`r`n")
    $env:RADIANT_CHECK = 'inherited-poison'
    & $stable | Out-Null
    Assert ($LASTEXITCODE -ne 0) 'hostile pointer fails nonzero'
    Assert (-not (Test-Path -LiteralPath (Join-Path $root 'injected.txt'))) 'hostile pointer is not executed'

    $realInstall = Join-Path $root 'real packaged install'
    Run-Install $source $realInstall
    $realLauncher = Join-Path $realInstall 'bin/radiant.cmd'
    Push-Location $caller
    try { & $realLauncher '--help'; $helpExit = $LASTEXITCODE; & $realLauncher 'missing-command'; $missingExit = $LASTEXITCODE } finally { Pop-Location }
    Assert ($helpExit -eq 0) 'packaged CLI --help exit code'
    Assert ($missingExit -eq 2) 'packaged CLI usage exit code'
    Write-Output 'Installer and stable launcher functional tests: passed'
} finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $oldChildOutput) { Remove-Item Env:RADIANT_TEST_OUTPUT -ErrorAction SilentlyContinue }
    else { $env:RADIANT_TEST_OUTPUT = $oldChildOutput }
    if ($null -eq $oldRadiantCheck) { Remove-Item Env:RADIANT_CHECK -ErrorAction SilentlyContinue }
    else { $env:RADIANT_CHECK = $oldRadiantCheck }
}
