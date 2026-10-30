@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem The pointer is untrusted data. PowerShell validates it before any commit text
rem is expanded by CMD; CMD receives only one full lower-case hexadecimal value.
set "RADIANT_ROOT=%~dp0.."
for %%I in ("%RADIANT_ROOT%") do set "RADIANT_ROOT=%%~fI"
set "RADIANT_COMMIT="
set "RADIANT_CHECK="
set "RADIANT_POINTER=%RADIANT_ROOT%\active.txt"
for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:RADIANT_ROOT;$pointer=Join-Path $root 'active.txt';if(-not(Test-Path -LiteralPath $pointer -PathType Leaf)){exit 1};$lines=@(Get-Content -LiteralPath $pointer -ErrorAction Stop);if($lines.Count -ne 2 -or $lines[0] -cnotmatch '^[0-9a-f]{40}$' -or $lines[1] -cnotmatch '^[0-9a-f]{64}$'){exit 1};$h=[Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($lines[0]));$expected=[BitConverter]::ToString($h).Replace('-','').ToLowerInvariant();if($lines[1] -cne $expected){exit 1};$child=Join-Path $root ('versions\'+$lines[0]+'\bin\radiant.bat');if(-not(Test-Path -LiteralPath $child -PathType Leaf)){exit 1};Write-Output $lines[0]" 2^>nul') do set "RADIANT_COMMIT=%%A"
set "RADIANT_UPDATER=%RADIANT_ROOT%\versions\%RADIANT_COMMIT%\runtime\update-radiant.ps1"
set "RADIANT_UPDATER_OK="
if defined RADIANT_COMMIT for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:RADIANT_ROOT;$commit=$env:RADIANT_COMMIT;$pointer=Join-Path $root 'active.txt';$lines=@(Get-Content -LiteralPath $pointer -ErrorAction Stop);$h=[Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($commit));$expected=[BitConverter]::ToString($h).Replace('-','').ToLowerInvariant();$manifestPath=Join-Path $root ('versions\'+$commit+'\manifest.json');$updater=Join-Path $root ('versions\'+$commit+'\runtime\update-radiant.ps1');if($lines.Count -ne 2 -or $lines[0] -cne $commit -or $lines[1] -cne $expected){exit 1};$manifest=Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop|ConvertFrom-Json;$record=@($manifest.files|Where-Object{$_.path -ceq 'runtime/update-radiant.ps1'});if($record.Count -ne 1 -or -not(Test-Path -LiteralPath $updater -PathType Leaf)){exit 1};$item=Get-Item -LiteralPath $updater -Force;if(($item.Attributes-band [IO.FileAttributes]::ReparsePoint)-ne 0 -or $item.Length -ne [int64]$record[0].size){exit 1};if((Get-FileHash -LiteralPath $updater -Algorithm SHA256).Hash.ToLowerInvariant() -cne ([string]$record[0].sha256).ToLowerInvariant()){exit 1};Write-Output valid" 2^>nul') do set "RADIANT_UPDATER_OK=%%A"
if /I "%RADIANT_UPDATER_OK%"=="valid" powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%RADIANT_UPDATER%" -InstallRoot "%RADIANT_ROOT%" -CurrentCommit "%RADIANT_COMMIT%"
set "RADIANT_COMMIT="
for /f "delims=" %%A in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$root=$env:RADIANT_ROOT;$pointer=Join-Path $root 'active.txt';if(-not(Test-Path -LiteralPath $pointer -PathType Leaf)){exit 1};$lines=@(Get-Content -LiteralPath $pointer -ErrorAction Stop);if($lines.Count -ne 2 -or $lines[0] -cnotmatch '^[0-9a-f]{40}$' -or $lines[1] -cnotmatch '^[0-9a-f]{64}$'){exit 1};$h=[Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($lines[0]));$expected=[BitConverter]::ToString($h).Replace('-','').ToLowerInvariant();if($lines[1] -cne $expected){exit 1};$child=Join-Path $root ('versions\'+$lines[0]+'\bin\radiant.bat');if(-not(Test-Path -LiteralPath $child -PathType Leaf)){exit 1};Write-Output $lines[0]" 2^>nul') do set "RADIANT_COMMIT=%%A"
if not defined RADIANT_COMMIT goto invalid
set "RADIANT_CHILD=%RADIANT_ROOT%\versions\%RADIANT_COMMIT%\bin\radiant.bat"
call "%RADIANT_CHILD%" %*
exit /b %ERRORLEVEL%
:invalid
>&2 echo ERROR: Radiant installation pointer is invalid or missing.
exit /b 1
