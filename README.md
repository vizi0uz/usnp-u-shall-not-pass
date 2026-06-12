<img width="1672" height="941" alt="cb2d2013-3e64-43a2-a264-7f193d6ee046" src="https://github.com/user-attachments/assets/8fcd4955-b505-4a96-863a-0ab7b8dfebb7" />

# USNP — U Shall Not Pass!

**A zero-elevation app launcher. Drop it next to any application that nags for admin rights—USNP strips the prompt and runs it clean.**

---

## What It Does

USNP is a lightweight, rename-safe launcher that suppresses Windows UAC (User Account Control) elevation prompts. Instead of letting a stubborn app request admin rights, USNP launches it non-elevated using 4 escalating methods—so the app runs with your current user privileges, no shield icon, no prompt.

**Perfect for:**
- Apps that check for elevation but don't actually need it
- Running apps in restricted environments where UAC is annoying
- Automating app launches in scripts or scheduled tasks
- Trading bots, automation tools, and other user-space applications

---

## Features

✅ **Interactive GUI** — One clickable button per detected executable; launch-on-click, auto-closes on success  
✅ **Resizable window** — Default 512×512 square with custom background art; reflow controls on resize  
✅ **Self-contained** — Embedded logo, icon, and background image; no external dependencies beyond PowerShell  
✅ **Rename-safe** — Works as `usnp.exe`, `launcher.exe`, `start-bot.exe`, etc. No hardcoded names  
✅ **Folder scanning** — Automatically finds all `.exe` files in its folder; excludes itself  
✅ **Audit trail** — Logs every launch attempt with timestamps and method used  
✅ **4-tier escalation** — Tries progressively harder to strip elevation:  
  1. `__COMPAT_LAYER=RunAsInvoker` environment variable (usually works)
  2. Explorer shell token (inherits current-user context)
  3. `runas /trustlevel:0x20000` (medium integrity)
  4. PsExec with `-l` flag (last resort)

✅ **PS5.1 compatible** — Runs on Windows PowerShell 5.1 (bundled in Windows 10+)  
✅ **No console window** — Pure GUI, no flashing cmd prompt  
✅ **No UAC request** — Manifest is `asInvoker`; Windows won't ask for elevation  

---

## Quick Start

### Option 1: Use Pre-Built Executable

1. Download `usnp.exe` from this repo.
2. Place it **next to** the app you want to launch (or in a folder with multiple apps).
3. Double-click `usnp.exe`.
4. Select the app from the window, click the button.
5. App launches—no UAC prompt.

### Option 2: Build from Source

