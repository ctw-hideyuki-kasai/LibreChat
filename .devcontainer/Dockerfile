# LibreChat DevContainer Dockerfile
FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    make \
    g++ \
    jemalloc \
    bash \
    curl \
    openssh-client \
    sudo

# Install uv for extended MCP support
COPY --from=ghcr.io/astral-sh/uv:0.6.13 /uv /uvx /bin/
RUN uv --version

# Set environment variable to use jemalloc
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

# Create app directory
WORKDIR /workspaces

# Set npm configuration for better reliability
RUN npm config set fetch-retry-maxtimeout 600000 && \
    npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 15000

# Create vscode user with sudo privileges (for npm global installs)
RUN addgroup -g 1000 vscode && \
    adduser -u 1000 -G vscode -s /bin/bash -D vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /workspaces && \
    chown -R vscode:vscode /workspaces

# Switch to vscode user
USER vscode

# Set default command
CMD ["/bin/sh", "-c", "while sleep 1000; do :; done"]
