# Dev container for Go projects.
# Base: official Go dev container image (Go 1.22 on Debian bookworm), which ships
# the toolchain and a non-root `vscode` user.

FROM mcr.microsoft.com/devcontainers/go:1-1.22-bookworm

# System deps commonly needed for builds and tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install the linters the qa/fix scripts use, as the vscode user so the binaries
# land on its PATH ($GOPATH/bin). The base image already provides go, gofmt, vet.
# Versions are pinned for reproducibility. golangci-lint is held on the v1 line
# because .golangci.yml uses the v1 config schema; bump both together if you
# migrate the config to the v2 schema.
USER vscode
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.61.0 \
    && go install golang.org/x/tools/cmd/goimports@v0.25.0
ENV PATH="/home/vscode/go/bin:${PATH}"

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
