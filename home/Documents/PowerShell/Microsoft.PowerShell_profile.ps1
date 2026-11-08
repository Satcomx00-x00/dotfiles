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

    # Cache the activation script. Its 22 KB / 324 lines parse for free, but
    # *running* them costs ~840 ms per shell because Invoke-Expression re-parses
    # a string; a dot-sourced copy of the same file costs ~400 ms.
    # Regenerated only when the generated mise config or mise itself changes.
    $MiseCache = Join-Path $HOME '.cache/mise-activate.ps1'
    $MiseStamp = Join-Path $HOME '.cache/mise-activate.stamp'
    $MiseConfig = Join-Path $HOME '.config/mise/config.toml'
    $MiseExe    = (Get-Command mise).Source
    $Stamp = @(
        if (Test-Path $MiseConfig) { (Get-Item $MiseConfig).LastWriteTimeUtc.Ticks }
        if (Test-Path $MiseExe)    { (Get-Item $MiseExe).LastWriteTimeUtc.Ticks }
        mise --version 2>$null
    ) -join '|'
    $Cached = if (Test-Path $MiseStamp) { Get-Content $MiseStamp -Raw } else { '' }

    if ($Cached.Trim() -ne $Stamp -or -not (Test-Path $MiseCache)) {
        New-Item -ItemType Directory -Force (Split-Path $MiseCache) | Out-Null
        mise activate pwsh | Set-Content $MiseCache -Encoding utf8
        Set-Content $MiseStamp $Stamp -Encoding utf8
    }

    $MisePrompt = $function:prompt
    . $MiseCache

    # mise's activated prompt re-runs hook-env on every prompt unless a cd has
    # already done it. The LocationChangedAction below owns that instead, so pin
    # the prompt back to what it was before activation. Without this, every
    # Enter pays the full tool-scan (~400 ms with the 62 tools declared here).
    # starship redefines the prompt below; this keeps the fallback cheap when it
    # is not installed.
    if ($MisePrompt) { function global:prompt { & $MisePrompt } }

    # hook-env costs ~10-15 ms per declared tool (62 tools ≈ 780 ms) and mise
    # runs it on EVERY directory change. Almost no cd needs it: a directory
    # only matters if it — or an ancestor — declares a tool version, because
    # mise walks up to the nearest project root. So walk up from the new path
    # (five Test-Path calls per level, no subprocess) and call mise only when
    # the answer changes: entering a project, or leaving the one we were in.
    # While the new path is still underneath $Global:__pwshMiseRoot no ancestor
    # can have changed, so moving around inside a project is free too.
    #
    # Two traps this avoids, both found the hard way:
    #   * mise activate REPLACES the command with a wrapper *function* whose
    #     .Source is empty, so `& (Get-Command mise).Source` silently runs
    #     nothing. $MiseExe was captured above, before activation — use it.
    #   * NewPath is a PathInfo object, not a string. .StartsWith/.EndsWith on
    #     it throw InvalidOperationException, so coerce once, up front.
    $Global:__pwshMiseExe = $MiseExe
    $Global:__pwshMiseRoot = ''
    $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction =
        [EventHandler[System.Management.Automation.LocationChangedEventArgs]]{
            param($Sender, $EventArgs)

            $NewPath = if ($EventArgs.NewPath) { $EventArgs.NewPath.Path } else { '' }
            if (-not $NewPath) { return }

            $Root = [string]$Global:__pwshMiseRoot
            if ($Root) {
                $Sep = [IO.Path]::DirectorySeparatorChar
                $Prefix = if ($Root.EndsWith($Sep)) { $Root } else { $Root + $Sep }
                if ($NewPath.StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)) { return }
            }

            $Declaring = ''
            $Probe = $NewPath
            while ($Probe) {
                foreach ($File in 'mise.toml', '.mise.toml', '.tool-versions', '.nvmrc', '.python-version') {
                    if (Test-Path (Join-Path $Probe $File)) { $Declaring = $Probe; break }
                }
                if ($Declaring) { break }
                $Up = [IO.Path]::GetDirectoryName($Probe)
                if (-not $Up -or $Up -eq $Probe) { break }
                $Probe = $Up
            }

            if (-not $Declaring -and -not $Root) { return }
            $Diff = & $Global:__pwshMiseExe hook-env -s pwsh 2>$null | Out-String
            if ($Diff -and $Diff.Trim()) { Invoke-Expression $Diff }
            $Global:__pwshMiseRoot = $Declaring
        }
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
