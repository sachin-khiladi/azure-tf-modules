# Reinforcement Learning Memory Guide

The Terraform agent team implements continuous self-improvement through an append-only learning memory system. This guide explains how to monitor, review, and apply lessons from resolved failures.

## Overview

**Location:** `agents/shared/learning-memory.md`

**Purpose:** Track failures, root causes, and successful fixes to improve agent instructions iteratively.

**Trigger:** When Implementation Agent resolves a Code Review Agent finding during a review loop (cycles 2-3), Orchestrator appends a learning entry.

**Operator Responsibility:** Review new learning entries and decide whether to update agent instructions.

## Learning Entry Structure

Each entry contains:

```markdown
### Date: YYYY-MM-DD | Failure Pattern: [Name]

**Root Cause:** [Explanation]

**Affected Agent(s):** Planning | Implementation | Testing | Code Review

**Resolution Applied:** [Summary of fix]

**Validation Proof:** [Evidence that fix worked: test output, lint pass, etc.]

**Instruction Update File:** agents/[agent-name]/.agent.md

**Update Summary:** Update [section name], add/modify rule [rule name]

**Anti-regression Check:** [How to detect if this failure happens again]
```

## Example Learning Entry

```markdown
### Date: 2024-11-20 | Failure Pattern: Missing Type Descriptor in Variable

**Root Cause:** Implementation Agent added variables without `type` attribute, violating terraform-standards.md requirement. Code Review Agent caught it on cycle 2.

**Affected Agent(s):** Implementation

**Resolution Applied:** Implementation Agent added missing `type` declarations to all variables. Code Review re-validated and approved on cycle 2.

**Validation Proof:** 
- terraform validate: PASSED
- tflint: PASSED (no variable type violations)
- Code Review Findings: Approved=true

**Instruction Update File:** .github/agents/terraform-implementation.agent.md

**Update Summary:** Strengthen "Standards Compliance Checklist" rule. Add explicit check: "Every var/output/local must have type OR default; type always preferred."

**Anti-regression Check:** Testing Agent will catch missing types in terraform validate step. Code Review fallback checklist includes type verification.
```

## Operator Workflow

### 1. Monitor for New Entries

After each orchestrator run, check if learning entry was appended:

```bash
tail -20 agents/shared/learning-memory.md
```

If new entry exists, proceed to review.

### 2. Review Entry for Accuracy

Verify:

- **Root Cause** makes sense and is grounded in code
- **Resolution** is explained clearly with evidence
- **Instruction Update File** is correct
- **Update Summary** is specific and actionable

If unclear, ask generation team for clarification before proceeding.

### 3. Apply Instruction Update (if approved)

If entry describes a pattern that should be prevented going forward:

```bash
# 1. Open the instruction file
code .github/agents/terraform-implementation.agent.md

# 2. Locate the section mentioned in "Update Summary"
# (e.g., "Standards Compliance Checklist")

# 3. Add or modify the rule mentioned
# Example: Add to checklist:
#   - [ ] All variables and outputs have type attributes (never omit type)

# 4. Save and commit
git add .github/agents/terraform-implementation.agent.md
git commit -m "Learn: Add explicit type-checking rule to Implementation Agent from failure 2024-11-20"
```

### 4. Mark Entry as Applied (Optional)

Append a note to the learning entry:

```markdown
**Operator Applied:** Yes, 2024-11-20 16:30 UTC
**Instruction File Updated:** .github/agents/terraform-implementation.agent.md
**Commit:** abc1234 (Learn: Add explicit type-checking rule to Implementation Agent)
```

## Decision Matrix: Apply or Archive?

| Condition | Decision | Reason |
|-----------|----------|--------|
| Root cause is agent misunderstanding of standard | Apply update | Agent needs clearer instruction |
| Root cause is ambiguity in terraform-standards.md | Update standards, not agent | Standards are source of truth |
| Root cause is one-off user oversight (typo, edge case) | Archive as note | Pattern doesn't recur; no instruction change needed |
| Root cause is design limitation in agent execution | Escalate to team | May require agent refactoring |
| Root cause is external tool bug (terraform, tflint, etc.) | Archive; track tool version | Not agent responsibility |

## Common Learning Patterns

### Pattern: Missing Type on Variable

**Typical Entry:**
```
Failure Pattern: Missing Type Descriptor
Root Cause: Implementation Agent did not enforce type attribute on variables
Affected Agent: Implementation
Resolution: Added type: string to variable
Update File: .github/agents/terraform-implementation.agent.md
```

**Action:** Update Implementation Agent's "Standards Compliance Checklist" to include type validation.

### Pattern: Hardcoded Secret in Code

