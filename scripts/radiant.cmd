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
if not defined RADIANT_COMMIT goto invalid
set "RADIANT_CHILD=%RADIANT_ROOT%\versions\%RADIANT_COMMIT%\bin\radiant.bat"
call "%RADIANT_CHILD%" %*
exit /b %ERRORLEVEL%
:invalid
>&2 echo ERROR: Radiant installation pointer is invalid or missing.
exit /b 1
