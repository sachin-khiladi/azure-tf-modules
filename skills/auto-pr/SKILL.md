---
name: auto-pr-skill
description: Creates a GitHub pull request only after Terraform validation and review gates pass AND orchestrator confirms successful completion within loop policy.
---

# Auto PR Skill

## Mission

Create a PR for finalized Terraform changes only when orchestrator confirms success and loop policy compliance. Enforce all preconditions; abort safely with remediation guidance if any precondition fails.

## Preconditions (All Mandatory)

1. **Orchestrator Status:** `.artifacts/orchestrator/loop-state.md` exists and contains `orchestrator_status = success`
2. **Loop Policy:** Loop cycle count from `.artifacts/orchestrator/loop-state.md` is <= 3
3. **Review Disposition:** `.artifacts/review/findings.md` contains `Approved: true`
4. **Required Artifacts:** All exist and are non-empty:
   - `.artifacts/plan/plan.md`
   - `.artifacts/implementation/changes.md`
   - `.artifacts/testing/results.md`
   - `.artifacts/review/findings.md`
   - `.artifacts/orchestrator/loop-state.md`
5. **Quality Gates:** All gates passed (from `.artifacts/testing/results.md`):
   - `terraform fmt -check -recursive`
   - `terraform init -backend=false`
   - `terraform validate`
   - `tflint`
   - `checkov -d .` or `tfsec .`
6. **Branch Check:** Current branch is NOT `main`
7. **GitHub CLI:** Authenticated and operational (`gh auth status` succeeds)

## Execution

Run:

```bash
bash scripts/auto_pr.sh
```

Optional environment variables:

- `PR_BASE` (default: `main`)
- `PR_TITLE` (default: `chore(terraform): apply orchestrated agent workflow updates`)
- `PR_BODY_FILE` (default: `.artifacts/pr-body.md`)

## Failure Policy (Strict)

- If any precondition fails: abort and print remediation guidance.
- If orchestrator status is not `success`: abort with explicit message (loop limit reached).
- If any quality gate has not passed: abort with gate name and error.
- If review is not approved: abort with findings summary for remediation.
- **Never create PR when preconditions are violated.**

## Success Output

- Prints PR URL
- PR body includes:
  - Plan summary (from `.artifacts/plan/plan.md`)
  - Implementation summary (from `.artifacts/implementation/changes.md`)
  - Test evidence (from `.artifacts/testing/results.md`)
  - Review findings (from `.artifacts/review/findings.md`)
  - Loop state metadata (from `.artifacts/orchestrator/loop-state.md`)

## Enforcement Notes

- This skill **does not invoke agents**; it gates PR creation based on orchestrator output.
- All stage outputs must be present and valid.
- Loop state is the source of truth for orchestrator success/failure.
- Learning updates are informational; do not block PR if present.
