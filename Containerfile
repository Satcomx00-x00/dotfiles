# Containerfile for dotfiles development and testing environment
# This provides a containerized environment with all tools pre-installed
#
# ARCHITECTURE NOTE:
# Unlike local installations where chezmoi runs the .chezmoiscripts/ during `apply`,
# this container has all installations baked in at build time for:
# - Faster container startup
# - Consistent development environment
# - No runtime dependencies on external package repositories
# - Easier testing and CI/CD integration
#
# The .chezmoiscripts/ are still maintained for local user installations.

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# ── Base system packages ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    unzip \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ── Go (required by install-binaries.sh for the go provider) ─────────────────
ARG GO_VERSION=1.22.4
RUN ARCH="$(uname -m)" && \
    case "$ARCH" in x86_64) GOARCH=amd64 ;; aarch64) GOARCH=arm64 ;; *) GOARCH="$ARCH" ;; esac && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" \
        | tar -C /usr/local -xz && \
    ln -sf /usr/local/go/bin/go   /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

ENV GOPATH=/go
ENV PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"

# ── Bun (used in place of npm — required for the npm/bun provider) ────────────
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# ── Copy CI scripts early (maximises Docker layer caching) ────────────────────
COPY ci/ /ci/

# ── Run the binary installer ──────────────────────────────────────────────────
# Installs: bat, btop, eza, fzf, helm, htop, k9s, terraform, zoxide, age, jq, yq, direnv, mkcert, sops (apt/direct)
#           helm-docs, kopia, kubectx, kubens, kubecolor, stern, helmfile, … (go)
#           fd, zellij, bob, rg, kyverno (github releases — pre-built musl/official binaries)
#           pipreqs, ruff, uv (pip)
#           bun (bun/npm)
RUN chmod +x /ci/install-binaries.sh && \
    /ci/install-binaries.sh && \
    rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh (system-wide)
ENV ZSH=/usr/share/oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    mv /root/.oh-my-zsh ${ZSH} && \
    chmod -R 755 ${ZSH}

# Install Powerlevel10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH}/custom/themes/powerlevel10k

# Install Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH}/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH}/custom/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-completions ${ZSH}/custom/plugins/zsh-completions && \
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH}/custom/plugins/fzf-tab

# Install fzf (junegunn/fzf) for keybindings and completion
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /usr/share/fzf && \
    /usr/share/fzf/install --key-bindings --completion --no-update-rc --no-fish

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Set Zsh as default shell
RUN chsh -s "$(which zsh)" root

# Set working directory
WORKDIR /dotfiles

# Copy dotfiles repository
COPY . /dotfiles

# Verify key installations
RUN zsh --version && \
    git --version && \
    go version && \
    bat --version && \
    btop --version && \
    eza --version && \
    fd --version && \
    rg --version && \
    bob --version && \
    zellij --version && \
    kyverno version && \
    zoxide --version && \
    kubectx --version && \
    terraform version && \
    k9s version

# Default to zsh
SHELL ["/bin/zsh", "-c"]
CMD ["/bin/zsh"]
