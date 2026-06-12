@echo off
setlocal
title USNP - U Shall Not Pass!
set "HERE=%~dp0"
set "PS1=%~dpn0.ps1"
set "SELF=%~n0"
where pwsh       >nul 2>nul && ( pwsh       -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %* & goto :eof )
where powershell >nul 2>nul && ( powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %* & goto :eof )
echo [!] PowerShell not found - pure-cmd fallback (RunAsInvoker)
set "__COMPAT_LAYER=RunAsInvoker"
set "TARGET="
for /f "delims=" %%F in ('dir /b /a-d "%HERE%*.exe" 2^>nul') do (
    echo %%~nF | findstr /i /x "%SELF%" >nul || set "TARGET=%%F"
)
if defined TARGET ( echo Launching %TARGET% ... & start "" "%HERE%%TARGET%" ) else ( echo No target exe found in %HERE% & pause )
endlocal
