# File Structure & Architecture Reference

Complete directory layout and key file relationships for the strict Terraform agent team.

## Directory Tree

```
tf-polices/
├── .git/                                    # Git repository
│
├── AGENTS.md                               # ✅ Team orchestration contract (updated)
├── IMPLEMENTATION_STATUS.md                # ✅ Delivery summary & validation checklist
│
├── agents/
│   ├── orchestrator/
│   │   └── .agent.md                      # ✅ Orchestrator control plane (NEW)
│   │       → Sole invocation authority
│   │       → Loop state management (max 3 cycles)
│   │       → Learning trigger logic
│   │
│   ├── planning/
│   │   └── .agent.md                      # ✅ Planning agent (hardened)
│   │       → Read-only analysis
│   │       → Scope boundary enforcement
│   │       → No code generation rule
│   │
│   ├── implementation/
│   │   └── .agent.md                      # ✅ Implementation agent (hardened)
│   │       → Plan-only execution
│   │       → No scope expansion rule
│   │       → Policy reference traceability
│   │       → tools=['read','edit']
│   │
│   ├── testing/
│   │   └── .agent.md                      # ✅ Testing agent (hardened)
│   │       → Fail-fast 5-gate ordering
│   │       → No auto-fix rule
│   │       → Deterministic output
│   │       → tools=['read','shell']
│   │
│   ├── code-review/
│   │   └── .agent.md                      # ✅ Code Review agent (hardened)
│   │       → Model diversity (primary/fallback)
│   │       → Fallback strict checklist
│   │       → Cycle indicator
│   │       → tools=['read']
│   │
│   └── shared/
│       ├── terraform-standards.md         # ✅ Standards (source-backed, rewritten)
│       │   → HashiCorp style guide (formatting, naming, file org)
│       │   → Variable & output type+description requirement
│       │   → Provider version pinning
│       │   → Secrets & state safety rules
│       │   → Module design patterns
│       │   → Security best practices
│       │   → 5 mandatory quality gates
│       │
│       ├── handoff-schema.md              # ✅ Handoff contract (rewired)
│       │   → 6-stage pipeline definition
│       │   → Stage 5: Orchestrator loop control logic
│       │   → Loop-state schema & decision tree
│       │   → Learning integration trigger
│       │   → PR preconditions (8 mandatory checks)
│       │
│       └── learning-memory.md             # ✅ Learning log (NEW)
│           → Append-only reinforcement entries
│           → Entry schema: pattern, root cause, resolution, validation, instruction update
│           → Placeholder for learning examples
│
├── skills/
│   └── auto-pr/
│       └── SKILL.md                       # ✅ PR creation skill (updated)
│           → Orchestrator status validation
│           → Loop count enforcement (<= 3)
│           → Fail-closed policy
│           → 8 preconditions (all mandatory)
│
├── scripts/
│   └── auto_pr.sh                         # ✅ PR automation script (hardened)
│       → Orchestrator artifact verification
│       → Loop cycle count validation
│       → Loop state parsing
│       → Enhanced PR body with metadata
│
├── docs/
│   ├── agent-workflow.md                  # ✅ Operator guide (rewritten)
│   │   → End-to-end flow
│   │   → Quality gates explanation
│   │   → Strict execution rules
│   │   → Failure remediation steps
│   │   → Troubleshooting matrix
│   │
│   ├── learning-memory-guide.md           # ✅ Learning system guide (NEW)
│   │   → Entry review workflow
│   │   → Operator decision matrix
│   │   → Anti-regression checks
│   │   → Learning metrics & health
│   │
│   └── operator-quick-reference.md        # ✅ Quick reference (NEW)
│       → Start workflow checklist
│       → Exit codes & statuses
│       → Artifact guidance
│       → Common issues & fixes
│       → Loop behavior reference
│       → Token efficiency checks
│       → Model diversity checks
│       → Escalation path
│
└── .artifacts/                            # Generated during workflow (not in repo)
    ├── plan/
    │   └── plan.md                        # Planning Agent output
    ├── implementation/
    │   └── changes.md                     # Implementation Agent output
    ├── testing/
    │   └── results.md                     # Testing Agent output
    ├── review/
    │   └── findings.md                    # Code Review Agent output
    └── orchestrator/
        ├── loop-state.md                  # Orchestrator loop tracking
        └── learning-update.md             # Learning trigger output (optional)
```

## File Relationships & Dependencies

