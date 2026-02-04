FROM node:lts-bookworm-slim

# Build arguments
ARG OPENCLAW_BETA=false
ARG GO_VERSION=1.23.4
ARG OPENCLAW_GATEWAY_PORT=18789

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_ROOT_USER_ACTION=ignore \
    OPENCLAW_BETA=${OPENCLAW_BETA} \
    OPENCLAW_NO_ONBOARD=1 \
    NPM_CONFIG_UNSAFE_PERM=true \
    OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT}

# =============================================================================
# SYSTEM DEPENDENCIES
# =============================================================================
# Combine all apt operations into a single layer and clean up aggressively
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    curl \
    wget \
    git \
    apt-utils \
    build-essential \
    software-properties-common \
    ca-certificates \
    gnupg \
    openssl \
    unzip \
    # Python stack
    python3 \
    python3-pip \
    python3-venv \
    # CLI tools
    jq \
    lsof \
    ripgrep \
    fd-find \
    fzf \
    bat \
    # Document processing
    pandoc \
    poppler-utils \
    ffmpeg \
    imagemagick \
    graphviz \
    # Databases & security
    sqlite3 \
    pass \
    # Browser
    chromium \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# DOCKER CLI
# =============================================================================
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# GO INSTALLATION
# =============================================================================
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o go.tar.gz && \
    echo "Downloading Go ${GO_VERSION}..." && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# =============================================================================
# GITHUB CLI
# =============================================================================
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# UV (Python tool manager)
# =============================================================================
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -fsSL https://astral.sh/uv/install.sh | sh && \
    rm -rf /tmp/*

# =============================================================================
# BUN INSTALLATION
# =============================================================================
ENV BUN_INSTALL_NODE=0 \
    BUN_INSTALL="/data/.bun"
RUN curl -fsSL https://bun.sh/install | bash && \
    rm -rf /tmp/*
ENV PATH="/data/.bun/bin:/data/.bun/install/global/bin:${PATH}"

# =============================================================================
# GLOBAL NODE/BUN PACKAGES
# =============================================================================
# Install Vercel, Marp, QMD
RUN bun install -g vercel @marp-team/marp-cli https://github.com/tobi/qmd && \
    hash -r && \
    bun pm -g untrusted

# Configure QMD Persistence
ENV XDG_CACHE_HOME="/data/.openclaw/cache"

# =============================================================================
# PYTHON TOOLS
# =============================================================================
RUN pip3 install --no-cache-dir --break-system-packages \
    ipython \
    csvkit \
    openpyxl \
    python-docx \
    pypdf \
    botasaurus \
    browser-use \
    playwright && \
    playwright install-deps && \
    rm -rf /tmp/* /datat/.cache

# =============================================================================
# COMMAND ALIASES
# =============================================================================
RUN ln -sf /usr/bin/fdfind /usr/bin/fd && \
    ln -sf /usr/bin/batcat /usr/bin/bat

# =============================================================================
# OPENCLAW INSTALLATION
# =============================================================================
RUN if [ "$OPENCLAW_BETA" = "true" ]; then \
        echo "Installing OpenClaw Beta..." && \
        npm install -g openclaw@beta; \
    else \
        echo "Installing OpenClaw Stable..." && \
        npm install -g openclaw; \
    fi && \
    # Verify installation
    if ! command -v openclaw >/dev/null 2>&1; then \
        echo "❌ OpenClaw install failed (binary 'openclaw' not found)"; \
        exit 1; \
    fi && \
    echo "✅ openclaw binary found" && \
    npm cache clean --force && \
    rm -rf /tmp/* /data/.npm/_cacache

# =============================================================================
# AI TOOL SUITE & CLAWHUB
# =============================================================================
RUN bun install -g \
    @openai/codex \
    @google/gemini-cli \
    opencode-ai \
    @steipete/summarize \
    @hyperbrowser/agent \
    clawhub && \
    # Claude CLI
    curl -fsSL https://claude.ai/install.sh | bash && \
    # Kimi CLI
    curl -fsSL https://code.kimi.com/install.sh | bash && \
    # Cleanup
    rm -rf /tmp/* /data/.bun/install/cache

# =============================================================================
# FINAL PATH CONSOLIDATION
# =============================================================================
ENV PATH="/usr/local/go/bin:\
/usr/local/bin:\
/usr/bin:\
/bin:\
/data/.local/bin:\
/data/.npm-global/bin:\
/data/.bun/bin:\
/data/.bun/install/global/bin:\
/data/.claude/bin:\
/data/.kimi/bin:\
/data/go/bin"

# =============================================================================
# APPLICATION SETUP
# =============================================================================
WORKDIR /app

# Copy application files (respecting .dockerignore)
COPY . .

# Setup symlinks and permissions in a single layer
RUN ln -sf /data/.claude/bin/claude /usr/local/bin/claude 2>/dev/null || true && \
    ln -sf /data/.kimi/bin/kimi /usr/local/bin/kimi 2>/dev/null || true && \
    ln -sf /app/scripts/openclaw-approve.sh /usr/local/bin/openclaw-approve && \
    find /app/scripts -type f -name "*.sh" -exec chmod +x {} \; && \
    chmod +x /usr/local/bin/openclaw-approve

# =============================================================================
# HEALTHCHECK
# =============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${OPENCLAW_GATEWAY_PORT}/health || exit 1

# =============================================================================
# RUNTIME
# =============================================================================
EXPOSE ${OPENCLAW_GATEWAY_PORT}

# Use exec form for better signal handling
CMD ["bash", "/app/scripts/bootstrap.sh"]
