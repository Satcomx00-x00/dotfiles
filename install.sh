#!/bin/sh
# install.sh — the only thing a fresh machine has to fetch.
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/Satcomx00-x00/dotfiles/main/install.sh)"
#
# Unattended (CI, container images, provisioning):
#
#   DOTFILES_NAME="Your Name" DOTFILES_EMAIL=you@example.com \
#   DOTFILES_PROFILE=server DOTFILES_TIER=standard \
#   sh -c "$(curl -fsSL .../install.sh)" -- --yes
#
# It does four things and then gets out of the way: detect the platform, make
# sure git and curl exist, install chezmoi, and hand off to
# `chezmoi init --apply`, which owns everything after that.
#
# ── Note on decision #38 ─────────────────────────────────────────────────────
# There is NO backup. On a machine that already has a ~/.zshrc, that file is
# replaced and git is the only rollback. This is the sharpest edge in the whole
# design and it is called out here, on screen, before anything is written.

set -eu

REPO="${DOTFILES_REPO:-https://github.com/Satcomx00-x00/dotfiles.git}"
BIN="${DOTFILES_BIN:-$HOME/.local/bin}"
ASSUME_YES=0

for arg in "$@"; do
    case "$arg" in
        -y | --yes) ASSUME_YES=1 ;;
        -h | --help)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

c_bold=''
c_dim=''
c_red=''
c_green=''
c_yellow=''
c_reset=''
if [ -t 1 ]; then
    c_bold='\033[1m'
    c_dim='\033[2m'
    c_red='\033[31m'
    c_green='\033[32m'
    c_yellow='\033[33m'
    c_reset='\033[0m'
fi
step() { printf "${c_bold}==>${c_reset} %s\n" "$*"; }
info() { printf "    %s\n" "$*"; }
warn() { printf "${c_yellow}!!${c_reset} %s\n" "$*"; }
die() {
    printf "${c_red}!!${c_reset} %s\n" "$*" >&2
    exit 1
}

# ─── 1. Platform ─────────────────────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$OS" in
    linux) ;;
    darwin) warn 'macOS is not a supported profile in this repo; proceeding anyway' ;;
    *) die "unsupported OS: $OS" ;;
esac
case "$ARCH" in
    x86_64 | amd64 | aarch64 | arm64) ;;
    *) die "unsupported architecture: $ARCH" ;;
esac
step "platform: $OS/$ARCH"

# ─── 2. Prerequisites ────────────────────────────────────────────────────────
# Only git and curl. Everything else is the base-layer script's job, and it has
# per-distro package lists this script has no business duplicating.
SUDO=''
[ "$(id -u)" -ne 0 ] && command -v sudo > /dev/null 2>&1 && SUDO=sudo

need=''
command -v git > /dev/null 2>&1 || need="$need git"
command -v curl > /dev/null 2>&1 || need="$need curl"

if [ -n "$need" ]; then
    step "installing bootstrap prerequisites:$need"
    # shellcheck disable=SC2086
    if command -v apt-get > /dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get update -qq
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends $need ca-certificates
    elif command -v apk > /dev/null 2>&1; then
        $SUDO apk add --no-cache $need ca-certificates
    elif command -v dnf > /dev/null 2>&1; then
        $SUDO dnf install -y -q $need
    elif command -v pacman > /dev/null 2>&1; then
        $SUDO pacman -Sy --noconfirm --needed $need
    elif command -v zypper > /dev/null 2>&1; then
        $SUDO zypper --non-interactive install -y $need
    else
        die "install these first:$need"
    fi
fi

# ─── 3. The warning that decision #38 earns ──────────────────────────────────
existing=''
for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.config/nvim"; do
    [ -e "$f" ] && existing="$existing $(basename "$f")"
done

if [ -n "$existing" ] && [ "$ASSUME_YES" -ne 1 ]; then
    printf "\n${c_yellow}This machine already has configuration:${c_reset}%s\n" "$existing"
    printf "There is no backup. These files will be REPLACED, and git is the\n"
    printf "only way back. Copy anything you care about now.\n\n"
    if [ -t 0 ]; then
        printf 'continue? [y/N] '
        read -r reply
        case "$reply" in
            [yY]*) ;;
            *) die 'aborted' ;;
        esac
    else
        die 'refusing to overwrite existing config non-interactively; pass --yes'
    fi
fi

# ─── 4. chezmoi ──────────────────────────────────────────────────────────────
export PATH="$BIN:$PATH"
if command -v chezmoi > /dev/null 2>&1; then
    step "chezmoi already installed ($(chezmoi --version | head -1))"
else
    step 'installing chezmoi'
    mkdir -p "$BIN"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN" > /dev/null ||
        die 'chezmoi install failed'
fi

# ─── 5. Hand off ─────────────────────────────────────────────────────────────
# Every prompt can be supplied as a flag, which is what makes the container
# image and CI use exactly this path rather than a parallel one.
#
# The flags key on the PROMPT TEXT, not the data key — see test/prompts.sh.
set --
if [ -n "${DOTFILES_NAME:-}" ]; then set -- "$@" --promptString "Full name=$DOTFILES_NAME"; fi
if [ -n "${DOTFILES_EMAIL:-}" ]; then set -- "$@" --promptString "Email=$DOTFILES_EMAIL"; fi
if [ -n "${DOTFILES_EDITOR:-}" ]; then set -- "$@" --promptString "Editor=$DOTFILES_EDITOR"; fi
if [ -n "${DOTFILES_PROFILE:-}" ]; then set -- "$@" --promptChoice "Machine profile=$DOTFILES_PROFILE"; fi
if [ -n "${DOTFILES_TIER:-}" ]; then set -- "$@" --promptChoice "Tool tier=$DOTFILES_TIER"; fi
if [ -n "${DOTFILES_SECRETS:-}" ]; then set -- "$@" --promptChoice "Secrets backend=$DOTFILES_SECRETS"; fi
if [ -n "${DOTFILES_SIGN:-}" ]; then set -- "$@" --promptBool "Enable SSH commit signing=$DOTFILES_SIGN"; fi
if [ -n "${DOTFILES_SIGNKEY:-}" ]; then set -- "$@" --promptString "SSH signing key path=$DOTFILES_SIGNKEY"; fi

step 'applying'
info 'first run installs the base packages, mise and every tool in your tier'
info 'expect a few minutes, and one sudo prompt for the base packages'
printf '\n'

if [ -n "${DOTFILES_SOURCE:-}" ]; then
    chezmoi init --apply --source="$DOTFILES_SOURCE" "$@"
else
    chezmoi init --apply "$REPO" "$@"
fi

# ─── 6. What now ─────────────────────────────────────────────────────────────
printf "\n${c_green}done${c_reset}\n"
info 'start a new shell, or: exec zsh -l'
info 'dotfiles help     everything this machine can do'
info 'dotfiles doctor   check it is healthy'
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
    printf "\n${c_dim}Your login shell is still %s. If chsh could not change it,\nrun: chsh -s \"\$(command -v zsh)\"${c_reset}\n" "${SHELL:-unknown}"
fi
