# Operator Quick Reference

Fast reference for invoking the Terraform agent team and troubleshooting common scenarios.

## Starting a Workflow

### Prerequisites

1. Feature branch created (NOT on `main`):
   ```bash
   git checkout -b feature/my-change
   ```

2. GitHub CLI authenticated:
   ```bash
   gh auth login
   ```

3. All tools installed:
   - `terraform` (latest stable)
   - `tflint`
   - `checkov` or `tfsec`
   - `gh` (GitHub CLI)

### Invoke Orchestrator

Call the Orchestrator Agent with your request:

```bash
# Example: Adding a new data source
copilot-agent .github/agents/orchestrator.agent.md --request "Add AWS S3 bucket data source for prod region"
```

The Orchestrator will invoke all downstream agents (Planning, Implementation, Testing, Code Review) as subagents only.

**Wait for:** `.artifacts/orchestrator/loop-state.md` to report `orchestrator_status: success`

## Exit Codes & Status

### Success (PR Created)

```
orchestrator_status: success
loop_count: 2 (out of max 3)
review_approved: true
```

→ PR is created automatically. Check GitHub for PR URL.

### Changes Requested (Loop Triggered)

```
orchestrator_status: in_progress
loop_count: 1 (< 3)
review_approved: false
changes_requested: true
```

→ Orchestrator will re-invoke Implementation, Testing, and Code Review. Wait for next loop-state update.

### Failed (Loop Limit Reached)

```
orchestrator_status: failed
loop_count: 3 (at max)
review_approved: false
reason: LOOP_LIMIT_EXCEEDED
```

→ No PR created. Review findings in `.artifacts/review/findings.md`. Discuss with team.

## Artifact Guidance

| Artifact | Check For | Action if Missing/Wrong |
|----------|-----------|------------------------|
| `.artifacts/plan/plan.md` | Scope boundary, acceptance criteria | Re-run Planning Agent |
| `.artifacts/implementation/changes.md` | Files changed, rationale per file | Re-run Implementation Agent |
| `.artifacts/testing/results.md` | Gate status (ALL_PASSED or BLOCKED_ON) | Fix blocker, re-run Testing Agent |
| `.artifacts/review/findings.md` | Approved true/false, Blocker Count | Review recursively until Approved=true |
| `.artifacts/orchestrator/loop-state.md` | orchestrator_status, loop_count, final_decision | Read for decisions; do not edit manually |

## Common Issues & Fixes

### ❌ "Quality gates blocking. BLOCKED_ON: TERRAFORM_FMT"

**Cause:** Code is not formatted per Terraform style.

**Fix:**
```bash
terraform fmt -recursive
git add -A
# Orchestrator will re-run Testing Agent automatically on next loop
```

### ❌ "Quality gates blocking. BLOCKED_ON: TERRAFORM_VALIDATE"

**Cause:** Invalid HCL syntax.

**Fix:**
1. Check error details in `.artifacts/testing/results.md`
2. Open file with error and fix syntax
3. Re-run orchestrator workflow

### ❌ "Quality gates blocking. BLOCKED_ON: TFLINT"

**Cause:** Code violates linting rules (naming, spacing, etc.).

**Fix:**
1. Read tflint findings in `.artifacts/testing/results.md`
2. Fix violations (typically renaming, spacing, or module reference issues)
3. Re-run orchestrator workflow

### ❌ "Code Review denies. CHANGES_REQUESTED: true"

**Cause:** Code Review Agent found issues (security, standard violation, design problem).

**Fix:**
1. Read findings in `.artifacts/review/findings.md`
2. Understand change request reason
3. Allow Orchestrator to loop: Implementation will address findings
4. Findings disappear once fixed and Code Review re-approves

### ❌ "Orchestrator status: failed. REASON: LOOP_LIMIT_EXCEEDED"

**Cause:** Code Review kept requesting changes through 3 review cycles.

**Fix:**
1. Review `.artifacts/review/findings.md` (latest cycle)
2. Discuss issues with team (may indicate design problem)
3. Create new plan and re-request orchestrator with revised approach

### ❌ "PR script failed: Not on main branch"

**Cause:** Currently on `main` branch (forbidden).

**Fix:**
```bash
git checkout -b feature/my-change
# Ensure all artifacts exist and orchestrator_status=success
bash scripts/auto_pr.sh
```

### ❌ "GitHub authentication failed"

**Cause:** GitHub CLI not authenticated.

**Fix:**
```bash
gh auth login
# Choose HTTPS and provide personal access token (or SSH key)
```

## Loop Behavior Reference

| Cycle | Code Review Result | Orchestrator Action | Max Allowed? |
|-------|-------------------|-------------------|--------------|
| 1 | Approved | Create PR | Yes |
| 1 | Changes Requested | Invoke Implementation (cycle 2) | Yes |
| 2 | Approved | Create PR | Yes |
| 2 | Changes Requested | Invoke Implementation (cycle 3) | Yes |
| 3 | Approved | Create PR | Yes |
| 3 | Changes Requested | Status=FAILED; block PR | No |

