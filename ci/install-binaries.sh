#!/usr/bin/env bash
# =============================================================================
# install-binaries.sh — CI Image Binary Installer
# =============================================================================
# Reads binaries.yaml and installs every tool via the appropriate package
# manager.  Intended to run inside a CI pipeline or container build.
#
# Providers: apt | go | cargo | pip | bun  (npm section uses bun)
#
# Usage:
#   ./install-binaries.sh [OPTIONS]
#
# Options:
#   --dry-run              Print commands without executing them
#   --skip-existing        Skip already-installed binaries (default: on)
#   --no-skip-existing     Force reinstall even if binary exists
#   --managers=LIST        Comma-separated managers to run
#                          default: apt,go,cargo,pip,bun
#   --only=LIST            Comma-separated binary names to install
#   --registry=PATH        Path to binaries.yaml  (default: <script-dir>/binaries.yaml)
#   --install-dir=PATH     Destination for symlinks/binaries (default: /usr/local/bin)
#   --help, -h             Show this message
#
# Environment variables (override defaults without CLI flags):
#   REGISTRY, INSTALL_DIR, DRY_RUN, SKIP_EXISTING, MANAGERS, ONLY_BINARIES
# =============================================================================

set -euo pipefail

# ─── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Defaults (can be overridden by env vars or CLI flags) ────────────────────
REGISTRY="${REGISTRY:-${SCRIPT_DIR}/binaries.yaml}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
DRY_RUN="${DRY_RUN:-false}"
SKIP_EXISTING="${SKIP_EXISTING:-true}"
ACTIVE_MANAGERS="${MANAGERS:-apt,go,cargo,pip,bun}"
ONLY_BINARIES="${ONLY_BINARIES:-}"
MAX_RETRIES=3

# ─── Colors (disabled when stdout is not a TTY) ───────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
  BLUE='\033[0;34m' CYAN='\033[0;36m' BOLD='\033[1m' NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# ─── Logging ──────────────────────────────────────────────────────────────────
log()         { echo -e "${BLUE}▶${NC} $*"; }
log_ok()      { echo -e "${GREEN}✔${NC} $*"; }
log_skip()    { echo -e "${CYAN}↷${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
log_error()   { echo -e "${RED}✘${NC} $*" >&2; }
log_section() { echo -e "\n${BOLD}${BLUE}══ $* ══${NC}"; }

# ─── Error accumulation (continue on failure, report at end) ─────────────────
ERRORS=()
record_error() { ERRORS+=("$1"); }

# ─── CLI parsing ─────────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run)            DRY_RUN=true ;;
    --skip-existing)      SKIP_EXISTING=true ;;
    --no-skip-existing)   SKIP_EXISTING=false ;;
    --managers=*)         ACTIVE_MANAGERS="${arg#*=}" ;;
    --only=*)             ONLY_BINARIES="${arg#*=}" ;;
    --registry=*)         REGISTRY="${arg#*=}" ;;
    --install-dir=*)      INSTALL_DIR="${arg#*=}" ;;
    --help|-h)
      sed -n '/^# Usage:/,/^# ===/{/^# ===/d; s/^# \{0,1\}//; p}' "$0"
      exit 0 ;;
    *) log_error "Unknown option: $arg"; exit 1 ;;
  esac
done

# ─── Guard: require python3 for YAML parsing ──────────────────────────────────
if ! command -v python3 &>/dev/null; then
  log_error "python3 is required to parse binaries.yaml. Install it first."
  exit 1
fi

# ─── Guard: registry must exist ───────────────────────────────────────────────
if [[ ! -f "$REGISTRY" ]]; then
  log_error "Registry not found: $REGISTRY"
  exit 1
fi

# ─── Helpers ──────────────────────────────────────────────────────────────────
is_manager_active() { [[ ",${ACTIVE_MANAGERS}," == *",${1},"* ]]; }
is_binary_wanted()  { [[ -z "$ONLY_BINARIES" ]] || [[ ",${ONLY_BINARIES}," == *",${1},"* ]]; }
binary_exists()     { command -v "$1" &>/dev/null; }

# run_cmd: honours --dry-run; exits 0 so callers can detect "nothing done"
run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  ${CYAN}[dry-run]${NC} $*"
    return 0
  fi
  "$@"
}

# retry_cmd: wraps run_cmd with exponential-backoff retries
retry_cmd() {
  local attempt=0
  until run_cmd "$@"; do
    attempt=$(( attempt + 1 ))
    if (( attempt >= MAX_RETRIES )); then
      return 1
    fi
    local delay=$(( 2 ** attempt ))
    log_warn "Attempt $attempt/$MAX_RETRIES failed. Retrying in ${delay}s…"
    sleep "$delay"
  done
}

