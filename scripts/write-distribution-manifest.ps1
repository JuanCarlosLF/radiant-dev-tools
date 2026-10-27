[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $DistributionPath,
    [Parameter(Mandatory = $true)] [string] $CommitSha,
    [Parameter(Mandatory = $true)] [string] $Version,
    [Parameter(Mandatory = $true)] [ValidateRange(1, 255)] [int] $RequiredJavaMajor
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Fail([string] $Message) {
    throw "Manifest generation failed: $Message"
}

if ($CommitSha -notmatch '^[0-9a-fA-F]{40}$') { Fail 'CommitSha must be a full 40-character hexadecimal commit.' }
if ([string]::IsNullOrWhiteSpace($Version)) { Fail 'Version must not be empty.' }

$root = Get-Item -LiteralPath $DistributionPath -ErrorAction Stop
if (-not $root.PSIsContainer) { Fail 'DistributionPath must be a directory.' }
if (($root.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Fail 'DistributionPath must not be a reparse point.' }
$rootPath = $root.FullName.TrimEnd('\', '/')

$files = New-Object System.Collections.Generic.List[object]
$pending = New-Object System.Collections.Generic.Stack[string]
$pending.Push($rootPath)

while ($pending.Count -gt 0) {
    $current = $pending.Pop()
    foreach ($entry in @(Get-ChildItem -LiteralPath $current -Force)) {
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Fail "Reparse points are not allowed: $($entry.FullName)"
        }

        $relative = $entry.FullName.Substring($rootPath.Length).TrimStart('\', '/') -replace '\\', '/'
        if ([string]::IsNullOrWhiteSpace($relative) -or $relative -match '(^|/)\.\.(/|$)' -or $relative.StartsWith('/') -or $relative -match '^[A-Za-z]:') {
            Fail "Unsafe relative path: $relative"
        }

        if ($entry.PSIsContainer) {
            $pending.Push($entry.FullName)
        } elseif ($relative -ne 'manifest.json') {
            $hash = (Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $files.Add([pscustomobject][ordered]@{
                    path   = $relative
                    size   = [int64]$entry.Length
                    sha256 = $hash
                })
        }
    }
}

$files = @($files | Sort-Object -Property path)
$paths = @($files | ForEach-Object { $_.path })
foreach ($required in @('bin/radiant', 'bin/radiant.bat')) {
    if ($paths -notcontains $required) { Fail "Required launcher is missing: $required" }
}
if (-not ($paths | Where-Object { $_ -like 'lib/*.jar' })) { Fail 'The distribution must contain at least one lib/*.jar file.' }

$manifest = [ordered]@{
    schema_version      = 1
    application         = 'radiant'
    commit_sha          = $CommitSha.ToLowerInvariant()
    version             = $Version
    required_java_major = $RequiredJavaMajor
    files               = $files
}
$json = $manifest | ConvertTo-Json -Depth 5 -Compress
[IO.File]::WriteAllText((Join-Path $rootPath 'manifest.json'), $json, (New-Object System.Text.UTF8Encoding -ArgumentList $false))
