[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $DistributionPath,
    [Parameter(Mandatory = $true)] [ValidatePattern('^[0-9a-fA-F]{40}$')] [string] $ExpectedCommitSha,
    [string] $InstallRoot = $(Join-Path $env:LOCALAPPDATA 'Radiant'),
    [switch] $AllowStableLauncherUpgrade
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Fail([string] $Message) { throw "Radiant installation failed: $Message" }
function Assert-CreationAncestors([string] $Path) {
    $candidate = [IO.DirectoryInfo]$Path
    while ($null -ne $candidate -and -not (Test-Path -LiteralPath $candidate.FullName)) { $candidate = $candidate.Parent }
    if ($null -eq $candidate) { Fail "No existing ancestor is available for: $Path" }
    Assert-NoReparse $candidate.FullName
}
function Assert-NoReparse([string] $Path, [bool] $CheckAncestors = $true) {
    $current = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($null -ne $current) {
        if (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Fail "Reparse points are not allowed: $($current.FullName)" }
        if (-not $CheckAncestors) { break }
        $parent = if ($current -is [IO.DirectoryInfo]) { $current.Parent } else { $current.Directory }
        if ($null -eq $parent -or $parent.FullName -eq $current.FullName) { break }
        $current = Get-Item -LiteralPath $parent.FullName -Force -ErrorAction Stop
    }
}
function Assert-SafeRelativePath([string] $Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path.IndexOf([char]0) -ge 0) { Fail 'Manifest path is empty or contains a NUL.' }
    if ($Path.StartsWith('/') -or $Path -match '^[A-Za-z]:') { Fail "Manifest path is rooted: $Path" }
    if ($Path.Contains('\') -or $Path -match '(^|/)\.\.(/|$)' -or $Path -match '(^|/):') { Fail "Manifest path is unsafe: $Path" }
    foreach ($part in $Path.Split('/')) {
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.' -or $part -eq '..' -or $part -match '[\x00-\x1F<>:"|?*]' -or $part.EndsWith('.') -or $part.EndsWith(' ')) { Fail "Manifest path contains an unsafe component: $Path" }
        $base = $part.Split('.')[0].ToUpperInvariant()
        if ($base -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { Fail "Manifest path uses a reserved Windows name: $Path" }
    }
}
function Read-Json([string] $Path) {
    try { return (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop) } catch { Fail "Cannot read JSON: $Path ($($_.Exception.Message))" }
}
function Get-RegularFiles([string] $Root) {
    $result = New-Object System.Collections.Generic.List[object]
    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($Root)
    while ($stack.Count -gt 0) {
        $directory = $stack.Pop()
        Assert-NoReparse $directory $false
        foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
            if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Fail "Reparse points are not allowed: $($entry.FullName)" }
            if ($entry.PSIsContainer) { $stack.Push($entry.FullName) }
            else {
                $relative = $entry.FullName.Substring($Root.Length).TrimStart([char[]]@(92, 47)) -replace [regex]::Escape('\'), '/'
                Assert-SafeRelativePath $relative
                $result.Add($entry)
            }
        }
    }
    return $result.ToArray()
}
function Read-Manifest([string] $Root, [string] $Expected) {
    $path = Join-Path $Root 'manifest.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Fail 'manifest.json is missing.' }
    Assert-NoReparse $path
    $manifest = Read-Json $path
    if ($manifest.schema_version -ne 1) { Fail 'Unsupported manifest schema.' }
    if ($manifest.application -cne 'radiant') { Fail 'Manifest application must be radiant.' }
    if ($manifest.commit_sha -cnotmatch '^[0-9a-fA-F]{40}$' -or $manifest.commit_sha.ToLowerInvariant() -cne $Expected.ToLowerInvariant()) { Fail 'Manifest commit does not match the trusted expected commit.' }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.version)) { Fail 'Manifest version must not be empty.' }
    if ([int]$manifest.required_java_major -ne 24) { Fail 'Unsupported required Java major.' }
    if ($null -eq $manifest.files) { Fail 'Manifest inventory is missing.' }
    $seen = @{}
    foreach ($record in @($manifest.files)) {
        $pathValue = [string]$record.path
        Assert-SafeRelativePath $pathValue
        if ($seen.ContainsKey($pathValue.ToLowerInvariant())) { Fail "Duplicate or case-colliding inventory path: $pathValue" }
        $seen[$pathValue.ToLowerInvariant()] = $pathValue
        if ([int64]$record.size -lt 0 -or [string]$record.sha256 -notmatch '^[0-9a-fA-F]{64}$') { Fail "Invalid inventory record: $pathValue" }
    }
    return $manifest
}
function Validate-Distribution([string] $Root, [string] $TrustedCommit) {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "Distribution directory does not exist: $Root" }
    Assert-NoReparse $Root
    $manifest = Read-Manifest $Root $TrustedCommit
    $rootManifest = [IO.Path]::GetFullPath((Join-Path $Root 'manifest.json'))
    $actualFiles = @(Get-RegularFiles $Root | Where-Object { [IO.Path]::GetFullPath($_.FullName) -cne $rootManifest })
    $actual = @{}
    foreach ($file in $actualFiles) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart([char[]]@(92, 47)) -replace [regex]::Escape('\'), '/'
        $key = $relative.ToLowerInvariant()
        if ($actual.ContainsKey($key)) { Fail "Duplicate or case-colliding distribution file: $relative" }
        $actual[$key] = $relative
    }
    $expected = @{}
    foreach ($record in @($manifest.files)) { $expected[$record.path.ToLowerInvariant()] = $record }
    if ($actual.Count -ne $expected.Count) { Fail 'Distribution files do not exactly match the manifest inventory.' }
    foreach ($key in $expected.Keys) {
        if (-not $actual.ContainsKey($key) -or $actual[$key] -cne [string]$expected[$key].path) { Fail "Distribution inventory mismatch: $($expected[$key].path)" }
        $file = Join-Path $Root $actual[$key]
        $record = $expected[$key]
        if ((Get-Item -LiteralPath $file).Length -ne [int64]$record.size) { Fail "Size mismatch: $($record.path)" }
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -cne [string]$record.sha256.ToLowerInvariant()) { Fail "Hash mismatch: $($record.path)" }
    }
    $manifestPaths = @($manifest.files | ForEach-Object { [string]$_.path })
    foreach ($required in @('bin/radiant', 'bin/radiant.bat')) {
        if (-not ($manifestPaths -ccontains $required)) { Fail "Required exact-case file is missing: $required" }
    }
    if (-not ($manifestPaths | Where-Object { $_ -cmatch '^lib/.+\.jar$' })) { Fail 'The distribution must contain a lib/*.jar file.' }
    return [pscustomobject]@{ Manifest = $manifest; Inventory = $expected }
}
function Compare-Validated([string] $Left, [string] $Right, [string] $Expected) {
    $a = Validate-Distribution $Left $Expected
    $b = Validate-Distribution $Right $Expected
    if ((Get-Content -LiteralPath (Join-Path $Left 'manifest.json') -Raw) -cne (Get-Content -LiteralPath (Join-Path $Right 'manifest.json') -Raw)) { return $false }
    foreach ($key in $a.Inventory.Keys) {
        if (-not $b.Inventory.ContainsKey($key) -or [int64]$a.Inventory[$key].size -ne [int64]$b.Inventory[$key].size -or [string]$a.Inventory[$key].sha256 -cne [string]$b.Inventory[$key].sha256) { return $false }
    }
    return $true
}
function New-PointerText([string] $Commit) {
    $hash = [BitConverter]::ToString((New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Commit))).Replace('-', '').ToLowerInvariant()
    return "$Commit`r`n$hash`r`n"
}
function Replace-FileAtomically([string] $Source, [string] $Destination) {
    Assert-CreationAncestors $Destination
    if ((Test-Path -LiteralPath $Destination) -and -not (Test-Path -LiteralPath $Destination -PathType Leaf)) { Fail "Activation target is not a regular file: $Destination" }
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        Assert-NoReparse $Destination
        $backup = "$Destination.$([guid]::NewGuid().ToString('N')).backup"
        [IO.File]::Replace($Source, $Destination, $backup, $true)
        if (Test-Path -LiteralPath $backup) {
            try { Assert-NoReparse $backup; Remove-Item -LiteralPath $backup -Force -ErrorAction Stop }
            catch { Write-Warning "The owned pointer backup could not be removed: $backup" }
        }
    }
    else { [IO.File]::Move($Source, $Destination) }
}

