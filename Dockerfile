# Dockerfile for ClawOSS V11
FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    python3-pip \
    jq \
    bc \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw

# Create app directory
WORKDIR /app

# Copy package files (if any)
COPY package*.json ./
RUN npm install || true

# Copy project files
COPY . .

# Create necessary directories
RUN mkdir -p /root/.openclaw/logs \
    && mkdir -p workspace/memory/repos \
    && mkdir -p workspace/memory/issues \
    && mkdir -p workspace/memory/locks \
    && mkdir -p workspace/memory/subagent-inputs

# Initialize budget files
RUN echo "100.0" > workspace/memory/budget-max.txt \
    && echo "0.0" > workspace/memory/budget-spent.txt

# Make scripts executable
RUN chmod +x scripts/*.sh

# Expose OpenClaw gateway port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD openclaw gateway status || exit 1

# Set environment variables
ENV NODE_ENV=production
ENV OPENCLAW_HOME=/root/.openclaw

# Start script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash", "scripts/restart.sh"]
