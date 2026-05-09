# Reinforcement Learning Memory

Append-only log of resolved agent failures, applied fixes, and corresponding instruction improvements. Use this to prevent regression and strengthen guardrails after each validated resolution.

## Entry Format

```
## Resolution [ID]
- Date: YYYY-MM-DD HH:MM
- Failure Pattern: [describe the agent error or misbehavior]
- Root Cause: [why the error occurred]
- Affected Agent: [planning|implementation|testing|code-review|orchestrator]
- Resolution Applied: [what fix was implemented in code or instructions]
- Validation Proof: [artifact summary showing fix resolved the issue]
- Instruction Update File: [agents/X/.agent.md or agents/shared/Y.md]
- Update Summary: [exact change made to instruction file]
- Anti-Regression Check: [specific guardrail added to prevent recurrence]
```

---

## Examples (to be populated during execution)

(Entries will be appended here as failures are resolved during workflow execution.)

---

## Resolution 001

- Date: 2026-05-09 10:35
- Failure Pattern: Ambiguity about which files belong in a reusable policy module vs a root module — specifically whether `terraform.tf`, `providers.tf`, and `backend.tf` are required in child modules.
- Root Cause: Standards file (`terraform-standards.md`) listed file structure only for root modules, with no explicit guidance for reusable child modules. Agents had no rule preventing `providers.tf` or `backend.tf` from being added to reusable modules, and no rule requiring `README.md`.
- Affected Agent: terraform-planning, terraform-implementation, terraform-testing
- Resolution Applied:
  1. Updated `agents/shared/terraform-standards.md` — added explicit Reusable Module vs Root Module table clarifying which files belong where and making `README.md` mandatory for every policy module.
  2. Updated `terraform-implementation.agent.md` — added rules: README required, no `providers.tf`/`backend.tf` in modules, `terraform.tf` required.
  3. Updated `terraform-planning.agent.md` — same rules added to planning stage.
  4. Updated `terraform-testing.agent.md` — added gate 6: verify `README.md` exists in every module under `policies/`.
  5. Created `policies/allowed-locations/README.md` with inputs, outputs, and three consumption examples (single-region, multi-region, management group scope).
- Validation Proof: `terraform fmt -check`, `terraform init -backend=false`, and `terraform validate` all passed (exit 0) on `policies/allowed-locations/` with Terraform v1.9.8.
- Instruction Update File: `agents/shared/terraform-standards.md`, `.github/agents/terraform-implementation.agent.md`, `.github/agents/terraform-planning.agent.md`, `.github/agents/terraform-testing.agent.md`
- Update Summary:
  - Standards: Added Reusable Module vs Root Module table; made README mandatory; clarified that `providers.tf` and `backend.tf` are root-module-only artifacts.
  - Planning agent: README creation is a required planned task; no `providers.tf`/`backend.tf` in module folders.
  - Implementation agent: Missing README blocks implementation; do not create `providers.tf`/`backend.tf` in policy modules.
  - Testing agent: Gate 6 — README presence check is a blocker.
- Anti-Regression Check: Any PR touching `policies/` that lacks a `README.md` in the module folder will fail testing gate 6 before merge.