# ─── YAML section parser (no external deps, pure Python stdlib) ───────────────
# Outputs lines of the form: "<binary-key> <package-value>"
parse_section() {
  python3 - "$REGISTRY" "$1" <<'PYEOF'
import sys, re

registry, section = sys.argv[1], sys.argv[2]
in_section = False

with open(registry) as fh:
    for raw in fh:
        line = raw.rstrip('\n')
        stripped = line.lstrip()

        # Skip blank lines and full-line comments
        if not stripped or stripped.startswith('#'):
            continue

        # Top-level key (no leading whitespace)
        if not line[0:1].isspace():
            in_section = (stripped.rstrip(':') == section)
            continue

        if not in_section:
            continue

        # Indented entry: <key>: <value>  [# optional comment]
        m = re.match(r'\s+(\S+):\s*(\S.*)', line)
        if m:
            key   = m.group(1)
            value = re.sub(r'\s+#.*$', '', m.group(2)).strip()
            print(f"{key} {value}")
PYEOF
}

# ─── APT: special repository setup ───────────────────────────────────────────
# Called with the list of apt *package names* that are about to be installed.
# Configures third-party repos for packages not in the standard Ubuntu archives.
setup_apt_repos() {
  local need_update=false

  for pkg in "$@"; do
    case "$pkg" in
      eza)
        if [[ ! -f /etc/apt/sources.list.d/gierens.list ]]; then
          log "Configuring eza apt repository…"
          run_cmd mkdir -p /etc/apt/keyrings
          if [[ "$DRY_RUN" != "true" ]]; then
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
              | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
              | tee /etc/apt/sources.list.d/gierens.list >/dev/null
            chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
          fi
          need_update=true
        fi
        ;;
      terraform)
        if [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
          log "Configuring HashiCorp apt repository…"
          if [[ "$DRY_RUN" != "true" ]]; then
            wget -qO- https://apt.releases.hashicorp.com/gpg \
              | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
              | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
          fi
          need_update=true
        fi
        ;;
      helm)
        if [[ ! -f /etc/apt/sources.list.d/helm-stable-debian.list ]]; then
          log "Configuring Helm apt repository…"
          if [[ "$DRY_RUN" != "true" ]]; then
            curl -fsSL https://baltocdn.com/helm/signing.asc \
              | gpg --dearmor -o /usr/share/keyrings/helm.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] \
https://baltocdn.com/helm/stable/debian/ all main" \
              | tee /etc/apt/sources.list.d/helm-stable-debian.list >/dev/null
          fi
          need_update=true
        fi
        ;;
    esac
  done

  if [[ "$need_update" == "true" ]]; then
    log "Refreshing apt package lists after repo changes…"
    run_cmd apt-get update -qq
  fi
}

