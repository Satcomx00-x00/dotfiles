# Windows PowerShell 5.1 profile — kept minimal; pwsh 7 is the daily shell.
if (Test-Path "$HOME\.x-cmd.root\local\data\pwsh\_index.ps1") { Set-ExecutionPolicy Bypass -Scope Process; . "$HOME\.x-cmd.root\local\data\pwsh\_index.ps1" };  # boot up x-cmd.
if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }

# mise: put managed tools on PATH
if (Get-Command mise -ErrorAction SilentlyContinue) {
    $env:MISE_PWSH_CHPWD_WARNING = 0
    mise activate pwsh | Out-String | Invoke-Expression
}
