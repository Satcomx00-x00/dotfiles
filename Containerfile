# Dev/test container that runs the REAL bootstrap (chezmoi init --apply) so the
# image reflects exactly what a user gets — no separately-maintained install path.
#
#   docker build -f Containerfile -t dotfiles:debian .
#   docker build -f Containerfile --build-arg BASE=alpine:3.20    -t dotfiles:alpine .
#   docker build -f Containerfile --build-arg BASE=rockylinux:9   -t dotfiles:rocky  .
#   docker run --rm -it dotfiles:debian
#
# Tools are skipped at build time (DOTFILES_SKIP_MISE_TOOLS=1) to keep images lean
# and builds fast; run `mise install` inside the container to fetch the full toolset.
ARG BASE=debian:12
FROM ${BASE}

ARG USER=dev
ENV DOTFILES_SKIP_MISE_TOOLS=1 \
    ZELLIJ_SKIP=1 \
    DEBIAN_FRONTEND=noninteractive

# Minimal prerequisites + a non-root sudo user (covers apt / apk / dnf|yum).
RUN set -eu; \
    if   command -v apt-get >/dev/null 2>&1; then \
        apt-get update -qq && apt-get install -y --no-install-recommends git curl ca-certificates sudo; \
    elif command -v apk >/dev/null 2>&1; then \
        apk add --no-cache git curl bash sudo shadow; \
    elif command -v dnf >/dev/null 2>&1; then \
        dnf install -y git curl sudo shadow-utils; \
    elif command -v yum >/dev/null 2>&1; then \
        yum install -y git curl sudo shadow-utils; \
    fi; \
    ( useradd -m -s /bin/sh "$USER" 2>/dev/null || adduser -D -s /bin/sh "$USER" ); \
    ( echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER ) && chmod 0440 /etc/sudoers.d/$USER

COPY --chown=dev:dev . /home/${USER}/.local/share/chezmoi
USER ${USER}
WORKDIR /home/${USER}

# Run the same flow the README documents, against the copied local source.
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
        --source="$HOME/.local/share/chezmoi" -b "$HOME/.local/bin" \
        --promptString name="Dev User" \
        --promptString email="dev@example.com" \
        --promptString editor="vim" \
        --promptChoice machineType=server \
        --promptBool gpgSign=false \
        --promptString signingKey="" \
        --promptString workEmail="" \
        --promptBool headless=true

ENV PATH="/home/${USER}/.local/bin:${PATH}"
CMD ["/bin/zsh", "-l"]
