# =============================================================================
# Gaming OS Setup — install.ps1
# saumyakaran/dotfiles (windows branch)
#
# Run as NORMAL USER (not admin) in PowerShell 7+
# Symlinks require Developer Mode OR will be created via elevation at the end.
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DOTFILES     = "$env:USERPROFILE\dotfiles"
$GITHUB_USER  = "saumyakaran"
$REPO         = "dotfiles"
$BRANCH       = "windows"

function Log    { Write-Host "  $args" -ForegroundColor Cyan }
function Ok     { Write-Host "  + $args" -ForegroundColor Green }
function Warn   { Write-Host "  ! $args" -ForegroundColor Yellow }
function Header { Write-Host "`n-- $args --" -ForegroundColor Magenta }

# Bail if running as admin
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  ERROR: Do not run this script as Administrator." -ForegroundColor Red
    Write-Host "  Run it as your normal user in PowerShell 7." -ForegroundColor Red
    Write-Host "  Symlinks will be handled automatically at the end via elevation." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Developer Mode (needed for symlinks without admin)
# ─────────────────────────────────────────────────────────────────────────────
Header "Developer Mode"

$devMode = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
if ($devMode -and $devMode.AllowDevelopmentWithoutDevLicense -eq 1) {
    Ok "Developer Mode already enabled"
} else {
    Warn "Developer Mode is NOT enabled."
    Warn "Please enable it: Settings > Privacy & Security > For Developers > Developer Mode"
    Warn "This allows symlinks without admin. Press Enter to continue anyway..."
    Read-Host
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Scoop
# ─────────────────────────────────────────────────────────────────────────────
Header "Scoop"

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Log "Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Ok "Scoop installed"
} else { Ok "Scoop already installed" }

scoop bucket add extras 2>$null
scoop bucket add nerd-fonts 2>$null
Ok "Scoop buckets ready"

# ─────────────────────────────────────────────────────────────────────────────
# 3. CLI tools
# ─────────────────────────────────────────────────────────────────────────────
Header "CLI tools"

$scoopPackages = @("git", "oh-my-posh", "nodejs", "wget", "curl", "everything")

