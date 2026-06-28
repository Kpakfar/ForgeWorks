# Dev container for a TypeScript / Node project.
# Base: Node.js 22 LTS on Debian bookworm, run as the non-root `node` user.
# No docker-in-docker (see devcontainer.json for the rationale).

FROM mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm

# Install handy CLI tools (git and a recent Node toolchain ship in the base).
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Run as the unprivileged user the base image provides.
USER node

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
