[CmdletBinding()]
param(
    [string] $InstallRoot = $(Join-Path $env:LOCALAPPDATA 'Radiant'),
    [ValidatePattern('^[0-9a-fA-F]{40}$')] [string] $CurrentCommit,
    [string] $GhPath,
    [int] $TimeoutSeconds = 20,
    [switch] $Quiet
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Fail([string] $Message) { throw "Radiant update failed: $Message" }
function Warn([string] $Message) { if (-not $Quiet) { Write-Warning $Message } }
function Quote-ProcessArgument([string] $Value) {
    if ($Value -notmatch '[\s"]') { return $Value }
    $escaped = $Value -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}
function Invoke-External([string] $FileName, [string[]] $Arguments, [int] $Timeout, [string] $BinaryOutputPath, [int64] $MaxOutputBytes = 250MB) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables['GH_PROMPT_DISABLED'] = '1'
    $psi.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
    $prefix = @()
    if ([IO.Path]::GetExtension($FileName).ToLowerInvariant() -eq '.ps1') {
        $powerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
        $psi.FileName = $powerShell
        $prefix = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $FileName)
    }
    $psi.Arguments = (($prefix + $Arguments) | ForEach-Object { Quote-ProcessArgument ([string]$_) }) -join ' '
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    try {
        if (-not $process.Start()) { Fail "Could not start $FileName." }
        $process.StandardInput.Close()
        $stdoutTask = $null
        $output = $null
        if ([string]::IsNullOrWhiteSpace($BinaryOutputPath)) {
            $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        } else {
            $output = New-Object IO.FileStream($BinaryOutputPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        }
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $deadline = [DateTime]::UtcNow.AddSeconds($Timeout)
        if ($null -eq $stdoutTask) {
            $buffer = New-Object byte[] 65536
            $total = [int64]0
            while ($true) {
                $read = $process.StandardOutput.BaseStream.ReadAsync($buffer, 0, $buffer.Length)
                $remaining = [int][Math]::Max(1, [Math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalMilliseconds))
                if (-not $read.Wait($remaining)) { try { $process.Kill() } catch { }; try { $process.WaitForExit() } catch { }; Fail "The external command exceeded the ${Timeout}s timeout." }
                $count = $read.Result
                if ($count -eq 0) { break }
                $total += $count
                if ($total -gt $MaxOutputBytes) { try { $process.Kill() } catch { }; Fail 'The external command returned too many bytes.' }
                $output.Write($buffer, 0, $count)
            }
            $output.Flush()
            $remaining = [int][Math]::Max(1, [Math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalMilliseconds))
            if (-not $process.WaitForExit($remaining)) { try { $process.Kill() } catch { }; try { $process.WaitForExit() } catch { }; Fail "The external command exceeded the ${Timeout}s timeout." }
        } elseif (-not $process.WaitForExit($Timeout * 1000)) {
            try { $process.Kill() } catch { }
            try { $process.WaitForExit() } catch { }
            Fail "The external command exceeded the ${Timeout}s timeout."
        }
        $stdout = if ($null -eq $stdoutTask) { '' } else { $stdoutTask.Result }
        $stderr = $stderrTask.Result
        if ($stdout.Length -gt 8MB) { Fail 'The external command returned too much metadata.' }
        if ($stderr.Length -gt 1MB) { Fail 'The external command returned too much diagnostic output.' }
        if ($process.ExitCode -ne 0) { Fail "The external command failed with exit code $($process.ExitCode)." }
        return [pscustomobject]@{ Output = $stdout; Error = $stderr }
    } finally { if ($null -ne $output) { $output.Dispose() }; $process.Dispose() }
}
function Read-Json([string] $Text, [string] $Description) {
    try { return ($Text | ConvertFrom-Json -ErrorAction Stop) } catch { Fail "Invalid $Description metadata." }
}
function Get-GhPath() {
    if (-not [string]::IsNullOrWhiteSpace($GhPath)) {
        if (-not (Test-Path -LiteralPath $GhPath -PathType Leaf)) { Fail 'The configured gh command does not exist.' }
        return [IO.Path]::GetFullPath($GhPath)
    }
    $command = Get-Command gh.exe -ErrorAction SilentlyContinue
    if ($null -eq $command) { Fail 'GitHub CLI is not installed.' }
    return $command.Source
}
function Read-Pointer([string] $Root) {
    $pointer = Join-Path $Root 'active.txt'
    if (-not (Test-Path -LiteralPath $pointer -PathType Leaf)) { Fail 'No active installation exists.' }
    Assert-NoReparse $pointer
    $lines = @(Get-Content -LiteralPath $pointer -ErrorAction Stop)
    if ($lines.Count -ne 2 -or $lines[0] -cnotmatch '^[0-9a-f]{40}$' -or $lines[1] -cnotmatch '^[0-9a-f]{64}$') { Fail 'The active installation pointer is invalid.' }
    $hash = [BitConverter]::ToString((New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($lines[0]))).Replace('-', '').ToLowerInvariant()
    if ($lines[1] -cne $hash) { Fail 'The active installation pointer checksum is invalid.' }
    return $lines[0]
}
function Acquire-Lock([string] $Path) {
    try { return New-Object IO.FileStream -ArgumentList @($Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { return $null }
}
function Assert-NoReparse([string] $Path) {
    $current = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($null -ne $current) {
        if (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Fail "Reparse points are not allowed: $($current.FullName)" }
        $parent = if ($current -is [IO.DirectoryInfo]) { $current.Parent } else { $current.Directory }
        if ($null -eq $parent -or $parent.FullName -eq $current.FullName) { break }
        $current = Get-Item -LiteralPath $parent.FullName -Force -ErrorAction Stop
    }
}
function Assert-ExistingNoReparse([string] $Path, [string] $Description) {
    if (-not (Test-Path -LiteralPath $Path)) { Fail "$Description is missing." }
    Assert-NoReparse $Path
}
function Get-Property([object] $Object, [string] $Name) {
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $null }
    return $property.Value
}
function Get-PositiveInteger([object] $Value, [string] $Description) {
    if ($null -eq $Value -or $Value -is [bool] -or $Value -isnot [byte] -and $Value -isnot [int16] -and $Value -isnot [int32] -and $Value -isnot [int64] -and $Value -isnot [decimal] -and $Value -isnot [double]) { Fail "$Description is invalid." }
    $number = [int64]$Value
    if ($number -le 0 -or [double]$Value -ne [double]$number) { Fail "$Description is invalid." }
    return $number
}
function Read-TrustedRepository([object] $Document) {
    $id = Get-PositiveInteger (Get-Property $Document 'id') 'The repository id'
    if ((Get-Property $Document 'full_name') -cne 'JuanCarlosLF/radiant-dev-tools') { Fail 'The GitHub repository identity is not trusted.' }
    return [pscustomobject]@{ Id = $id; FullName = 'JuanCarlosLF/radiant-dev-tools' }
}
function Get-TrustedRunRecords([object] $Document, [int64] $RepositoryId) {
    $runs = @(Get-Property $Document 'workflow_runs')
    $valid = New-Object System.Collections.Generic.List[object]
    foreach ($run in $runs) {
        $id = Get-PositiveInteger (Get-Property $run 'id') 'The workflow run id'
        $headRepository = Get-Property $run 'head_repository'
        $headRepositoryId = Get-Property $headRepository 'id'
        $repository = Get-Property $headRepository 'full_name'
        $sha = [string](Get-Property $run 'head_sha')
        $created = [string](Get-Property $run 'created_at')
        $path = [string](Get-Property $run 'path')
        $createdAt = [datetime]::MinValue
        $parsed = [datetime]::TryParse($created, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$createdAt)
        if ($path -ne '.github/workflows/ci-distribution.yml' -or
            (Get-Property $run 'event') -ne 'push' -or (Get-Property $run 'head_branch') -ne 'develop' -or
            (Get-Property $run 'status') -ne 'completed' -or (Get-Property $run 'conclusion') -ne 'success' -or
            $repository -cne 'JuanCarlosLF/radiant-dev-tools' -or [int64]$headRepositoryId -ne $RepositoryId -or $sha -cnotmatch '^[0-9a-fA-F]{40}$' -or -not $parsed) { continue }
        $valid.Add([pscustomobject]@{ Run = $run; Id = [string]$id; Sha = $sha.ToLowerInvariant(); Created = $createdAt })
    }
    return $valid.ToArray()
}
function Select-TrustedRun([object[]] $Records, [string] $Active) {
    if ($Records.Count -eq 0) { return $null }
    $ordered = @($Records | Sort-Object -Property @{Expression = 'Created'; Descending = $true}, @{Expression = { [int64]$_.Id }; Descending = $true})
    $current = @($ordered | Where-Object { $_.Sha -eq $Active })
    if ($current.Count -eq 0) { return $null }
    $newest = $ordered[0]
    if ($newest.Sha -eq $Active -or $newest.Created -le $current[0].Created) { return $null }
    return $newest
}
function Select-TrustedArtifact([object] $Document, [string] $RunId, [string] $Sha, [int64] $RepositoryId) {
    $artifacts = @(Get-Property $Document 'artifacts')
    $matches = @($artifacts | Where-Object {
        $workflow = Get-Property $_ 'workflow_run'
        (Get-Property $_ 'name') -ceq 'radiant-dev' -and
        (Get-Property $_ 'expired') -eq $false -and
        (Get-Property $_ 'id') -isnot [string] -and
        [string](Get-Property $workflow 'id') -ceq $RunId -and
        [string](Get-Property $workflow 'head_sha') -ceq $Sha -and
        [int64](Get-Property $workflow 'repository_id') -eq $RepositoryId -and
        [int64](Get-Property $workflow 'head_repository_id') -eq $RepositoryId
    })
    if ($matches.Count -ne 1) { Fail 'The trusted run does not have exactly one valid radiant-dev artifact.' }
    return $matches[0]
}
function Assert-SafeEntry([string] $Name) {
    $normalized = $Name.Replace('\', '/')
    if ([string]::IsNullOrWhiteSpace($normalized) -or $normalized.StartsWith('/') -or $normalized -match '^[A-Za-z]:' -or $normalized -match '(^|/)\.\.(/|$)' -or $normalized -match '(^|/):') { Fail "The artifact contains an unsafe path: $Name" }
    foreach ($part in $normalized.TrimEnd('/').Split('/')) {
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.' -or $part -eq '..' -or $part -match '[\x00-\x1F<>:"|?*]' -or $part.EndsWith('.') -or $part.EndsWith(' ')) { Fail "The artifact contains an unsafe path: $Name" }
        if ($part.Split('.')[0].ToUpperInvariant() -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { Fail "The artifact contains a reserved path: $Name" }
    }
    return $normalized
}
function Get-TrustedOwnedInstaller([string] $Root, [string] $Commit) {
    $version = Join-Path (Join-Path $Root 'versions') $Commit
    $manifestPath = Join-Path $version 'manifest.json'
    Assert-ExistingNoReparse $version 'The active version directory'
    Assert-ExistingNoReparse $manifestPath 'The active version manifest'
    $manifest = Read-Json (Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop) 'active version manifest'
    if ($manifest.schema_version -ne 1 -or $manifest.application -cne 'radiant' -or [string]$manifest.commit_sha -cne $Commit) { Fail 'The active version manifest is not trusted.' }
    $record = @($manifest.files | Where-Object { [string]$_.path -ceq 'runtime/install-radiant.ps1' })
    if ($record.Count -ne 1 -or [int64]$record[0].size -lt 0 -or [string]$record[0].sha256 -cnotmatch '^[0-9a-fA-F]{64}$') { Fail 'The active version installer record is invalid.' }
    $path = Join-Path $version 'runtime/install-radiant.ps1'
    Assert-ExistingNoReparse $path 'The active version installer'
    $item = Get-Item -LiteralPath $path -Force
    if (-not $item.PSIsContainer -and $item.Length -eq [int64]$record[0].size -and (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ceq [string]$record[0].sha256.ToLowerInvariant()) { return $path }
    Fail 'The active version installer does not match its manifest.'
}
function Extract-Artifact([string] $ZipPath, [string] $Destination) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    $seen = @{}; $total = [int64]0
    try {
        if ($archive.Entries.Count -gt 10000) { Fail 'The artifact contains too many entries.' }
        foreach ($entry in $archive.Entries) {
            $name = Assert-SafeEntry $entry.FullName
            $key = $name.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { Fail "The artifact contains duplicate paths: $name" }
            $seen[$key] = $name
            if (($entry.ExternalAttributes -band [int]0xF0000000) -eq [int]0xA0000000) { Fail "The artifact contains a link entry: $name" }
            $total += [int64]$entry.Length
            if ($total -gt 250MB -or $entry.Length -gt 100MB) { Fail 'The artifact is too large.' }
        }
        foreach ($entry in $archive.Entries) {
            $name = Assert-SafeEntry $entry.FullName
            if ($name.EndsWith('/')) { New-Item -ItemType Directory -Path (Join-Path $Destination $name.TrimEnd('/')) -Force | Out-Null; continue }
            $target = Join-Path $Destination $name
            $parent = Split-Path -Parent $target
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Assert-NoReparse $parent
            $input = $entry.Open(); $output = New-Object IO.FileStream($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $buffer = New-Object byte[] 65536; do { $read = $input.Read($buffer, 0, $buffer.Length); if ($read -gt 0) { $output.Write($buffer, 0, $read) } } while ($read -gt 0) }
            finally { $output.Dispose(); $input.Dispose() }
        }
    } finally { $archive.Dispose() }
}

$root = [IO.Path]::GetFullPath($InstallRoot).TrimEnd([char[]]@(92, 47))
$lock = $null; $work = Join-Path $root ('.update-' + [guid]::NewGuid().ToString('N')); $zip = Join-Path $work 'artifact.zip'; $distribution = Join-Path $work 'distribution'
try {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { Fail 'The installation root does not exist.' }
    Assert-NoReparse $root
    $active = Read-Pointer $root
    if (-not [string]::IsNullOrWhiteSpace($CurrentCommit) -and $CurrentCommit.ToLowerInvariant() -ne $active) { Fail 'The stable wrapper and active pointer disagree.' }
    $lockPath = Join-Path $root '.update.lock'
    if (Test-Path -LiteralPath $lockPath) { Assert-NoReparse $lockPath }
    $lock = Acquire-Lock $lockPath
    if ($null -eq $lock) { Warn 'Another update is already in progress; continuing with the current version.'; exit 0 }
    New-Item -ItemType Directory -Path $distribution -Force | Out-Null
    $gh = Get-GhPath
    $repositoryResponse = Invoke-External $gh @('api', 'repos/JuanCarlosLF/radiant-dev-tools') $TimeoutSeconds
    $repository = Read-TrustedRepository (Read-Json $repositoryResponse.Output 'repository')
    $runResponse = Invoke-External $gh @('api', 'repos/JuanCarlosLF/radiant-dev-tools/actions/workflows/ci-distribution.yml/runs?branch=develop&event=push&status=success&per_page=100') $TimeoutSeconds
    $recent = @(Get-TrustedRunRecords (Read-Json $runResponse.Output 'workflow run') $repository.Id)
    $run = Select-TrustedRun $recent $active
    $activePresent = @($recent | Where-Object { $_.Sha -ceq $active }).Count -gt 0
    if ($null -eq $run -and -not $activePresent) {
        # The first page is bounded at 100 runs. A direct head_sha query prevents an old
        # active installation from becoming permanently invisible as history grows.
        $headResponse = Invoke-External $gh @('api', "repos/JuanCarlosLF/radiant-dev-tools/actions/workflows/ci-distribution.yml/runs?branch=develop&event=push&status=success&head_sha=$active&per_page=10") $TimeoutSeconds
        $head = @(Get-TrustedRunRecords (Read-Json $headResponse.Output 'active workflow run') $repository.Id)
        $run = Select-TrustedRun (@($recent) + @($head)) $active
    }
    if ($null -eq $run) { exit 0 }
    $artifactResponse = Invoke-External $gh @('api', "repos/JuanCarlosLF/radiant-dev-tools/actions/runs/$($run.Id)/artifacts?per_page=100") $TimeoutSeconds
    $artifact = Select-TrustedArtifact (Read-Json $artifactResponse.Output 'artifact') $run.Id $run.Sha $repository.Id
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $download = Invoke-External $gh @('api', "repos/JuanCarlosLF/radiant-dev-tools/actions/artifacts/$([string]$artifact.id)/zip") $TimeoutSeconds -BinaryOutputPath $zip
    if (-not (Test-Path -LiteralPath $zip -PathType Leaf) -or (Get-Item -LiteralPath $zip).Length -le 0) { Fail 'The trusted artifact download was empty.' }
    Extract-Artifact $zip $distribution
    $installer = Get-TrustedOwnedInstaller $root $active
    & $installer -DistributionPath $distribution -ExpectedCommitSha $run.Sha -InstallRoot $root | Out-Null
    Write-Output "Updated radiant to $($run.Sha)"
} catch {
    Warn $_.Exception.Message
    exit 0
} finally {
    if ($null -ne $lock) { $lock.Dispose() }
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
