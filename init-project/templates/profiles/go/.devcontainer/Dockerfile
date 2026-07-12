# Dev container for Go projects.
# Base: official Go dev container image (Go 1.25 on Debian bookworm), which ships
# the toolchain and a non-root `vscode` user.

# Digest-pinned tag: 2-1.25-bookworm (Dockerfiles do not allow inline comments,
# so the human-readable tag lives here). To update, resolve the tag's current
# digest: `docker manifest inspect mcr.microsoft.com/devcontainers/go:2-1.25-bookworm`.
FROM mcr.microsoft.com/devcontainers/go@sha256:f8f841c474489d6cd5b67cb30ee0e56ae5f1379f0bdf2679191573c41b5e11f8

# System deps commonly needed for builds and tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install the linters the qa/fix scripts use, as the vscode user so the binaries
# land on its PATH ($GOPATH/bin). The base image already provides go, gofmt, vet.
# Versions are pinned for reproducibility. golangci-lint is on the v2 line (v1 is
# EOL and does not support Go 1.25); note the required `/v2/` module path. Keep
# this version in lockstep with the CI install step and the .golangci.yml schema
# (which is `version: "2"`).
USER vscode
RUN go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.12.2 \
    && go install golang.org/x/tools/cmd/goimports@v0.47.0
ENV PATH="/home/vscode/go/bin:${PATH}"

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
