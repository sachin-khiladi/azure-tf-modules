# Terraform Agent Workflow

Deterministic, orchestrator-controlled multi-agent execution with strict no-deviation rules, bounded review-remediation loops (max 3), and reinforcement learning from resolved failures.

## End-to-End Flow

1. **Orchestrator Agent** invokes Planning Agent (subagent only)
   - Planning Agent produces `.artifacts/plan/plan.md`
   
2. **Orchestrator Agent** invokes Implementation Agent (subagent only)
   - Implementation Agent produces `.artifacts/implementation/changes.md`
   
3. **Orchestrator Agent** invokes Testing Agent (subagent only)
   - Testing Agent runs mandatory gates
   - Testing Agent produces `.artifacts/testing/results.md`
   - If testing fails: orchestrator stops and emits fail status; no PR
   
4. **Orchestrator Agent** invokes Code Review Agent (subagent only, cycle 1)
   - Code Review Agent produces `.artifacts/review/findings.md`
   - If approved: proceed to PR
   - If changes requested and cycle < 3: proceed to loop
   
5. **Loop (Max 3 Cycles):** If Code Review has findings
   - Orchestrator re-invokes Implementation Agent (subagent) with findings
   - Orchestrator re-invokes Testing Agent (subagent) on updated code
   - Orchestrator re-invokes Code Review Agent (subagent) on new test results
   - Orchestrator records loop cycle in `.artifacts/orchestrator/loop-state.md`
   - If Implementation resolved findings: Orchestrator appends learning entry
   - Loop continues until: approved, or cycle count reaches 3
   
6. **Final Decision:**
   - If review approved within 3 cycles: set `orchestrator_status = success`
   - If findings persist at cycle 3: set `orchestrator_status = failed`; no PR
   
7. **PR Creation (Gated by Auto PR Skill)**
   - Only if orchestrator status = success AND loop count <= 3
   - `bash scripts/auto_pr.sh` verifies all preconditions and creates PR
   - PR body includes plan, implementation, test evidence, review findings, and loop state

## Required Quality Gates (Mandatory Order)

All gates must pass for code to reach Code Review:

1. `terraform fmt -check -recursive` — Formatting compliance
2. `terraform init -backend=false` — Provider compatibility
3. `terraform validate` — Syntax and consistency
4. `tflint` — Linting and best practices
5. `checkov -d .` or `tfsec .` — Security scanning

All gates are blocking. Failure at any gate stops the pipeline.

## Strict Execution Rules

- **Orchestrator Authority:** All stage invocations are subagent calls only. No direct tool access by other agents.
- **No Deviation:** Follow plan exactly. Scope expansion, stage skipping, or reordering is forbidden.
- **Standards Compliance:** All code must follow `agents/shared/terraform-standards.md` (source-backed HashiCorp rules).
- **No Token Expansion:** Agents load minimal required tools/MCP. Soft budgets warn and compress, do not expand.
- **Fail-Closed:** If loop limit reached with unresolved findings, PR creation is blocked.
- **Learning Enabled:** When Implementation resolves a Code Review finding, Orchestrator appends entry to `agents/shared/learning-memory.md` and operators review for instruction updates.

## Model Diversity in Code Review

- **Primary:** Code Review Agent uses a different model or perspective than Implementation Agent.
- **Fallback:** If alternate model unavailable, review declares `FALLBACK_MODE: true` and executes stricter checklist.
- **Always Declared:** Output must state which model/perspective was used.

## Common Failures & Remediation

### Testing Fails on a Gate

Error message shows which gate failed:

```
ERROR: Quality gates blocking. BLOCKED_ON: TERRAFORM_FMT
```

**Fix:** Run the failing gate locally to see detailed errors, fix code, commit, and re-trigger orchestrator.

### Code Review Rejects (Cycle 1 or 2)

Orchestrator loops Implementation and Testing back through Code Review:

- Check `.artifacts/orchestrator/loop-state.md` for cycle count
- Check `.artifacts/review/findings.md` for findings summary
- Implementation Agent must address findings in next cycle
- If cycle count reaches 3 with unresolved findings: orchestrator sets status to failed; no PR

**Fix:** Ensure Implementation Agent receives findings from Code Review and addresses them explicitly.

### Orchestrator Status is "Failed"

```
ERROR: Orchestrator status is not 'success'. Loop may have reached limit or failed.
```

**Remediation:**

1. Check `.artifacts/orchestrator/loop-state.md` for failure reason
2. Review last cycle's findings in `.artifacts/review/findings.md`
3. If findings are persistent: discuss with team and decide whether to close PR request or revise approach entirely
4. Re-run orchestrator workflow with revised plan/implementation

### Review Artifacts Missing or Incomplete

```
ERROR: Missing required artifact: .artifacts/review/findings.md
```

**Fix:** Ensure Code Review Agent completed successfully. Check agent logs for errors and re-run.

### GitHub Authentication Missing

```
ERROR: GitHub CLI is not authenticated. Run: gh auth login
```

**Fix:** Authenticate GitHub CLI:

```bash
gh auth login
```

### PR Script Fails (Not on Main Branch, Required Artifacts, Loop Policy)

Run preflight check:

```bash
bash scripts/auto_pr.sh --check
```

Ensure:

- Current branch is not `main`
- All required artifacts exist and are non-empty
- Orchestrator loop state confirms success and cycle count <= 3
- Review findings show Approved: true

## Operating Notes

- Keep artifacts current after each stage; orchestrator uses them as source of truth.
- Do not bypass Testing or Code Review stages.
- Do not run agents directly; let Orchestrator invoke them as subagents.
- When resolving Code Review findings, ensure Implementation Agent addresses them explicitly.
- No reinforcement learning update is created unless a fix is validated; learning entries are append-only.

## Model Diversity & Alternate Models

If Code Review cannot run with a different model:

1. Review output will declare `FALLBACK_MODE: true`
2. Review will execute the stricter checklist (variables, outputs, secrets, naming, indentation, etc.)
3. This is functionally equivalent to a different review perspective but less sophisticated
4. Ensure findings are comprehensive before approving

## Troubleshooting Matrix

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Testing blocks on fmt | Code not formatted to standard | Run `terraform fmt -recursive` and commit |
| Testing blocks on validate | Invalid HCL syntax | Check error output; fix syntax; re-run |
| Testing blocks on tflint | Linting violations | Review tflint output; fix per rules; re-run |
| Review keeps requesting changes | Implementation not understanding findings | Review findings summary; add more detail to findings artifact |
| Loop stuck at cycle 3 | Persistent unresolved findings | Discuss with team; may require design change |
| PR script shows "not approved" | Review Approved field is false | Check findings; ensure Code Review completed successfully |