foreach ($pkg in $scoopPackages) {
    $installed = scoop list 2>$null | Select-String "^$pkg "
    if (-not $installed) {
        Log "Installing $pkg..."
        scoop install $pkg
        Ok "$pkg installed"
    } else { Ok "$pkg already installed" }
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Fonts
# ─────────────────────────────────────────────────────────────────────────────
Header "Fonts"

$fonts = @("GeistMono-NF", "GeistMono-NF-Propo")
foreach ($font in $fonts) {
    $fontCheck = Get-ChildItem "$env:USERPROFILE\scoop\apps" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $font }
    if (-not $fontCheck) {
        Log "Installing $font..."
        scoop install $font
        Ok "$font installed"
    } else { Ok "$font already installed" }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. GUI apps via winget
# ─────────────────────────────────────────────────────────────────────────────
Header "GUI apps (winget)"

$wingetPackages = @(
    @{ id = "glzr-io.glazewm";             name = "GlazeWM" }
    @{ id = "AmN.yasb";                    name = "YASB" }
    @{ id = "Microsoft.WindowsTerminal";   name = "Windows Terminal" }
    @{ id = "Zed.Zed";                     name = "Zed" }
    @{ id = "Flow-Launcher.Flow-Launcher"; name = "Flow Launcher" }
    @{ id = "Nilesoft.Shell";              name = "Nilesoft Shell" }
    @{ id = "Microsoft.PowerToys";         name = "PowerToys" }
    @{ id = "Windhawk.Windhawk";           name = "Windhawk" }
    @{ id = "voidtools.Everything";        name = "Everything" }
    @{ id = "File-New-Project.EarTrumpet"; name = "EarTrumpet" }
    @{ id = "QL-Win.QuickLook";            name = "QuickLook" }
    @{ id = "Spotify.Spotify";             name = "Spotify" }
)

foreach ($pkg in $wingetPackages) {
    Log "Checking $($pkg.name)..."
    $installed = winget list --id $pkg.id --accept-source-agreements 2>$null | Select-String $pkg.id
    if (-not $installed) {
        winget install --id $pkg.id --silent --accept-package-agreements --accept-source-agreements
        Ok "$($pkg.name) installed"
    } else { Ok "$($pkg.name) already installed" }
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. Files App (Microsoft Store)
# ─────────────────────────────────────────────────────────────────────────────
Header "Files App"

$filesCheck = winget list --name "Files" 2>$null | Select-String "Files"
if (-not $filesCheck) {
    Log "Installing Files App from Microsoft Store..."
    winget install --id "49306atecsolution.FilesUWP" --silent --accept-package-agreements --accept-source-agreements 2>$null
    if ($LASTEXITCODE -ne 0) {
        Warn "winget install failed — trying Microsoft Store ID..."
        winget install --id "9NGHP3DX8HDX" --source msstore --silent --accept-package-agreements --accept-source-agreements 2>$null
        if ($LASTEXITCODE -ne 0) {
            Warn "Files App could not be installed automatically."
            Warn "Install manually from Microsoft Store: search 'Files' by Files Community"
        } else { Ok "Files App installed" }
    } else { Ok "Files App installed" }
} else { Ok "Files App already installed" }

# ─────────────────────────────────────────────────────────────────────────────
# 7. Spicetify
# ─────────────────────────────────────────────────────────────────────────────
Header "Spicetify"

if (-not (Get-Command spicetify -ErrorAction SilentlyContinue)) {
    Log "Installing Spicetify..."
    Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression
    Ok "Spicetify installed"
} else { Ok "Spicetify already installed" }

$spicetifyThemesPath = "$env:APPDATA\spicetify\Themes"
if (-not (Test-Path "$spicetifyThemesPath\catppuccin")) {
    Log "Installing Spicetify Catppuccin theme..."
    git clone --depth=1 https://github.com/catppuccin/spicetify.git "$env:TEMP\catppuccin-spicetify"
    Copy-Item "$env:TEMP\catppuccin-spicetify\catppuccin" "$spicetifyThemesPath\catppuccin" -Recurse -Force
    Remove-Item "$env:TEMP\catppuccin-spicetify" -Recurse -Force
    Ok "Catppuccin theme installed"
} else { Ok "Catppuccin theme already present" }

# ─────────────────────────────────────────────────────────────────────────────
# 8. Claude Code
# ─────────────────────────────────────────────────────────────────────────────
Header "Claude Code"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Log "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    Ok "Claude Code installed"
} else { Ok "Claude Code already installed" }

# ─────────────────────────────────────────────────────────────────────────────
# 9. Dotfiles
# ─────────────────────────────────────────────────────────────────────────────
Header "Dotfiles"

if (-not (Test-Path $DOTFILES)) {
    Log "Cloning dotfiles (windows branch)..."
    git clone --single-branch --branch $BRANCH "https://github.com/$GITHUB_USER/$REPO.git" $DOTFILES
    Ok "Dotfiles cloned"
} else {
    Log "Dotfiles already exist, pulling latest..."
    git -C $DOTFILES pull
    Ok "Dotfiles up to date"
}

[System.Environment]::SetEnvironmentVariable("DOTFILES", $DOTFILES, "User")
$env:DOTFILES = $DOTFILES

# ─────────────────────────────────────────────────────────────────────────────
# 10. Spicetify apply
# ─────────────────────────────────────────────────────────────────────────────
Header "Applying Spicetify"

Log "Running spicetify backup + apply..."
spicetify backup
spicetify apply
Ok "Spicetify applied"

# ─────────────────────────────────────────────────────────────────────────────
# 11. Symlinks — elevated subprocess
# ─────────────────────────────────────────────────────────────────────────────
Header "Symlinks"

$symlinkScript = @"
Set-StrictMode -Version Latest
`$DOTFILES = "$DOTFILES"

function Symlink(`$src, `$dst) {
    `$dstDir = Split-Path `$dst -Parent
    if (-not (Test-Path `$dstDir)) { New-Item -ItemType Directory -Path `$dstDir -Force | Out-Null }
    if (Test-Path `$dst) {
        if ((Get-Item `$dst -Force).LinkType -eq 'SymbolicLink') {
            Remove-Item `$dst -Force
        } else {
            Rename-Item `$dst "`$dst.bak" -Force
            Write-Host "  ! Backed up existing `$(Split-Path `$dst -Leaf)" -ForegroundColor Yellow
        }
    }
    New-Item -ItemType SymbolicLink -Path `$dst -Target `$src -Force | Out-Null
    Write-Host "  + Linked `$(Split-Path `$dst -Leaf)" -ForegroundColor Green
}

Write-Host ""
Write-Host "-- Symlinks --" -ForegroundColor Magenta

# GlazeWM
Symlink "`$DOTFILES\glazewm\config.yaml"                         "`$env:USERPROFILE\.glaze-wm\config.yaml"

# YASB (reads from ~/.config/yasb/, NOT ~/.yasb/)
Symlink "`$DOTFILES\yasb\config.yaml"                            "`$env:USERPROFILE\.config\yasb\config.yaml"
Symlink "`$DOTFILES\yasb\styles.css"                             "`$env:USERPROFILE\.config\yasb\styles.css"

