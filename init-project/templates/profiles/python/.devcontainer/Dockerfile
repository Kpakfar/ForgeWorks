# Dev container for this project.
# Base: Python 3.12 slim, with uv installed for the non-root user.
# Capability dependencies (database clients, system libs for native wheels, ...)
# are appended by /init-project only when the interview asks for them -- keep
# this image minimal by default.

FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# Minimal system deps: compiler for native wheels, plus the basics.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install uv (Astral's fast Python package manager) for the vscode user --
# the container runs as vscode (see devcontainer.json), so a root install
# would be dead weight.
USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