**Key:** Orchestrator enforces max 3 **Code Review** invocations (not 3 attempts per stage).

## Learning Memory Management

When a learning entry is appended (after Orchestrator successfully loops and resolves findings):

1. **Review:** Open `agents/shared/learning-memory.md`, read new entry
2. **Verify:** Entry describes real pattern and includes validation proof
3. **Decide:** Apply instruction update or archive as edge case
4. **Apply:** Update agent `.agent.md` file per entry's "Instruction Update File"
5. **Commit:** Log instruction update in git

Example:
```bash
# Review new entry
tail -50 agents/shared/learning-memory.md

# If approved for update:
code .github/agents/terraform-implementation.agent.md
# ... make changes per entry guidance ...
git add .github/agents/terraform-implementation.agent.md agents/shared/learning-memory.md
git commit -m "Learn: Enforce type descriptor on all variables (from 2024-11-20 failure)"
```

## Token Efficiency Checks

Agents should load minimal tools. To verify:

```bash
# Check Planning Agent tools (should be: read only)
grep "^tools:" .github/agents/terraform-planning.agent.md

# Check Implementation Agent tools (should be: read, edit)
grep "^tools:" .github/agents/terraform-implementation.agent.md

# Check Testing Agent tools (should be: read, shell)
grep "^tools:" .github/agents/terraform-testing.agent.md

# Check Code Review Agent tools (should be: read only)
grep "^tools:" .github/agents/terraform-code-review.agent.md

# Check Orchestrator tools (should be: agent only)
grep "^tools:" .github/agents/orchestrator.agent.md
```

If output shows excessive tools (e.g., `write`, `search`, `network` for Planning), file issue for token remediation.

## Model Diversity Check

Code Review Agent must use a different model or declare fallback mode:

```bash
grep -A2 "Model Used\|FALLBACK_MODE" .artifacts/review/findings.md
```

Expected output:

**Normal:** `Model Used: [Different Model from Implementation]`

**Fallback:** `FALLBACK_MODE: true`

If neither, Code Review may have skipped model diversity rule.

## Dry Run Test Scenario

To test loop behavior without real PR:

```bash
# 1. Create test feature branch
git checkout -b test/loop-validation

# 2. Make intentional small change (e.g., add a variable)
# Example in main.tf:
# variable "test_loop" {
#   description = "Testing loop behavior"
#   # Intentionally omit type to trigger Code Review finding
# }

git add -A
git commit -m "Test: Intentional finding for loop validation"

# 3. Invoke Orchestrator
copilot-agent .github/agents/orchestrator.agent.md --request "Test loop handling with intentional finding"

# 4. Wait for cycle 1 Code Review to request changes

# 5. Orchestrator will auto-loop; Implementation fixes (adds type: string)

# 6. Verify cycle 2 Code Review approves

# 7. Check PR was created with loop-state showing cycle 2

# 8. Delete PR:
PR_NUMBER=$(gh pr list --state open --head test/loop-validation --json number -q '.[] | .number')
gh pr close $PR_NUMBER

# 9. Clean up branch
git checkout main
git branch -D test/loop-validation
```

## Useful Commands

```bash
# Check workflow status
cat .artifacts/orchestrator/loop-state.md

# View latest review findings
cat .artifacts/review/findings.md | tail -30

# Check test gate blockers
grep "BLOCKED_ON" .artifacts/testing/results.md

# List all PR artifacts
ls -lh .artifacts/*/

# Monitor learning entries
tail -20 agents/shared/learning-memory.md

# Verify terraform standards compliance
grep -A5 "Naming Conventions\|Core Standards" agents/shared/terraform-standards.md

# Check agent tool constraints
for agent in agents/*/; do echo "$agent:"; grep "^tools:" "$agent"/.agent.md; done
```

## Escalation Path

If workflow is stuck or behaving unexpectedly:

1. **Check artifacts:** Are all required files present and non-empty?
2. **Check loop-state:** Is orchestrator status clear (success/failed/in_progress)?
3. **Check agent errors:** Are there error logs from subagent invocation?
4. **Review findings:** Does Code Review explain its decision?
5. **Escalate:** If unclear, file issue with artifact snapshots and request human review.

## No-Go Conditions for PR

PR will NOT be created if:

- ✗ Orchestrator status != "success"
- ✗ Loop count > 3
- ✗ Code Review Approved != true
- ✗ Any required artifact is missing
- ✗ Testing gate is blocked
- ✗ Current branch is `main`
- ✗ GitHub CLI is not authenticated
- ✗ No staged changes exist

Clear all of these before PR creation is possible.