**Typical Entry:**
```
Failure Pattern: Hardcoded Secret Exposure
Root Cause: Implementation Agent wrote DB password in main.tf instead of using variable
Affected Agent: Implementation
Resolution: Moved password to variables.tf and marked sensitive=true
Update File: .github/agents/terraform-implementation.agent.md + .github/agents/terraform-code-review.agent.md
```

**Action:** 
1. Update Implementation to explicitly check for hardcoded strings that look like passwords
2. Update Code Review checklist to flag any suspicious hardcoded values

### Pattern: Deprecated Provider Version

**Typical Entry:**
```
Failure Pattern: Deprecated Provider Version
Root Cause: Implementation Agent used old provider version from template
Affected Agent: Implementation
Resolution: Updated required_providers to use current stable version
Update File: agents/terraform-standards.md
```

**Action:** Update terraform-standards.md [Provider & Version Pinning] section with latest stable versions.

## Token Efficiency Notes

Learning system is designed to be token-efficient:

- **Append-only:** New entries are added at end of file; no rewrites
- **Single operator review:** Operator (human) decides which updates apply; no auto-mutations
- **Soft learning triggers:** Orchestrator appends entry only when fix is validated by subsequent Code Review approval
- **No silent instruction updates:** All changes to agent files are explicitly committed and logged

## Anti-Regression Checks

Each learning entry should specify how to detect regression:

### Example Anti-Regression Checklist

```markdown
**Anti-regression Check:** 
1. terraform validate must pass (catches missing type attributes)
2. tflint must pass (catches variable/output naming issues)
3. Code Review fallback checklist explicitly includes type verification
4. If same pattern re-appears, escalate to team for deeper fix
```

Test the anti-regression check by intentionally creating the original failure and confirming it is caught:

```bash
# Inject the original failure manually
echo 'variable "example" { }' > test_regression.tf

# Run validation
terraform fmt -check test_regression.tf  # Should fail (missing type)
terraform validate  # Should also fail

# Clean up
rm test_regression.tf
```

## Failure Analysis Ladder

Use this ladder to determine root cause:

1. **Agent Instruction Issue?** ← Most common (update agent)
2. **Standard Ambiguity?** ← Update terraform-standards.md
3. **Tool Configuration Missing?** ← Update tflint/checkov config
4. **Tool Bug or Version?** ← Document and escalate
5. **Design Flaw?** ← Escalate to team

## When to NOT Update Instructions

- Failure is a legitimate edge case that should be discussed with user, not hardcoded
- Failure is user error (misconfiguration of variable) that learning system should not over-correct
- Failure happens only once and is unlikely to recur (wait for pattern confirmation)
- Instruction change would overly constrain valid use cases

## Learning Metrics

Monitor learning health:

```bash
# Count entries per agent
grep "^Affected Agent" agents/shared/learning-memory.md | sort | uniq -c

# Example output:
#  3 Implementation
#  1 Code Review
#  1 Testing

# Count applied updates
grep "^**Operator Applied:** Yes" agents/shared/learning-memory.md | wc -l
```

Healthy patterns:
- Most entries from Implementation (code generation is harder than review)
- Applied-vs-archived ratio ~70% (some entries are valid edge cases)
- Major cluster of updates every 20-30 runs (continuous improvement)

## Troubleshooting

### Learning Entry is Appended But Doesn't Make Sense

**Check:**
1. Is the root cause accurate? Ask Implementation Agent for clarification.
2. Is the resolution actually fixing the problem? Check test results.
3. Did Code Review actually approve after the fix?

**Fix:** Re-run the scenario manually to get full context, then update learning entry with clarification.

### Agent Instruction is Updated But Pattern Keeps Recurring

**Analysis:**
1. Was the instruction update specific enough?
2. Does the rule clash with other valid use cases?
3. Is the agent parsing the instruction correctly?

**Fix:** Revise instruction to be more explicit or escalate to team for agent behavior audit.

### Learning Memory File is Growing Too Large

**Maintenance:**
- Archive entries older than 6 months to `docs/learning-memory-archive.md`
- Keep recent entries (last 3 months) in active `agents/shared/learning-memory.md`
- Review archive periodically for recurring patterns

## Best Practices

1. **Review Promptly:** Don't let learning entries pile up; review and decide within 24h of creation.
2. **Be Conservative:** Only update instructions if the pattern is clearly recurring (2+ occurrences).
3. **Test Updates:** After updating instruction, manually verify the anti-regression check passes.
4. **Document Everything:** Every instruction change comes from a learning entry; never silent mutations.
5. **Escalate Systematically:** If 3+ learning entries point to the same root cause, escalate to team for design review.
