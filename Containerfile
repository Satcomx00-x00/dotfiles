# Containerfile for dotfiles development and testing environment
# This provides a containerized environment with k9s and other tools

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install k9s
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

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Set working directory
WORKDIR /dotfiles

# Copy dotfiles repository
COPY . /dotfiles

# Verify k9s installation
RUN k9s version

# Default command
CMD ["/bin/bash"]
