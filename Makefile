# Local entry points. Every CI job is one of these targets, so anything that
# fails in CI can be reproduced here with the same command.

SHELL      := /bin/sh
ROOT       := $(CURDIR)
IMAGE      ?= debian:12
PROFILE    ?= server
TIER       ?= standard

# mise puts the dev toolchain on PATH without needing an activated shell.
export PATH := $(HOME)/.local/bin:$(shell mise bin-paths 2>/dev/null | tr '\n' ':')$(PATH)

.DEFAULT_GOAL := help
.PHONY: help dev-tools render lint lint-help theme-check check \
        verify-tools verify-externals verify-zellij verify-portable \
        sandbox sandbox-all sandbox-full bench portable docs \
        install update doctor clean

help: ## Show this help
	@printf 'dotfiles — make targets\n\n'
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / \
		{ printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nsandbox knobs: IMAGE=%s PROFILE=%s TIER=%s\n' '$(IMAGE)' '$(PROFILE)' '$(TIER)'

# ─── Development toolchain ───────────────────────────────────────────────────

dev-tools: ## Install chezmoi + linters used by the checks below
	@command -v chezmoi >/dev/null 2>&1 || \
		sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b "$(HOME)/.local/bin"
	@command -v mise >/dev/null 2>&1 || \
		curl -fsSL https://mise.run | MISE_INSTALL_PATH="$(HOME)/.local/bin/mise" sh
	@mise install

# ─── Fast checks: no container, no network ───────────────────────────────────

render: ## Render every template against every fixture
	@sh test/render.sh

lint: render ## shellcheck, syntax, shfmt, toml, lua, pin rule
	@sh test/lint.sh

lint-help: render ## Fail on any undocumented alias or function
	@sh test/lint-help.sh

theme-check: ## Prove theme.toml reaches exactly its declared consumers
	@sh test/theme-check.sh

verify-tools: ## Resolve every backend in tools.toml against upstream (network)
	@sh test/verify-tools.sh

verify-externals: ## Check every chezmoi external URL is reachable (network)
	@sh test/verify-externals.sh

verify-zellij: ## Parse the generated KDL with a real zellij binary
	@sh test/verify-zellij.sh

verify-portable: portable ## Source portable.sh on a bare container and assert it works
	@sh test/verify-portable.sh

check: lint lint-help theme-check ## Everything that does not need docker
	@printf '\ncheck: OK\n'

# ─── Container checks ────────────────────────────────────────────────────────

sandbox: ## Bootstrap into a throwaway container (IMAGE/PROFILE/TIER)
	@sh test/sandbox.sh '$(IMAGE)' '$(PROFILE)' '$(TIER)'

sandbox-all: ## Sandbox across the distro and profile matrix
	@sh test/sandbox.sh debian:12   server      standard
	@sh test/sandbox.sh alpine:3.20 container   minimal
	@sh test/sandbox.sh ubuntu:24.04 workstation full

sandbox-full: ## Sandbox with the real tool downloads (slow, the true end-to-end)
	@DOTFILES_SKIP_MISE_TOOLS=0 sh test/sandbox.sh '$(IMAGE)' '$(PROFILE)' '$(TIER)'

bench: ## Measure interactive shell startup against the 60 ms budget
	@sh test/bench.sh '$(IMAGE)'

# ─── Generated artefacts (each has a CI freshness gate) ──────────────────────

portable: ## Regenerate portable.sh from the shared shell layer
	@sh scripts/gen-portable.sh

docs: ## Regenerate the generated sections of README.md
	@sh scripts/gen-docs.sh

# ─── Day-2 ───────────────────────────────────────────────────────────────────

install: ## Apply this working tree to THIS machine
	@chezmoi init --apply --source="$(ROOT)"

update: ## Pull and apply
	@chezmoi update --source="$(ROOT)"

doctor: ## Health check on this machine
	@chezmoi doctor --source="$(ROOT)"
	@command -v dotfiles >/dev/null 2>&1 && dotfiles doctor || true

clean: ## Remove build output
	@rm -rf $(ROOT)/.build