```
User Request
    ↓
AGENTS.md (defines team policy)
    ↓
.github/agents/orchestrator.agent.md (sole authority)
    ├─ Invokes .github/agents/terraform-planning.agent.md (subagent #1)
    │   └─ References: agents/shared/terraform-standards.md
    │   └─ Output: .artifacts/plan/plan.md
    │
    ├─ Invokes .github/agents/terraform-implementation.agent.md (subagent #2)
    │   ├─ References: agents/shared/terraform-standards.md
    │   └─ Output: .artifacts/implementation/changes.md
    │
    ├─ Invokes .github/agents/terraform-testing.agent.md (subagent #3)
    │   ├─ References: agents/shared/terraform-standards.md (gates section)
    │   └─ Output: .artifacts/testing/results.md
    │
    ├─ Invokes .github/agents/terraform-code-review.agent.md (subagent #4)
    │   ├─ References: agents/shared/terraform-standards.md (fallback checklist)
    │   └─ Output: .artifacts/review/findings.md
    │
    ├─ Loop Control Decision (agents/shared/handoff-schema.md "Stage 5")
    │   ├─ If Approved → Proceed to PR
    │   ├─ If Changes Requested & cycle < 3 → Subagent re-invoke #2,#3,#4
    │   ├─ If Changes Requested & cycle == 3 → Fail-closed, status=failed
    │   └─ Generate: .artifacts/orchestrator/loop-state.md
    │
    ├─ Learning Trigger
    │   └─ If Implementation fix approved → Append agents/shared/learning-memory.md
    │
    └─ Proceed to PR Creation
        └─ Invokes skills/auto-pr/SKILL.md
            └─ Run scripts/auto_pr.sh
                └─ Validates: orchestrator_status=success, loop_count<=3, all preconditions
                └─ Creates: Pull Request on GitHub
```

## Key Governance Points

### 1. Orchestrator Only Tool

**File:** `.github/agents/orchestrator.agent.md`  
**Key Section:** "Execution Rules"  
**Rule:** `tools: ['agent']` — only agent invocation allowed  
**Purpose:** Sole control point prevents individual agents from calling external tools

### 2. Subagent-Only Invocation

**File:** `agents/shared/handoff-schema.md`  
**Key Section:** All 6 stage descriptions  
**Rule:** "Subagent Call: [Agent Name] (no other invocations)"  
**Purpose:** Enforces orchestrator authority

### 3. Loop Control Max 3 Cycles

**File:** `.github/agents/orchestrator.agent.md` + `agents/shared/handoff-schema.md`  
**Key Section:** "Review Feedback Loop" + "Stage 5: Loop Control"  
**Rule:** If cycle count reaches 3, set `orchestrator_status=failed`, block PR  
**Purpose:** Prevents infinite loops; fail-closed design

### 4. Learning Trigger Condition

**File:** `.github/agents/orchestrator.agent.md`  
**Key Section:** "Review Feedback Loop" → "Trigger conditions"  
**Rule:** Append learning-memory.md when Implementation fix is validated by Code Review approval (cycle > 1)  
**Purpose:** Capture solutions for self-improvement

### 5. PR Gate Policy

**File:** `scripts/auto_pr.sh`  
**Key Section:** Precondition validation  
**Rule:** Require orchestrator_status=success AND loop_count<=3 before PR creation  
**Purpose:** Enforce orchestrator authority at PR creation boundary

### 6. Token Efficiency Constraints

**File:** All agent `.agent.md` files (frontmatter)  
**Key:** `tools:` field minimal per agent  
**Purpose:** Prevent tool sprawl and excessive MCP loading

## Creation Order (Historical)

