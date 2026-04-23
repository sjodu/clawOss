#!/usr/bin/env bash
# ClawOSS Budget Reset — Reset budget counter to zero

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_DIR="$PROJECT_DIR/workspace"

BUDGET_SPENT_FILE="$WORKSPACE_DIR/memory/budget-spent.txt"

echo "=== ClawOSS Budget Reset ==="
echo ""

# Show current status
if [ -f "$BUDGET_SPENT_FILE" ]; then
  CURRENT_SPENT=$(cat "$BUDGET_SPENT_FILE")
  echo "Current spent: \$$CURRENT_SPENT"
else
  echo "No budget file found (will create)"
fi

echo ""
read -p "Reset budget counter to \$0.00? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "0.0" > "$BUDGET_SPENT_FILE"
  echo "✅ Budget counter reset to \$0.00"
  echo ""

  # Show new status
  bash "$SCRIPT_DIR/budget-status.sh"

  # Restart gateway if it was stopped
  if ! openclaw gateway status 2>/dev/null | grep -qi "running\|reachable\|ok"; then
    echo ""
    echo "Gateway is stopped. Restart with:"
    echo "  bash scripts/restart.sh"
  fi
else
  echo "❌ Cancelled"
  exit 1
fi