$source = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $DistributionPath -ErrorAction Stop).Path)
$expected = $ExpectedCommitSha.ToLowerInvariant()
$root = [IO.Path]::GetFullPath($InstallRoot).TrimEnd([char[]]@(92, 47))
if ([string]::IsNullOrWhiteSpace($root)) { Fail 'InstallRoot must not be empty.' }
Assert-CreationAncestors $root
if (-not (Test-Path -LiteralPath $root)) { New-Item -ItemType Directory -Path $root -Force | Out-Null }
Assert-NoReparse $root
$versions = Join-Path $root 'versions'
$bin = Join-Path $root 'bin'
Assert-CreationAncestors $versions
Assert-CreationAncestors $bin
New-Item -ItemType Directory -Path $versions, $bin -Force | Out-Null
Assert-NoReparse $versions
Assert-NoReparse $bin
$lockPath = Join-Path $root '.install.lock'
$lock = $null
$stage = Join-Path $root ('.staging-' + [guid]::NewGuid().ToString('N'))
try {
    # A same-root exclusive handle serializes installers without replacing a running version.
    Assert-CreationAncestors $lockPath
    if (Test-Path -LiteralPath $lockPath) { Assert-NoReparse $lockPath }
    try { $lock = New-Object IO.FileStream -ArgumentList @($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { Fail 'Another installation is already in progress.' }
    $sourceValidation = Validate-Distribution $source $expected
    $destination = Join-Path $versions $expected
    if (Test-Path -LiteralPath $destination) {
        if (-not (Compare-Validated $source $destination $expected)) { Fail 'An existing version has different or tampered bytes.' }
        $versionPath = $destination
    } else {
        Assert-CreationAncestors $stage
        New-Item -ItemType Directory -Path $stage -Force | Out-Null
        foreach ($record in @($sourceValidation.Manifest.files)) {
            $target = Join-Path $stage ([string]$record.path)
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $source ([string]$record.path)) -Destination $target -Force
        }
        Copy-Item -LiteralPath (Join-Path $source 'manifest.json') -Destination (Join-Path $stage 'manifest.json') -Force
        # Validate after copying as well as before copying so source/staging races fail closed.
        Validate-Distribution $stage $expected | Out-Null
        if (Test-Path -LiteralPath $destination) { Fail 'The version appeared concurrently; it was not replaced.' }
        [IO.Directory]::Move($stage, $destination)
        $stage = $null
        Validate-Distribution $destination $expected | Out-Null
        $versionPath = $destination
    }
    $stable = Join-Path $bin 'radiant.cmd'
    $candidateStable = Join-Path $PSScriptRoot 'radiant.cmd'
    if (-not (Test-Path -LiteralPath $candidateStable -PathType Leaf)) {
        $candidateStable = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/radiant.cmd'
    }
    if (-not (Test-Path -LiteralPath $candidateStable -PathType Leaf)) { Fail 'Stable launcher source is missing.' }
    Assert-NoReparse $candidateStable
    if ((Test-Path -LiteralPath $stable) -and -not (Test-Path -LiteralPath $stable -PathType Leaf)) { Fail 'Existing stable launcher is not a regular file.' }
    if (Test-Path -LiteralPath $stable -PathType Leaf) {
        Assert-NoReparse $stable
        if (-not [Linq.Enumerable]::SequenceEqual([IO.File]::ReadAllBytes($stable), [IO.File]::ReadAllBytes($candidateStable))) {
            if (-not $AllowStableLauncherUpgrade) { Fail 'Existing stable launcher is incompatible; explicit bootstrap upgrade is required.' }
            $stableTemp = "$stable.$([guid]::NewGuid().ToString('N')).tmp"
            Copy-Item -LiteralPath $candidateStable -Destination $stableTemp -Force
            Replace-FileAtomically $stableTemp $stable
        }
    } else { Copy-Item -LiteralPath $candidateStable -Destination $stable -Force }
    $pointerTemp = Join-Path $root ('.active-' + [guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllText($pointerTemp, (New-PointerText $expected), (New-Object Text.UTF8Encoding -ArgumentList $false))
    # Replace only the pointer; the previous pointer remains until this atomic operation succeeds.
    Replace-FileAtomically $pointerTemp (Join-Path $root 'active.txt')
    Write-Output "Installed radiant $expected under $versionPath"
} finally {
    if ($null -ne $stage -and (Test-Path -LiteralPath $stage)) {
        try { Assert-NoReparse $stage; Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop }
        catch { Write-Warning "Owned staging cleanup failed: $stage" }
    }
    if ($null -ne $lock) { $lock.Dispose() }
}
