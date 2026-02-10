.PHONY: help install install-scripts update status diff apply clean test validate doctor shellcheck container-build container-run container-shell

# Default target
help:
	@echo "Dotfiles Makefile Commands:"
	@echo ""
	@echo "  make install        - Install dotfiles using chezmoi"
	@echo "  make install-scripts - Install scripts from chezmoiscripts"
	@echo "  make update         - Update dotfiles from repository"
	@echo "  make reinit         - Reinitialize from local directory (for development)"
	@echo "  make status         - Show chezmoi status"
	@echo "  make diff           - Show differences between current and source"
	@echo "  make apply          - Apply pending changes"
	@echo "  make clean          - Remove chezmoi state (careful!)"
	@echo "  make test           - Test installation in Docker"
	@echo "  make container-build - Build the development container with k9s"
	@echo "  make container-run  - Run the development container"
	@echo "  make container-shell - Open a shell in the development container"
	@echo "  make validate       - Validate templates"
	@echo "  make doctor         - Run chezmoi doctor"
	@echo "  make shellcheck     - Check shell scripts with shellcheck"
	@echo ""

# Install dotfiles
install:
	@echo "Installing chezmoi..."
	@sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
	@echo "Initializing dotfiles..."
	@~/.local/bin/chezmoi init --apply

# Update from repository
update:
	@chezmoi update -v

# Reinitialize from local directory (for development)
reinit:
	@echo "Reinitializing chezmoi from local directory..."
	@chezmoi init --apply --source=$$(pwd)
	@echo "✅ Reinitialized and applied."

# Show status
status:
	@chezmoi status

# Show differences
diff:
	@chezmoi diff

# Apply changes
apply:
	@chezmoi apply -v

# Clean state
clean:
	@echo "⚠️  This will reset chezmoi state. Continue? [y/N]"
	@read -r response && [ "$$response" = "y" ] || exit 1
	@chezmoi state reset
	@echo "State reset complete"

# Test in Docker containers
test:
	@echo "Testing on Ubuntu 22.04..."
	@docker run --rm -v "$$(pwd):/dotfiles" ubuntu:22.04 bash -c "\
		apt-get update -qq && \
		apt-get install -y curl git && \
		sh -c \"\$$(curl -fsLS https://get.chezmoi.io)\" -- --bin-dir /usr/local/bin && \
		chezmoi init --dry-run --verbose /dotfiles && \
		echo '✅ Ubuntu 22.04 test passed'"
	@echo ""
	@echo "Testing on Alpine..."
	@docker run --rm -v "$$(pwd):/dotfiles" alpine:latest sh -c "\
		apk add --no-cache curl git bash && \
		sh -c \"\$$(curl -fsLS https://get.chezmoi.io)\" -- --bin-dir /usr/local/bin && \
		chezmoi init --dry-run --verbose /dotfiles && \
		echo '✅ Alpine test passed'"

# Validate templates
validate:
	@echo "Validating templates..."
	@mkdir -p ~/.config/chezmoi
	@if [ ! -f ~/.config/chezmoi/chezmoi.toml ]; then \
		echo '[data]' > ~/.config/chezmoi/chezmoi.toml; \
		echo '  name = "Test User"' >> ~/.config/chezmoi/chezmoi.toml; \
		echo '  email = "test@example.com"' >> ~/.config/chezmoi/chezmoi.toml; \
		echo '  editor = "vim"' >> ~/.config/chezmoi/chezmoi.toml; \
		echo '  gpgSign = false' >> ~/.config/chezmoi/chezmoi.toml; \
	fi
	@for template in $$(find home -name "*.tmpl"); do \
		echo "Validating: $$template"; \
		chezmoi execute-template < "$$template" > /dev/null || exit 1; \
	done
	@echo "✅ All templates valid"

# Run chezmoi doctor
doctor:
	@chezmoi doctor

# Check shell scripts with shellcheck
shellcheck:
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck..."; \
		find .chezmoiscripts -name "*.sh" -exec shellcheck {} \; ; \
		echo "✅ Shellcheck complete"; \
	else \
		echo "⚠️  shellcheck not installed"; \
	fi

# Install scripts from chezmoiscripts
install-scripts:
	@echo "Installing scripts from chezmoiscripts..."
	@for script in $$(find .chezmoiscripts -name "*.sh"); do \
		echo "Running $$script"; \
		chezmoi execute-template < "$$script" | bash; \
	done
	@echo "✅ Scripts installed"

# Build the development container with k9s
container-build:
	@echo "Building development container with k9s..."
	@docker build -f Containerfile -t dotfiles-dev:latest .
	@echo "✅ Container built successfully"

# Run the development container
container-run:
	@echo "Running development container..."
	@docker run --rm -it dotfiles-dev:latest

# Open a shell in the development container
container-shell:
	@echo "Opening shell in development container..."
	@docker run --rm -it dotfiles-dev:latest /bin/bash
	done
	@echo "✅ Scripts installed"
