# pwsh 7 profile — the Windows counterpart of ~/.config/shell/*.sh.
#
# Machine-specific functions (hosts, LAN scripts) go in
# ~/.config/powershell/local.ps1, which chezmoi never manages (decision #30).

# x-cmd (same as the Windows PowerShell 5.1 profile)
if (Test-Path "$HOME\.x-cmd.root\local\data\pwsh\_index.ps1") { . "$HOME\.x-cmd.root\local\data\pwsh\_index.ps1" }

# Tools that only look in %APPDATA% on Windows: point them at the XDG copies
# chezmoi writes, so one file serves every OS.
$env:BAT_CONFIG_PATH     = "$HOME\.config\bat\config"
$env:RIPGREP_CONFIG_PATH = "$HOME\.config\ripgrep\config"
$env:K9S_CONFIG_DIR      = "$HOME\.config\k9s"

# mise: put managed tools on PATH — first, since it provides starship & co.
if (Get-Command mise -ErrorAction SilentlyContinue) {
    $env:MISE_PWSH_CHPWD_WARNING = 0
    mise activate pwsh | Out-String | Invoke-Expression
}

# Prompt
if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }

# PSReadLine: history-based predictions, shown as a list (F2 toggles inline/list)
if ((Get-Module -ListAvailable PSReadLine) -and -not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -HistoryNoDuplicates -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
}

# Aliases / helpers
function ll { Get-ChildItem -Force @args }
function which($Name) { Get-Command $Name -All | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function touch($Path) { if (Test-Path $Path) { (Get-Item $Path).LastWriteTime = Get-Date } else { New-Item -ItemType File $Path | Out-Null } }
function reload { . $PROFILE }

# Launch Chrome Dev with CDP and expose it on the LAN (self-elevates if needed)
function chrome-cdp {
    param([int]$Port = 9222)
    $ErrorActionPreference = 'Stop'

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Start-Process pwsh -Verb RunAs -ArgumentList '-NoExit', '-Command', "chrome-cdp -Port $Port"
        return
    }

    $LanIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.1.*' } |
        Select-Object -First 1).IPAddress
    if (-not $LanIp) { throw 'No 192.168.1.* IPv4 address found' }
    $Chrome = 'C:\Program Files\Google\Chrome Dev\Application\chrome.exe'
    $UserDataDir = "$env:TEMP\chrome-mcp-profile"

    # portproxy needs iphlpsvc
    if ((Get-Service iphlpsvc).Status -ne 'Running') { Start-Service iphlpsvc }

    Start-Process $Chrome -ArgumentList "--remote-debugging-port=$Port", '--remote-allow-origins=*', "--user-data-dir=$UserDataDir"
    Start-Sleep -Seconds 2   # let Chrome bind its loopback listener

    # Detect which loopback Chrome bound (::1 vs 127.0.0.1)
    $line = netstat -an | Select-String ":$Port\s.*LISTENING"
    $useV6 = [bool]($line -match '\[::1\]')
    $connect = if ($useV6) { '::1' } else { '127.0.0.1' }
    $proto = if ($useV6) { 'v4tov6' } else { 'v4tov4' }
    Write-Host "Chrome bound on $connect -> using $proto" -ForegroundColor Cyan

    # Reset old portproxy entries, then forward LAN IPv4 -> Chrome loopback
    'v4tov4', 'v4tov6' | ForEach-Object {
        netsh interface portproxy delete $_ listenaddress=$LanIp listenport=$Port 2>$null | Out-Null
        netsh interface portproxy delete $_ listenaddress=0.0.0.0 listenport=$Port 2>$null | Out-Null
    }
    netsh interface portproxy add $proto listenaddress=$LanIp listenport=$Port connectaddress=$connect connectport=$Port

    # Firewall (LAN only)
    if (-not (Get-NetFirewallRule -DisplayName "Chrome CDP $Port" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "Chrome CDP $Port" -Direction Inbound `
            -Protocol TCP -LocalPort $Port -Action Allow -Profile Private | Out-Null
    }

    netsh interface portproxy show all
    netstat -an | Select-String ":$Port\s"
    Write-Host "`nTest from LAN:  curl -H 'Host: localhost' http://${LanIp}:$Port/json/version" -ForegroundColor Green
}

# Machine-local additions, last so they can override anything above.
if (Test-Path "$HOME\.config\powershell\local.ps1") { . "$HOME\.config\powershell\local.ps1" }
