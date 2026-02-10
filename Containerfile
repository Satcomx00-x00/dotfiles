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

# Install essential packages
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    unzip \
    fzf \
    ripgrep \
    fd-find \
    bat \
    htop \
    ncdu \
    jq \
    tree \
    sudo \
    gpg \
    && rm -rf /var/lib/apt/lists/*

# Install eza (modern ls replacement)
RUN mkdir -p /etc/apt/keyrings && \
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
    apt-get update && \
    apt-get install -y eza && \
    rm -rf /var/lib/apt/lists/*

# Install zoxide (smart cd)
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Create bat symlink (Debian/Ubuntu ships bat as batcat)
RUN mkdir -p /usr/local/bin && \
    ln -sf "$(command -v batcat)" /usr/local/bin/bat && \
    chmod +x /usr/local/bin/bat

# Install k9s - Kubernetes CLI To Manage Your Clusters In Style!
RUN ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; then K9S_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then K9S_ARCH="arm64"; \
    else K9S_ARCH="$ARCH"; fi && \
    K9S_VERSION="0.32.4" && \
    curl -sL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz" -o /tmp/k9s.tar.gz && \
    tar xzf /tmp/k9s.tar.gz -C /tmp && \
    mv /tmp/k9s /usr/local/bin/k9s && \
    chmod +x /usr/local/bin/k9s && \
    rm -rf /tmp/*

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

# Verify installations
RUN k9s version && \
    zsh --version && \
    git --version && \
    fzf --version && \
    eza --version && \
    zoxide --version && \
    bat --version

# Default to zsh
SHELL ["/bin/zsh", "-c"]
CMD ["/bin/zsh"]
