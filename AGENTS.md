# Repository Instructions

This file contains repository-level rules only. Agent orchestration, stage logic, handoffs, and loop intelligence must remain in custom agent files under `.github/agents/`.

## Terraform Version Policy

- Use only Terraform GA (generally available) releases.
- Do not use alpha, beta, release candidate, or experimental Terraform versions.
- Keep all Terraform code and module/provider constraints aligned with GA-only versions.

## Repository Standards

- All Terraform changes must follow `agents/shared/terraform-standards.md`.
- Keep implementation deterministic, idempotent, and free from hardcoded secrets.
- Keep generated workflow artifacts under `.artifacts/`.
- Create and merge changes from non-main branches only.

## Instruction Boundary

- `AGENTS.md` must stay free of agentic execution logic.
- All decision-making and workflow behavior belongs in `.github/agents/*.agent.md`.
