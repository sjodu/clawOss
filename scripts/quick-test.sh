#!/usr/bin/env bash
# ClawOSS Quick Configuration Test — Verify LLM config and budget setup

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== ClawOSS V11 Quick Configuration Test ==="
echo ""

# Load .env
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
  echo "[1/5] ✅ Loaded .env"
else
  echo "[1/5] ❌ No .env file found"
  echo "       Copy .env.example to .env and configure it"
  exit 1
fi

# Check required environment variables
echo "[2/5] Checking environment variables..."
MISSING=()
[ -z "${LLM_PROVIDER:-}" ] && MISSING+=("LLM_PROVIDER")
[ -z "${LLM_MODEL:-}" ] && MISSING+=("LLM_MODEL")
[ -z "${LLM_API_KEY:-}" ] && MISSING+=("LLM_API_KEY")
[ -z "${GITHUB_TOKEN:-}" ] && MISSING+=("GITHUB_TOKEN")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "      ❌ Missing required variables: ${MISSING[*]}"
  exit 1
fi

echo "      ✅ LLM_PROVIDER: $LLM_PROVIDER"
echo "      ✅ LLM_MODEL: $LLM_MODEL"
echo "      ✅ LLM_API_KEY: ${LLM_API_KEY:0:10}..."
echo "      ✅ BUDGET_MAX_USD: ${BUDGET_MAX_USD:-100.0}"

# Test configuration generation
echo "[3/5] Testing configuration generation..."
DEPLOYED_CONFIG="$HOME/.openclaw/openclaw.json"

# Run the config generation part of restart.sh
LLM_PROVIDER="${LLM_PROVIDER:-openai}" \
LLM_MODEL="${LLM_MODEL:-gpt-4o-mini}" \
LLM_API_KEY="${LLM_API_KEY}" \
LLM_BASE_URL="${LLM_BASE_URL:-https://api.openai.com/v1}" \
LLM_CONTEXT_WINDOW="${LLM_CONTEXT_WINDOW:-128000}" \
LLM_MAX_TOKENS="${LLM_MAX_TOKENS:-4096}" \
LLM_COST_INPUT="${LLM_COST_INPUT:-0.15}" \
LLM_COST_OUTPUT="${LLM_COST_OUTPUT:-0.6}" \
python3 -c "
import json
config = {
  'agents': {
    'defaults': {
      'model': {
        'primary': '${LLM_PROVIDER}/${LLM_MODEL}',
        'fallbacks': []
      }
    }
  },
  'models': {
    'providers': {
      '${LLM_PROVIDER}': {
        'baseUrl': '${LLM_BASE_URL}',
        'apiKey': '${LLM_API_KEY}',
        'models': [{
          'id': '${LLM_MODEL}',
          'contextWindow': int('${LLM_CONTEXT_WINDOW}'),
          'maxTokens': int('${LLM_MAX_TOKENS}'),
          'cost': {
            'input': float('${LLM_COST_INPUT}'),
            'output': float('${LLM_COST_OUTPUT}')
          }
        }]
      }
    }
  }
}
print('Config structure valid')
" || {
  echo "      ❌ Configuration generation failed"
  exit 1
}

echo "      ✅ Configuration structure valid"

# Check budget files
echo "[4/5] Checking budget tracking..."
mkdir -p "$PROJECT_DIR/workspace/memory"
BUDGET_MAX_FILE="$PROJECT_DIR/workspace/memory/budget-max.txt"
BUDGET_SPENT_FILE="$PROJECT_DIR/workspace/memory/budget-spent.txt"

echo "${BUDGET_MAX_USD:-100.0}" > "$BUDGET_MAX_FILE"
if [ ! -f "$BUDGET_SPENT_FILE" ]; then
  echo "0.0" > "$BUDGET_SPENT_FILE"
fi

echo "      ✅ Budget files initialized"

# Verify OpenClaw is installed
echo "[5/5] Checking OpenClaw installation..."
if ! command -v openclaw &>/dev/null; then
  echo "      ❌ openclaw command not found"
  echo "         Install OpenClaw first"
  exit 1
fi

echo "      ✅ OpenClaw installed: $(openclaw --version 2>&1 | head -1 || echo 'version unknown')"

# Summary
echo ""
echo "╔════════════════════════════════════════╗"
echo "║   Configuration Test PASSED ✅          ║"
echo "╠════════════════════════════════════════╣"
printf "║ Provider: %-28s ║\n" "$LLM_PROVIDER"
printf "║ Model:    %-28s ║\n" "$LLM_MODEL"
printf "║ Budget:   \$%-27s ║\n" "${BUDGET_MAX_USD:-100.0}"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Ready to start! Run:"
echo "  bash scripts/restart.sh"
