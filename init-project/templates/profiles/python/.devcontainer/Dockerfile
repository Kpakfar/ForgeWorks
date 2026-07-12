# Dev container for this project.
# Base: Python 3.12 slim, with uv installed for the non-root user.
# Capability dependencies (database clients, system libs for native wheels, ...)
# are appended by /init-project only when the interview asks for them -- keep
# this image minimal by default.

# Digest-pinned tag: 1-3.12-bookworm (Dockerfiles do not allow inline comments,
# so the human-readable tag lives here). To update, resolve the tag's current
# digest: `docker manifest inspect mcr.microsoft.com/devcontainers/python:1-3.12-bookworm`.
FROM mcr.microsoft.com/devcontainers/python@sha256:7876580dc67fd460fd962f004cbeb480027e9bbc0657096f1087db11f9eaff39

# Minimal system deps: compiler for native wheels, plus the basics.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install uv (Astral's fast Python package manager) for the vscode user --
# the container runs as vscode (see devcontainer.json), so a root install
# would be dead weight. The installer is version-pinned and checksum-verified
# (no pipe-to-shell). To update: bump UV_VERSION, download that release's
# uv-installer.sh, and record its sha256 here.
USER vscode
ARG UV_VERSION=0.11.28
ARG UV_INSTALLER_SHA256=b7b3fe80cad1142a2a5794050b7db7b3291d1bac1423b0732571dd9366e8ca8b
RUN curl -LsSf -o /tmp/uv-installer.sh \
      "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-installer.sh" \
    && echo "${UV_INSTALLER_SHA256}  /tmp/uv-installer.sh" | sha256sum -c - \
    && sh /tmp/uv-installer.sh \
    && rm /tmp/uv-installer.sh
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
