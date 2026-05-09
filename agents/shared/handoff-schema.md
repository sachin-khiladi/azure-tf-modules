# Agent Handoff Schema

All stages use markdown artifacts under `.artifacts/`. Orchestrator controls flow and loop state transitions.

## Stage 1: Planning Agent

**Subagent Call:** Planning Agent (no other invocations)

Input:

- User request.
- Repository standards from `agents/shared/terraform-standards.md`.

Output:

- `.artifacts/plan/plan.md`

Required sections:

- Request Digest
- Scope Boundary (explicit in-scope and out-of-scope)
- Target Policy Module Path (must be `policies/<policy-name>/`, for example `policies/allowed-location/`)
- Planned Changes (numbered, concrete)
- Assumptions
- Risks & Mitigations
- Validation Strategy (mapped to quality gates)
- Acceptance Criteria
- Standards References

## Stage 2: Implementation Agent

**Subagent Call:** Implementation Agent (only if plan complete; no direct tool calls)

Input:

- `.artifacts/plan/plan.md` (required; blocking if missing)

Output:

- Code changes in repository
- `.artifacts/implementation/changes.md`

Required sections:

- Files Changed (with line ranges or hashes)
- Policy Module Layout Check (`PASS` only if policy modules are under `policies/<policy-name>/`)
- Change Summary (per file, per plan item)
- Rationale per Major Change (traceable to plan)
- Deviations from Plan (if any, with justification)
- Standards Compliance Checklist

## Stage 3: Testing Agent

**Subagent Call:** Testing Agent (only if implementation complete)

Input:

- `.artifacts/implementation/changes.md` (required; blocking if missing)

Output:

- `.artifacts/testing/results.md`

Required sections:

- Execution Summary (start/end time, branch, commit)
- Command Execution Table (one row per gate; columns: gate, command, status, exit code, duration, output)
- Pass/Fail Status (ALL_PASSED or BLOCKED_ON: [gate_name])
- Blocker Details (if failed: type, count, exact error text)
- Blocker Decision (BLOCKS_PR_CREATION for gates 1-5)

## Stage 4: Code Review Agent

**Subagent Call:** Code Review Agent (only if testing PASSED)

Input:

- `.artifacts/implementation/changes.md` (required)
- `.artifacts/testing/results.md` (required; blocking if not PASSED)
- Cycle Indicator: [1, 2, or 3] from Orchestrator

Output:

- `.artifacts/review/findings.md`

Required sections:

- Metadata
  - Cycle: [1, 2, 3]
  - Model/Perspective Used: [explicit declaration]
  - Fallback Mode: [true/false]
- Findings by Severity (High, Medium, Low; or "No findings identified")
- Disposition Machine-Parseable
  - Approved: [true/false]
  - Changes Requested: [true/false]
  - Blocker Count: [N]
- Orchestrator Feedback (for loop control)
  - Findings Summary: [brief list for Implementation Agent]
  - Required Actions: [if changes requested]

## Stage 5: Loop Control (Orchestrator)

**Orchestrator Decision Logic:**

1. If Code Review Approved:
   - Set `orchestrator_status = success`
   - Proceed to Auto PR
   
2. If Code Review Changes Requested and cycle < 3:
   - Increment cycle counter
   - **Invoke Implementation Agent (subagent)** with review findings
   - **Invoke Testing Agent (subagent)** on updated code
   - **Invoke Code Review Agent (subagent)** on new test results
   - Append cycle result to `.artifacts/orchestrator/loop-state.md`
   - If Implementation resolved findings: append learning entry
   - Return to loop decision

3. If Code Review Changes Requested and cycle == 3:
   - Set `orchestrator_status = failed`
   - Append failure reason to `.artifacts/orchestrator/loop-state.md`
   - Block PR creation; output fail-closed status
   - Append learning entry if applicable

Output:

- `.artifacts/orchestrator/loop-state.md`

Required sections:

- Metadata (initiated timestamp, request digest, target branch)
- Loop Progress (per cycle: planning, implementation, testing, review status)
- Blocker Details (findings count, severity, disposition per cycle)
- Final Decision (total cycles, orchestrator status, reason if failed)

## Stage 6: Auto PR Skill

**Preconditions (All Must Be True):**

- Orchestrator status = `success` (from `.artifacts/orchestrator/loop-state.md`)
- Loop count <= 3 (from loop-state metadata)
- All required artifacts present and non-empty
- Review disposition is `Approved: true`
- Current branch is NOT `main`
- GitHub CLI authentication is valid
- All quality gates passed (from testing results)

**Subagent Call:** None. PR creation uses GitHub CLI directly.

Input:

- `.artifacts/plan/plan.md`
- `.artifacts/implementation/changes.md`
- `.artifacts/testing/results.md`
- `.artifacts/review/findings.md`
- `.artifacts/orchestrator/loop-state.md`

Output:

- Pull Request URL

## Reinforcement Learning Integration

When Implementation resolves a Code Review finding successfully:

1. Orchestrator appends entry to `.artifacts/orchestrator/learning-update.md` with:
   - Failure Pattern
   - Root Cause
   - Resolution Applied
   - Validation Proof
   - Instruction Update File
   - Update Summary
   - Anti-Regression Check

2. **Notify operators** to review and apply instruction updates to relevant agent `.agent.md` file.

3. All updates must be explicit and documented; no silent mutations.