# ─── Provider: apt ───────────────────────────────────────────────────────────
install_apt() {
  log_section "APT"

  local -a to_install_keys=()   # binary names  (for skip-check)
  local -a to_install_pkgs=()   # package names (passed to apt-get)

  while read -r binary pkg; do
    [[ -z "$binary" ]] && continue
    is_binary_wanted "$binary" || continue

    # For bat on Debian/Ubuntu the actual binary may be called "batcat"
    local check_cmd="$binary"
    [[ "$binary" == "bat" ]] && check_cmd="batcat bat"

    if [[ "$SKIP_EXISTING" == "true" ]]; then
      local already=false
      for cmd in $check_cmd; do
        binary_exists "$cmd" && already=true && break
      done
      if [[ "$already" == "true" ]]; then
        log_skip "$binary (already installed)"
        continue
      fi
    fi

    to_install_keys+=("$binary")
    to_install_pkgs+=("$pkg")
    log "Queued: $binary  →  apt:$pkg"
  done < <(parse_section "apt")

  if (( ${#to_install_pkgs[@]} == 0 )); then
    log_ok "Nothing to install via apt"
    return 0
  fi

  setup_apt_repos "${to_install_pkgs[@]}"

  log "apt-get update…"
  run_cmd apt-get update -qq

  log "Installing ${#to_install_pkgs[@]} package(s): ${to_install_pkgs[*]}"
  if ! retry_cmd apt-get install -y --no-install-recommends "${to_install_pkgs[@]}"; then
    log_error "apt-get install failed for: ${to_install_pkgs[*]}"
    record_error "apt: install failed (${to_install_pkgs[*]})"
    return 0
  fi

  # Debian/Ubuntu ships bat as batcat — create a convenience symlink
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    log "Creating bat → batcat symlink in ${INSTALL_DIR}"
    run_cmd ln -sf "$(command -v batcat)" "${INSTALL_DIR}/bat"
  fi

  log_ok "apt packages installed"
}

# ─── Provider: go ────────────────────────────────────────────────────────────
install_go() {
  log_section "Go"

  if ! command -v go &>/dev/null; then
    log_warn "go not found — skipping go installs"
    return 0
  fi
  log "Go version: $(go version)"

  while read -r binary module; do
    [[ -z "$binary" ]] && continue
    is_binary_wanted "$binary" || continue

    if [[ "$SKIP_EXISTING" == "true" ]] && binary_exists "$binary"; then
      log_skip "$binary (already installed)"
      continue
    fi

    log "Installing $binary  →  go:$module"
    if ! retry_cmd env CGO_ENABLED=0 go install "$module"; then
      log_error "Failed: $binary ($module)"
      record_error "go: $binary"
    else
      log_ok "$binary"
    fi
  done < <(parse_section "go")
}

# ─── Provider: cargo ─────────────────────────────────────────────────────────
install_cargo() {
  log_section "Cargo"

  if ! command -v cargo &>/dev/null; then
    log_warn "cargo not found — skipping cargo installs"
    return 0
  fi
  log "Cargo version: $(cargo --version)"

  while read -r binary crate; do
    [[ -z "$binary" ]] && continue
    is_binary_wanted "$binary" || continue

    if [[ "$SKIP_EXISTING" == "true" ]] && binary_exists "$binary"; then
      log_skip "$binary (already installed)"
      continue
    fi

    log "Installing $binary  →  cargo:$crate"
    if ! retry_cmd cargo install --locked "$crate"; then
      log_error "Failed: $binary ($crate)"
      record_error "cargo: $binary"
    else
      log_ok "$binary"
    fi
  done < <(parse_section "cargo")
}

# ─── Provider: pip ────────────────────────────────────────────────────────────
install_pip() {
  log_section "Pip"

  local pip_cmd
  if command -v pip3 &>/dev/null; then
    pip_cmd="pip3"
  elif command -v pip &>/dev/null; then
    pip_cmd="pip"
  else
    log_warn "pip / pip3 not found — skipping pip installs"
    return 0
  fi
  log "Pip: $($pip_cmd --version)"

  local -a to_install=()

  while read -r binary pkg; do
    [[ -z "$binary" ]] && continue
    is_binary_wanted "$binary" || continue

    if [[ "$SKIP_EXISTING" == "true" ]] && binary_exists "$binary"; then
      log_skip "$binary (already installed)"
      continue
    fi

    to_install+=("$pkg")
    log "Queued: $binary  →  pip:$pkg"
  done < <(parse_section "pip")

  if (( ${#to_install[@]} == 0 )); then
    log_ok "Nothing to install via pip"
    return 0
  fi

  log "Installing ${#to_install[@]} package(s): ${to_install[*]}"
  if ! retry_cmd $pip_cmd install --upgrade "${to_install[@]}"; then
    log_error "pip install failed for: ${to_install[*]}"
    record_error "pip: install failed (${to_install[*]})"
  else
    log_ok "pip packages installed"
  fi
}

# ─── Provider: bun (npm section) ─────────────────────────────────────────────
install_bun() {
  log_section "Bun  (npm section)"

  if ! command -v bun &>/dev/null; then
    log_warn "bun not found — skipping npm/bun installs"
    return 0
  fi
  log "Bun version: $(bun --version)"

  while read -r binary pkg; do
    [[ -z "$binary" ]] && continue
    is_binary_wanted "$binary" || continue

    if [[ "$SKIP_EXISTING" == "true" ]] && binary_exists "$binary"; then
      log_skip "$binary (already installed)"
      continue
    fi

    log "Installing $binary  →  bun:$pkg"
    if ! retry_cmd bun add -g "$pkg"; then
      log_error "Failed: $binary ($pkg)"
      record_error "bun: $binary"
    else
      log_ok "$binary"
    fi
  done < <(parse_section "npm")
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
  echo -e "${BOLD}${BLUE}"
  echo    "╔══════════════════════════════════════════════╗"
  echo    "║        CI Binary Installer  ·  image build   ║"
  echo -e "╚══════════════════════════════════════════════╝${NC}"

  [[ "$DRY_RUN" == "true" ]] && log_warn "DRY-RUN mode — no changes will be made"

  log "Registry  : $REGISTRY"
  log "Managers  : $ACTIVE_MANAGERS"
  log "InstallDir: $INSTALL_DIR"
  [[ -n "$ONLY_BINARIES" ]] && log "Filter    : $ONLY_BINARIES"

  is_manager_active "apt"   && install_apt
  is_manager_active "go"    && install_go
  is_manager_active "cargo" && install_cargo
  is_manager_active "pip"   && install_pip
  is_manager_active "bun"   && install_bun

  # ─── Summary ────────────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${BLUE}══ Summary ══${NC}"
  if (( ${#ERRORS[@]} == 0 )); then
    log_ok "All installations completed successfully!"
  else
    log_error "${#ERRORS[@]} installation(s) failed:"
    for err in "${ERRORS[@]}"; do
      echo -e "  ${RED}•${NC} $err"
    done
    exit 1
  fi
}

main "$@"