Requires PowerShell 5.1+ and the [`ps2exe`](https://github.com/MScholtes/PS2EXE) module.

```powershell
# Install ps2exe (once)
Install-Module ps2exe -Scope CurrentUser -Force

# Clone or download this repo
cd path/to/usnp

# Build
.\build-usnp.ps1
```

This generates `usnp.exe` and deploys it. If you customize the background image (`launcher-logo.png`), just rerun the build script.

---

## Usage

### GUI Mode (Default)

Double-click `usnp.exe`:
- **Window opens** showing all `.exe` files in the same folder.
- **Pick an app** — click its button.
- **Launches** with elevation stripped.
- **Window auto-closes** on success; shows error if launch fails.

### Command-Line Mode

```powershell
# Launch a specific exe by full path
.\usnp.exe -ExePath "C:\path\to\app.exe"

# Launch by searching for a running process
.\usnp.exe -SearchName "myapp"

# Custom search folder(s)
.\usnp.exe -SearchRoots "C:\tools", "C:\bots"
```

### Batch File Wrapper

For Windows batch scripts or CMD:

```batch
@echo off
REM Wrapper that auto-finds and launches any exe in this folder
set HERE=%~dp0
set PS1=%~dpn0.ps1
where pwsh >nul 2>nul && ( pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %* & goto :eof )
where powershell >nul 2>nul && ( powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %* & goto :eof )
echo PowerShell not found
```

---

## Customization

### Change the Background Image

1. Replace `launcher-logo.png` in the tools folder with your own image.
   - Must be PNG, preferably square (1254×1254 or larger).
2. Rebuild:
   ```powershell
   .\build-usnp.ps1
   ```
3. The new image is scaled and embedded into the exe automatically.

### Modify the UI

Edit `usnp.ps1.template` (the source of truth):
- **Window size**: Change `$clientW` and `$clientH` in `Show-MainWindow` (default 512×512).
- **Button appearance**: Adjust `BackColor`, `Font`, `Size` in the Label-button loop.
- **Colors/styles**: Edit the `FromArgb` color values.
- **Status messages**: Modify strings in `Set-Status` calls.

Then rebuild:
```powershell
.\build-usnp.ps1
```

> ⚠️ **Important:** Never edit `usnp.ps1` directly—it's 800KB+ of embedded base64 and will be overwritten. Always edit the `.template` file and rebuild.

---

## How It Works

### Architecture

```
usnp.exe (compiled)
  ↓
  Scans folder for *.exe files
  ↓
  Shows interactive window
  ↓
  On button click:
    Try Method 1 (RunAsInvoker env)
    → Try Method 2 (Explorer shell token)
    → Try Method 3 (runas /trustlevel)
    → Try Method 4 (PsExec -l)
  ↓
  Log success/failure
  ↓
  Auto-close window
```

### Build Pipeline

1. **Scale images** — `launcher-logo.png` → 128px (icon) + 512px (background)
2. **Base64 encode** — Embed into PowerShell script template
3. **Inject** — Replace markers `__LOGO_B64__` and `__BG_B64__` in template
4. **Parse-check** — Verify PowerShell 5.1 and 7 syntax is valid
5. **Compile** — ps2exe converts PowerShell to Windows exe
6. **Verify manifest** — Assert `requestedExecutionLevel level="asInvoker"` (no admin)
7. **Deploy** — Copy to tools folder and configured bot folder

---

## Logging

Each run creates a `.log` file next to the launcher, named after the exe:
- `usnp.log` (if exe is `usnp.exe`)
- `launcher.log` (if exe is `launcher.exe`)

Log format:
```
[2026-06-12 11:09:07] [INFO] USNP start (root: C:\path\to\folder)
[2026-06-12 11:09:07] [INFO] Found 2 candidate(s).
[2026-06-12 11:09:08] [OK] Target: C:\path\to\app.exe
[2026-06-12 11:09:08] [INFO] Launching app.exe...
[2026-06-12 11:09:08] [INFO] Method 1: RunAsInvoker
[2026-06-12 11:09:09] [OK] Running - PID 12345
```

---

## Troubleshooting

### Window shows no buttons

**Problem:** No `.exe` files found in the same folder as `usnp.exe`.

**Solution:** Place `usnp.exe` in a folder with the app you want to launch, or use `-SearchRoots` to point to a different folder.

### "Admin elevation required" shield icon on exe

**Problem:** Your compiled exe has the admin-shield icon and prompts for elevation.

**Solution:** The manifest is wrong. This happens if the build was done with an older ps2exe version or a malformed ps2exe flag. Rebuild with:
```powershell
Remove-Item usnp.exe, usnp.ps1
.\build-usnp.ps1
```

To verify, extract the manifest from the exe:
```powershell
[System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes("usnp.exe")) | Select-String "requestedExecutionLevel"
```

Should return: `requestedExecutionLevel level="asInvoker"`

### App still pops a UAC prompt after launch

**Problem:** The app itself was already elevated (e.g., spawned from an admin cmd window).

**Solution:** Make sure you're running `usnp.exe` from a **non-elevated** context. Close any admin PowerShell/CMD windows and try again.

### SmartScreen warning on first run

**Problem:** Windows SmartScreen warns "Windows protected your PC."

**Solution:** This is normal for unsigned executables. Click "More info" → "Run anyway." It's not a UAC prompt—it's SmartScreen doing its job. To remove the warning, code-sign the exe (requires a certificate).

---

## Requirements

- **Windows 10 / Windows 11** (any edition)
- **PowerShell 5.1** (built into Windows)
- **.NET Framework 4.5+** (built into Windows 10+)
- **Optional:** `PsExec` from [Sysinternals](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) (Method 4 fallback; download once and place in PATH or same folder)

---

## File Structure

```
usnp/
  usnp.ps1.template    ← Source of truth (code + markers)
  build-usnp.ps1       ← Build script (scales, injects, compiles)
  usnp.cmd             ← Batch wrapper (auto-finds PowerShell, runs ps1)
  launcher-logo.png    ← Background + icon image (customize this)
  launcher-icon.png    ← (Optional) icon overlay
  usnp.ico             ← Icon file for exe
  usnp.ps1             ← Generated (don't edit—built from template)
  usnp.exe             ← Compiled executable (the actual launcher)
  usnp.log             ← Runtime log
  README.md            ← This file
```

---

## Security & Limitations

### What USNP Does NOT Do

- ❌ Does **not** grant admin rights—it **strips** them
- ❌ Does **not** work if the OS-level policy forbids non-admin app launches
- ❌ Does **not** bypass signature validation or SmartScreen (only on unsigned exe warning)
- ❌ Does **not** work for apps that hard-check for admin and refuse to run without it

### Audit & Trust

USNP is a **generic launcher tool**—it makes no assumptions about what app you're launching. Use it only with apps you trust. Always verify:
- The source of `usnp.exe` (build it yourself if unsure)
- The folder contents before clicking launch
- The log file after launch to confirm what ran

---

## Version History

**v1.1.1** (2026-06-12)
- Resizable window (was fixed-size)
- Default 512×512 square (no aspect distortion)
- Anchored controls (reflow on resize)
- Updated logo/background support

**v1.1** (2026-06-12)
- Interactive GUI window (replaced auto-launch)
- Clickable buttons per exe
- Launch-on-click, auto-close on success
- Embedded background image with ~70% opacity buttons

**v1.0.2** (Earlier)
- Batch mode (auto-launch, console-based)
- 4-tier elevation suppression
- Rename-safe operation
- Audit logging

---

## Intended Use & Disclaimer

USNP runs applications **de-elevated** using the documented Windows `RunAsInvoker`
app-compat shim — it **lowers** privilege and suppresses *unnecessary* UAC prompts. It is
**not** a privilege-escalation exploit and does **not** grant administrator rights. Use it
only on machines you own or are authorized to administer, with applications you trust.
Provided as-is, without warranty; you assume all risk.

---

## License

This project is provided as-is for educational and legitimate use (restricted environments, automation, etc.). No warranty implied. Use at your own risk.

---

## Contributing

Found a bug? Have an idea? Feel free to:
1. Test the current version
2. Document the issue with steps to reproduce
3. Suggest a fix or improvement

Contributions welcome!

---

## FAQ

**Q: Can I rename the exe?**  
A: Yes! USNP auto-detects its own name and excludes itself from the exe list. Rename freely.

**Q: Does it work on Windows 7 / Server 2016?**  
A: Untested. Requires PowerShell 5.1 and .NET 4.5+. May work, but not officially supported.

**Q: Can I run two USNP instances at the same time?**  
A: Yes. Each instance scans independently and logs separately.

**Q: What if an app is already non-elevated?**  
A: USNP still launches it—the elevation-stripping methods are no-ops for non-elevated processes, so the app just runs normally.

**Q: How do I uninstall USNP?**  
A: Delete `usnp.exe`. That's it. No registry entries, no service, no cleanup needed.

---

**Made with ❤️ for app launchers and automation scripts.**