1. ✅ **AGENTS.md** – Team policy and authority
2. ✅ **agents/shared/terraform-standards.md** – Reference standards (source-backed)
3. ✅ **.github/agents/terraform-planning.agent.md** – Analysis phase
4. ✅ **.github/agents/terraform-implementation.agent.md** – Code generation phase
5. ✅ **.github/agents/terraform-testing.agent.md** – Quality gates phase
6. ✅ **.github/agents/terraform-code-review.agent.md** – Review phase
7. ✅ **agents/shared/handoff-schema.md** – Pipeline contract & loop control
8. ✅ **.github/agents/orchestrator.agent.md** – Control plane (created last for dependency reasons)
9. ✅ **agents/shared/learning-memory.md** – Reinforcement log
10. ✅ **skills/auto-pr/SKILL.md** – PR creation skill
11. ✅ **scripts/auto_pr.sh** – PR automation
12. ✅ **docs/** – Operator documentation (3 files)

## Key File Points of Interest

### For Understanding Strict Rules

```bash
# Review global rules and orchestrator authority
cat AGENTS.md | grep -A20 "Global Rules"

# Review strict agent rules
for agent in agents/{planning,implementation,testing,code-review}/.agent.md; do
  echo "=== $(dirname $agent) ===" 
  grep -A20 "Rules (Strict, No Exceptions)" "$agent"
done

# Review orchestrator execution
cat .github/agents/orchestrator.agent.md | grep -A30 "Execution Rules"
```

### For Understanding Loop Control

```bash
# Review loop control logic
cat .github/agents/orchestrator.agent.md | grep -A50 "Review Feedback Loop"

# Review loop state schema
cat agents/shared/handoff-schema.md | grep -A30 "Loop Progress"

# Review PR preconditions (loop gating)
cat skills/auto-pr/SKILL.md | grep -A15 "Preconditions"
```

### For Understanding Learning System

```bash
# Review learning entry schema
cat agents/shared/learning-memory.md | head -50

# Review learning trigger logic
cat .github/agents/orchestrator.agent.md | grep -A10 "Learning Trigger"

# Review operator guidance
cat docs/learning-memory-guide.md | grep -A20 "Operator Workflow"
```

### For Quick Operator Reference

```bash
# Test scenario procedure
cat docs/operator-quick-reference.md | grep -A30 "Dry Run Test Scenario"

# Common issues
cat docs/operator-quick-reference.md | grep -A50 "Common Issues"

# Exit codes & statuses
cat docs/operator-quick-reference.md | grep -A30 "Exit Codes"
```

## Integration Points

### GitHub Integration

- **Tool:** GitHub CLI (`gh`)
- **Gate:** Auto PR Skill verifies `gh auth` is authenticated
- **Artifact:** PR body includes full workflow metadata from all stages
- **Reference:** `scripts/auto_pr.sh` PR body construction

### Terraform CLI Integration

- **Tools:** `terraform`, `tflint`, `checkov`/`tfsec`
- **Gate:** Testing Agent runs 5 mandatory gates in order
- **Reference:** `.github/agents/terraform-testing.agent.md` + `agents/shared/terraform-standards.md`

### Agent Framework Integration

- **Platform:** VS Code Copilot with agent support
- **Invocation:** Orchestrator uses subagent mechanism
- **Reference:** `.github/agents/orchestrator.agent.md` "Execution Rules"

## Validation Workflow

### Pre-Deployment Checklist

1. Verify file structure:
   ```bash
   find agents -name ".agent.md" | wc -l    # Should be: 5 (planning, implementation, testing, code-review, orchestrator)
   find docs -name "*.md" | wc -l            # Should be: 3 (workflow, learning, quick-reference)
   ```

2. Verify core dependencies:
   ```bash
   grep "tools:" .github/agents/orchestrator.agent.md        # Should: ['agent']
   grep "tools:" .github/agents/terraform-planning.agent.md            # Should: ['read']
   grep "tools:" .github/agents/terraform-implementation.agent.md      # Should: ['read','edit']
   grep "tools:" .github/agents/terraform-testing.agent.md             # Should: ['read','shell']
   grep "tools:" .github/agents/terraform-code-review.agent.md         # Should: ['read']
   ```

3. Verify loop control logic:
   ```bash
   grep -c "max 3" AGENTS.md                          # Should: >= 2
   grep -c "orchestrator_status" .github/agents/orchestrator.agent.md  # Should: >= 3
   grep -c "loop_count" scripts/auto_pr.sh            # Should: >= 2
   ```

4. Verify standards are source-backed:
   ```bash
   grep "HashiCorp" agents/shared/terraform-standards.md    # Should: >= 10
   grep "https://developer.hashicorp.com" agents/shared/terraform-standards.md  # Should: >= 5
   ```

### Live Deployment Steps

1. Stage all updated files in git
2. Run validation: `bash scripts/auto_pr.sh --check` (dry run)
3. Commit: `git add -A && git commit -m "Feat: Strict Terraform agent orchestration framework"`
4. Create PR: `git push origin main && gh pr create --title "Strict Terraform Agent Team"`
5. Merge when reviewed
6. Test dry-run scenario on feature branch
7. Monitor learning-memory.md during first 10 runs

---

## Summary

**Total Files Created/Updated:** 15  
**Total Directories:** 6  
**Lines of Code:** ~2,000+  
**Governance Rules Enforced:** 11 (subagent-only, no-deviation, loop max 3, standards compliance, etc.)  
**Quality Gates:** 5 (all mandatory, fail-fast)  
**Agent Diversity:** 5 specialized agents + 1 orchestrator  
**Documentation Pages:** 3 (workflow, learning, quick-reference)  

**Status:** ✅ Complete and ready for validation
