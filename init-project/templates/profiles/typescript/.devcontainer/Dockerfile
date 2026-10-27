# Dev container for a TypeScript / Node project.
# Base: Node.js 24 LTS on Debian bookworm, run as the non-root `node` user.
# No docker-in-docker (see devcontainer.json for the rationale).

# Digest-pinned tag: 24-bookworm (Dockerfiles do not allow inline comments,
# so the human-readable tag lives here). To update, resolve the tag's current
# digest: `docker manifest inspect mcr.microsoft.com/devcontainers/typescript-node:24-bookworm`.
FROM mcr.microsoft.com/devcontainers/typescript-node@sha256:970eebf5b82d3800bdd9f46680e1c4c664d365d18603148540788356700ce301

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
