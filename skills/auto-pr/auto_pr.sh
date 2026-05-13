#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Missing required command: $1"
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "ERROR: Missing required artifact: $1"
    exit 1
  fi
}

require_cmd git
require_cmd gh
require_cmd terraform
require_cmd tflint

SCANNER=""
if command -v checkov >/dev/null 2>&1; then
  SCANNER="checkov"
elif command -v tfsec >/dev/null 2>&1; then
  SCANNER="tfsec"
else
  echo "ERROR: Missing scanner. Install checkov (preferred) or tfsec"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "main" ]]; then
  echo "ERROR: Refusing to create PR from main branch. Create a feature branch first."
  exit 1
fi

# Verify all required artifacts exist
ART_PLAN=".artifacts/plan/plan.md"
ART_IMPL=".artifacts/implementation/changes.md"
ART_TEST=".artifacts/testing/results.md"
ART_REVIEW=".artifacts/review/findings.md"
ART_ORCH_STATE=".artifacts/orchestrator/loop-state.md"

require_file "$ART_PLAN"
require_file "$ART_IMPL"
require_file "$ART_TEST"
require_file "$ART_REVIEW"
require_file "$ART_ORCH_STATE"

# Verify orchestrator status = success
if ! grep -q "orchestrator_status.*success" "$ART_ORCH_STATE"; then
  echo "ERROR: Orchestrator status is not 'success'. Loop may have reached limit or failed."
  echo "$(cat "$ART_ORCH_STATE" | grep -A5 'Final Decision')"
  exit 1
fi

# Verify loop count <= 3
LOOP_COUNT=$(grep -oP 'Total Cycles: \K[0-9]+' "$ART_ORCH_STATE" || echo "0")
if [[ $LOOP_COUNT -gt 3 ]]; then
  echo "ERROR: Loop count ($LOOP_COUNT) exceeds max of 3. PR blocked."
  exit 1
fi

# Verify review approval
if ! grep -q "Approved: true" "$ART_REVIEW"; then
  echo "ERROR: Code Review is not approved. Findings detected:"
  grep -A 10 "Findings by Severity" "$ART_REVIEW" || true
  exit 1
fi

# Verify all quality gates passed
if grep -q "BLOCKED_ON" "$ART_TEST"; then
  BLOCKED_GATE=$(grep "BLOCKED_ON" "$ART_TEST" | head -1)
  echo "ERROR: Quality gates blocking. $BLOCKED_GATE"
  exit 1
fi

# Verify test results show all passed
if ! grep -q "ALL_PASSED\|Pass: true" "$ART_TEST"; then
  echo "ERROR: Testing did not pass all gates. See: $ART_TEST"
  exit 1
fi

PR_BASE="${PR_BASE:-main}"
PR_TITLE="${PR_TITLE:-chore(terraform): apply orchestrated agent workflow updates}"
PR_BODY_FILE="${PR_BODY_FILE:-.artifacts/pr-body.md}"

mkdir -p .artifacts
cat > "$PR_BODY_FILE" <<EOF
## Orchestrator Summary

Orchestrator Status: success
Loop Cycles: $LOOP_COUNT / 3
Review Approved: true

---

## Plan Summary

$(cat "$ART_PLAN")

---

## Implementation Summary

$(cat "$ART_IMPL")

---

## Test Evidence

$(cat "$ART_TEST")

---

## Code Review Findings

$(cat "$ART_REVIEW")

---

## Orchestrator Loop State

$(cat "$ART_ORCH_STATE")
EOF

git add -A
if git diff --cached --quiet; then
  echo "ERROR: No staged changes found. Commit your changes before creating PR."
  exit 1
fi

echo "Creating PR on branch '$BRANCH' targeting '$PR_BASE'..."
gh pr create --base "$PR_BASE" --head "$BRANCH" --title "$PR_TITLE" --body-file "$PR_BODY_FILE"

echo "PR created successfully."
