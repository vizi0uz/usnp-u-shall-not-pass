# Build usnp.exe from usnp.ps1.template — embeds logo(128) + bg(512) base64, parse-checks, ps2exe.
$ErrorActionPreference = 'Stop'
$t = $PSScriptRoot

Add-Type -AssemblyName System.Drawing

function Get-ScaledB64 {
    param([string]$Path, [int]$Size)
    $src = New-Object System.Drawing.Bitmap $Path
    $dst = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $Size, $Size)
    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $dst.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $b64 = [Convert]::ToBase64String($ms.ToArray())
    $ms.Dispose(); $dst.Dispose(); $src.Dispose()
    return $b64
}

Write-Host "Scaling logo (128) + background (512)..."
$logoB64 = Get-ScaledB64 -Path "$t\launcher-logo.png" -Size 128
$bgB64   = Get-ScaledB64 -Path "$t\launcher-logo.png" -Size 512
Write-Host ("  logo b64 len = {0}, bg b64 len = {1}" -f $logoB64.Length, $bgB64.Length)

Write-Host "Injecting into template..."
$tpl = Get-Content "$t\usnp.ps1.template" -Raw
$tpl = $tpl.Replace('__LOGO_B64__', $logoB64)
$tpl = $tpl.Replace('__BG_B64__',   $bgB64)
# Write ASCII (PS5.1-safe), no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$t\usnp.ps1", $tpl, $utf8NoBom)
Write-Host "  wrote usnp.ps1 ($((Get-Item "$t\usnp.ps1").Length) bytes)"

Write-Host "Parse-check (PowerShell 7)..."
$errs = $null
[System.Management.Automation.Language.Parser]::ParseFile("$t\usnp.ps1", [ref]$null, [ref]$errs) | Out-Null
if ($errs -and $errs.Count) { Write-Host "PS7 PARSE ERRORS:"; $errs | ForEach-Object { Write-Host "  $_" }; exit 2 }
Write-Host "  PS7 parse OK (0 errors)"

Write-Host "Compiling exe (ps2exe, asInvoker)..."
Import-Module ps2exe
# IMPORTANT: do NOT pass `-requireAdmin $false` -- PS binds the bare switch ON and the
# manifest becomes requireAdministrator (forces UAC). OMIT the flag => default asInvoker.
Invoke-ps2exe -InputFile "$t\usnp.ps1" -OutputFile "$t\usnp.exe" `
    -iconFile "$t\usnp.ico" -title 'USNP - U Shall Not Pass!' -product 'USNP' `
    -version '1.1.1' -noConsole | Out-Null

# Verify manifest is asInvoker (fail loudly if admin crept back in)
$exeTxt = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes("$t\usnp.exe"))
if ($exeTxt -match 'requireAdministrator') { Write-Host "ERROR: exe manifest requests admin!"; exit 3 }
$lvl = ([regex]::Match($exeTxt, 'requestedExecutionLevel[^>]*')).Value
Write-Host "  manifest OK -> $lvl"

Write-Host "DONE."
