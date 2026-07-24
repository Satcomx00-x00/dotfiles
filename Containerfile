# syntax=docker/dockerfile:1
#
# Decision #36: the full standard-tier toolchain, pre-baked.
#
# A container that bootstraps on every launch costs ~4 minutes each time and
# needs a network. This image pays that once, at build time, and starts in
# seconds. ~1.2 GB is the price, and for a dev container that is the right trade.
#
#   docker build -f Containerfile -t dotfiles .
#   docker run --rm -it dotfiles
#
# Also the base for .devcontainer/devcontainer.json (Codespaces, VS Code).

FROM debian:12-slim

# The `container` profile: no fonts, no terminal emulator config, no chsh (the
# image sets the shell below), no Zellij autostart. See report.md §3.
ARG PROFILE=container
ARG TIER=standard

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/root \
    PATH=/root/.local/bin:/root/.local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Only what the bootstrap itself needs. Everything else — including zsh — is
# installed by the repository's own base-layer script, so the image and a real
# machine take exactly the same path and cannot diverge.
RUN apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
        ca-certificates curl git sudo locales \
    && rm -rf /var/lib/apt/lists/*

# Cache-friendly ordering: the data files change far less often than the shell
# configuration, so a tweak to an alias does not re-download 45 tools.
WORKDIR /src
COPY .chezmoiroot ./
COPY home/.chezmoidata/ ./home/.chezmoidata/
COPY home/.chezmoi.toml.tmpl home/.chezmoiversion home/.chezmoiignore home/.chezmoiexternal.toml.tmpl ./home/
COPY test/prompts.sh ./test/

# chezmoi, then the full apply. DOTFILES_SKIP_MISE_TOOLS is deliberately NOT set:
# baking the tools in is the entire point of this image.
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /root/.local/bin

COPY . /src

RUN chezmoi init --apply --source=/src --no-tty \
        --promptChoice "Machine profile=${PROFILE}" \
        --promptChoice "Tool tier=${TIER}" \
        --promptChoice "Secrets backend=none" \
        --promptBool "Enable SSH commit signing=false" \
        --promptString "SSH signing key path=" \
    && chezmoi purge --force 2>/dev/null || true

# Neovim's plugins were synced by the apply above (phase 7), so the first real
# launch is instant rather than a two-minute download.

# zsh is now installed by the base layer; make it the shell for `docker exec`
# and for anything that respects /etc/passwd.
RUN chsh -s "$(command -v zsh)" root || true

# Never start a multiplexer inside a container: it is already a single-purpose
# session, and nesting it breaks `docker exec` and `docker run -it` alike.
ENV ZELLIJ_SKIP=1 \
    SHELL=/usr/bin/zsh

WORKDIR /workspace
CMD ["/usr/bin/zsh", "-l"]
