# ── Oh My Posh ────────────────────────────────────────────────
oh-my-posh init pwsh --config "$env:DOTFILES\oh-my-posh\saumya.omp.json" | Invoke-Expression

# ── Useful aliases ─────────────────────────────────────────────
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
Set-Alias -Name vi  -Value nvim -ErrorAction SilentlyContinue

# ── Quality of life ────────────────────────────────────────────
$env:EDITOR = "zed"

function which ($cmd) { Get-Command $cmd | Select-Object -ExpandProperty Source }
function reload { . $PROFILE }

# ── PSReadLine (better shell history/autocomplete) ─────────────
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ── Suppress the PowerShell startup banner ─────────────────────
# (handled by pwsh -NoLogo in Windows Terminal profile)