# Oh My Posh
Symlink "`$DOTFILES\oh-my-posh\saumya.omp.json"                  "`$env:USERPROFILE\.config\ohmyposh\saumya.omp.json"

# PowerShell profile
Symlink "`$DOTFILES\powershell\Microsoft.PowerShell_profile.ps1" "`$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# Zed
Symlink "`$DOTFILES\zed\settings.json"                           "`$env:APPDATA\Zed\settings.json"

# Flow Launcher
Symlink "`$DOTFILES\flow-launcher\Settings.json"                 "`$env:APPDATA\FlowLauncher\Settings\Settings.json"

# Spicetify
Symlink "`$DOTFILES\spicetify\config-xpui.ini"                   "`$env:APPDATA\spicetify\config-xpui.ini"

# Nilesoft Shell
`$nilePath = "C:\Program Files\Nilesoft Shell\shell.nss"
if (Test-Path (Split-Path `$nilePath -Parent)) {
    Symlink "`$DOTFILES\nilesoft-shell\shell.nss" `$nilePath
} else {
    Write-Host "  ! Nilesoft Shell not found — symlink manually after install" -ForegroundColor Yellow
}

# Windows Terminal
`$wtPackage = Get-ChildItem "`$env:LOCALAPPDATA\Packages" | Where-Object { `$_.Name -like "Microsoft.WindowsTerminal*" } | Select-Object -First 1
if (`$wtPackage) {
    Symlink "`$DOTFILES\windows-terminal\settings.json" "`$(`$wtPackage.FullName)\LocalState\settings.json"
} else {
    Write-Host "  ! Windows Terminal package not found — symlink manually" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Symlinks done. Press any key to close..." -ForegroundColor Green
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

$symlinkScriptPath = "$env:TEMP\symlinks.ps1"
$symlinkScript | Out-File -FilePath $symlinkScriptPath -Encoding UTF8
Log "Launching elevated window for symlinks (accept the UAC prompt)..."
Start-Process pwsh -ArgumentList "-NoLogo -ExecutionPolicy Bypass -File `"$symlinkScriptPath`"" -Verb RunAs -Wait
Ok "Symlinks complete"

# ─────────────────────────────────────────────────────────────────────────────
# 12. Autostart — elevated subprocess
# ─────────────────────────────────────────────────────────────────────────────
Header "Autostart"

$autostartScript = @"
function RegisterStartupTask(`$name, `$exe) {
    `$action    = New-ScheduledTaskAction -Execute `$exe
    `$trigger   = New-ScheduledTaskTrigger -AtLogOn
    `$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    `$principal = New-ScheduledTaskPrincipal -UserId `$env:USERNAME -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName `$name -Action `$action -Trigger `$trigger -Settings `$settings -Principal `$principal -Force | Out-Null
    Write-Host "  + Registered `$name" -ForegroundColor Green
}

`$glaze = Get-Command glazewm -ErrorAction SilentlyContinue
if (`$glaze) { RegisterStartupTask "GlazeWM" `$glaze.Source }
else { Write-Host "  ! GlazeWM not in PATH — autostart skipped" -ForegroundColor Yellow }

`$yasb = Get-Command yasb -ErrorAction SilentlyContinue
if (`$yasb) { RegisterStartupTask "YASB" `$yasb.Source }
else { Write-Host "  ! YASB not in PATH — autostart skipped" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Autostart done. Press any key to close..." -ForegroundColor Green
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

$autostartScriptPath = "$env:TEMP\autostart.ps1"
$autostartScript | Out-File -FilePath $autostartScriptPath -Encoding UTF8
Log "Launching elevated window for autostart (accept the UAC prompt)..."
Start-Process pwsh -ArgumentList "-NoLogo -ExecutionPolicy Bypass -File `"$autostartScriptPath`"" -Verb RunAs -Wait
Ok "Autostart tasks registered"

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  All done! Manual steps remaining:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Run: claude                       — authenticate Claude Code" -ForegroundColor White
Write-Host "  2. Files App — set as default for folders (Settings > Default Apps)" -ForegroundColor White
Write-Host "  3. Windhawk — open and install desired mods" -ForegroundColor White
Write-Host "  4. Add wallpaper to dotfiles\wallpaper\" -ForegroundColor White
Write-Host "  5. Wallpaper Engine — install via Steam" -ForegroundColor White
Write-Host ""
Write-Host "  Restart to apply GlazeWM + YASB autostart." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
