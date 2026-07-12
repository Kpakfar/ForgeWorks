# Dev container for Rust projects.
# Base: official Rust dev container image (Debian bookworm), which ships rustup,
# cargo, and a non-root `vscode` user. The image tag tracks the Rust 1.x line;
# the EXACT toolchain is pinned by rust-toolchain.toml, which rustup resolves
# automatically inside the container.

FROM mcr.microsoft.com/devcontainers/rust:1-1-bookworm

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
