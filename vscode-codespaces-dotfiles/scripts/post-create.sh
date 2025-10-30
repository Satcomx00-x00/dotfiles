#!/bin/bash

# Post-create hook for GitHub Codespaces; delegates to the install script.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

bash "${SCRIPT_DIR}/install.sh"