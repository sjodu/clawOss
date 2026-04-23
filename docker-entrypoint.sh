#!/bin/bash
set -e

echo "=== ClawOSS V11 Container Starting ==="

# Validate required environment variables
if [ -z "${LLM_API_KEY:-}" ]; then
    echo "ERROR: LLM_API_KEY is required"
    exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "ERROR: GITHUB_TOKEN is required"
    exit 1
fi

# Set defaults
export LLM_PROVIDER="${LLM_PROVIDER:-openai}"
export LLM_MODEL="${LLM_MODEL:-gpt-4o-mini}"
export LLM_BASE_URL="${LLM_BASE_URL:-https://api.openai.com/v1}"
export LLM_CONTEXT_WINDOW="${LLM_CONTEXT_WINDOW:-128000}"
export LLM_MAX_TOKENS="${LLM_MAX_TOKENS:-4096}"
export LLM_COST_INPUT="${LLM_COST_INPUT:-0.15}"
export LLM_COST_OUTPUT="${LLM_COST_OUTPUT:-0.6}"
export BUDGET_MAX_USD="${BUDGET_MAX_USD:-100.0}"
export GITHUB_USERNAME="${GITHUB_USERNAME:-ClawOSS}"
export GITHUB_EMAIL="${GITHUB_EMAIL:-clawoss@users.noreply.github.com}"

echo "Configuration:"
echo "  LLM: $LLM_PROVIDER/$LLM_MODEL"
echo "  Budget: \$$BUDGET_MAX_USD"
echo "  GitHub: $GITHUB_USERNAME"

# Configure Git
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global --add safe.directory /app

# Authenticate GitHub CLI
echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
if gh auth status >/dev/null 2>&1; then
    echo "✅ GitHub CLI authenticated"
else
    echo "⚠️  GitHub CLI authentication failed"
fi

# Update budget files with environment variable
echo "$BUDGET_MAX_USD" > workspace/memory/budget-max.txt
if [ ! -f workspace/memory/budget-spent.txt ]; then
    echo "0.0" > workspace/memory/budget-spent.txt
fi

# Create python symlink if needed
if ! command -v python &>/dev/null && command -v python3 &>/dev/null; then
    ln -sf "$(which python3)" /usr/local/bin/python
fi

echo "=== Starting ClawOSS ==="

# Execute the command
exec "$@"
