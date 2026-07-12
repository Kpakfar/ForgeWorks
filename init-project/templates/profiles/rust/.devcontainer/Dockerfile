# Dev container for Rust projects.
# Base: official Rust dev container image (Debian bookworm), which ships rustup,
# cargo, and a non-root `vscode` user. The image tag tracks the Rust 1.x line;
# the EXACT toolchain is pinned by rust-toolchain.toml, which rustup resolves
# automatically inside the container.

# Digest-pinned tag: 1-1-bookworm (Dockerfiles do not allow inline comments,
# so the human-readable tag lives here). To update, resolve the tag's current
# digest: `docker manifest inspect mcr.microsoft.com/devcontainers/rust:1-1-bookworm`.
FROM mcr.microsoft.com/devcontainers/rust@sha256:fc57fb865035c5395e85246c8842b071ced6e7cde727b3c98abbcc794eaf4759

# System deps commonly needed for builds and tooling. pkg-config + libssl-dev
# cover the common native-TLS / openssl-sys crates.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    jq \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Pre-install the pinned toolchain (with clippy + rustfmt) as the vscode user so
# the first qa run does not stall on a toolchain download. Keep this version in
# lockstep with rust-toolchain.toml and the CI toolchain step.
USER vscode
RUN rustup toolchain install 1.96 --component clippy --component rustfmt \
    && rustup default 1.96

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
