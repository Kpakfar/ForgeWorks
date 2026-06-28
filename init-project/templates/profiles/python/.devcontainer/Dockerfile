# Dev container for python-rag projects.
# Base: Python 3.12 slim, with uv pre-installed.
# Postgres + pgvector run as a separate service via docker-compose if needed,
# or you can use the included docker-in-docker feature.

FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# Install system deps for psycopg, lxml, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install uv (Astral's fast Python package manager).
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin:${PATH}"

# Make sure vscode user can use uv too.
USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Working directory is set by VS Code from devcontainer.json
WORKDIR /workspace
