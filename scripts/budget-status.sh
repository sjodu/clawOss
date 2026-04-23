#!/usr/bin/env bash
# ClawOSS Budget Status — Display current budget usage

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_DIR="$PROJECT_DIR/workspace"

BUDGET_MAX=$(cat "$WORKSPACE_DIR/memory/budget-max.txt" 2>/dev/null || echo "100.0")
BUDGET_SPENT=$(cat "$WORKSPACE_DIR/memory/budget-spent.txt" 2>/dev/null || echo "0.0")

# Calculate remaining and percentage
BUDGET_REMAINING=$(echo "$BUDGET_MAX - $BUDGET_SPENT" | bc 2>/dev/null || echo "0.0")
BUDGET_PERCENT=$(echo "scale=2; $BUDGET_SPENT / $BUDGET_MAX * 100" | bc 2>/dev/null || echo "0")

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════╗"
echo "║        BUDGET STATUS                   ║"
echo "╠════════════════════════════════════════╣"
printf "║ Max Budget:      \$%-18s ║\n" "$BUDGET_MAX"
printf "║ Spent:           \$%-18s ║\n" "$BUDGET_SPENT"
printf "║ Remaining:       \$%-18s ║\n" "$BUDGET_REMAINING"
printf "║ Usage:           %-18s%% ║\n" "$BUDGET_PERCENT"
echo "╚════════════════════════════════════════╝"

# Warnings
if (( $(echo "$BUDGET_SPENT >= $BUDGET_MAX" | bc -l 2>/dev/null || echo 0) )); then
  echo ""
  echo -e "${RED}⚠️  BUDGET EXCEEDED - Gateway stopped${NC}"
  echo "To reset: bash scripts/budget-reset.sh"
  exit 1
elif (( $(echo "$BUDGET_SPENT >= $BUDGET_MAX * 0.8" | bc -l 2>/dev/null || echo 0) )); then
  echo ""
  echo -e "${YELLOW}⚠️  WARNING: 80% budget used${NC}"
  exit 0
else
  echo ""
  echo -e "${GREEN}✅ Budget OK${NC}"
  exit 0
fi
