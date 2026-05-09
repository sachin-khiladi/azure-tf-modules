# Terraform Standards

Source-backed strict Terraform guardrails based on HashiCorp official style guide, module development patterns, and registry publishing requirements.

## Core Standards (HashiCorp Style Guide)

### Formatting & Validation

- **Always** run `terraform fmt -check -recursive` before committing.
- **Always** run `terraform validate` to check syntax and internal consistency.
- Use 2-space indentation for every nesting level.
- Align `=` signs when multiple consecutive arguments appear at the same level.
- Separate top-level blocks with one blank line; nested blocks within blocks with one blank line.
- Place meta-arguments (`count`, `for_each`, `depends_on`) first, then arguments, then nested blocks.

### File Organization

Mandatory file structure:

- `terraform.tf` — Terraform version and required_providers block (root modules **and** reusable child modules)
- `providers.tf` — All provider configurations (default first if multiple; **root modules only**)
- `variables.tf` — All input variable declarations (alphabetical order)
- `main.tf` — Primary resource and data source definitions
- `outputs.tf` — All output value declarations (alphabetical order)
- `locals.tf` — Local values (if applicable)
- `backend.tf` — Backend configuration (**root modules only**)
- `README.md` — **Required for every reusable module** (see Module Design section)

#### Reusable Module vs Root Module

This repository contains **reusable policy modules** under `policies/<policy-name>/`. These modules are consumed by other repositories, not run standalone.

| File | Root Module | Reusable Module |
|------|------------|-----------------|
| `terraform.tf` (required_version + required_providers) | ✅ Required | ✅ Required — declares provider constraints for consumers |
| `provider {}` block / `providers.tf` | ✅ Required | ❌ Omit — consumer configures the provider |
| `backend.tf` | ✅ Required | ❌ Omit — consumer manages state |
| `README.md` | Optional | ✅ Required |

Optional files for larger configurations:

- `network.tf`, `compute.tf`, `storage.tf`, `security.tf`, `monitoring.tf` — Organize resources by logical function

### Naming Conventions

- **Resources:** Use descriptive nouns, lowercase with underscores; do NOT include resource type in name.
  - ✅ `resource "aws_instance" "web_api"`
  - ❌ `resource "aws_instance" "aws_instance_web_api"`
- **Modules:** Repos use format `terraform-<PROVIDER>-<NAME>` (e.g., `terraform-aws-vpc`). Local modules use `./modules/<module_name>`.
- **Locals/Variables/Outputs:** Lowercase with underscores; alphabetical order in `variables.tf` and `outputs.tf`.
- **Tags:** Consistent naming across all resources; document required tags in `locals.tf` or `variables.tf`.

### Variables & Outputs (Always Include Type and Description)

Every variable and output **must** include:

1. **Type:** Explicit type constraint (string, number, bool, list, map, object, etc.)
2. **Description:** Non-empty, human-readable description
3. **Default (optional):** Only if variable is optional
4. **Sensitive (optional):** Set `sensitive = true` for passwords, private keys, etc. (state still stores in plaintext; marked in plan output)
5. **Validation Blocks:** For restrictive requirements beyond type checking

Example:

```hcl
variable "instance_count" {
  type        = number
  description = "Number of instances to deploy. Must be at least 2."
  default     = 3

  validation {
    condition     = var.instance_count >= 2
    error_message = "Minimum of 2 instances required."
  }
}

output "instance_ips" {
  type        = list(string)
  description = "Public IP addresses of deployed instances"
  value       = aws_instance.web[*].public_ip
  sensitive   = false
}
```

### Comments

- Use `#` for single-line and multi-line comments (not `//` or `/* */`).
- Add comments only where they clarify non-obvious logic; avoid over-commenting.
- For resource definitions, use comments to explain WHY, not WHAT (code shows WHAT).

### Provider & Version Pinning (Mandatory)

- **Pin ALL provider versions** using conservative constraints to prevent unexpected breaks.
- **Pin module versions** to major.minor version at minimum.
- **Pin Terraform CLI version** using `required_version` in `terraform` block.

Example:

```hcl
terraform {
  required_version = ">= 1.7"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34.0"
    }
  }
}
```

### Secrets & State Safety (No Exceptions)

- **Never hardcode** secrets, passwords, keys, or sensitive data in `.tf` files.
- **Never commit** `terraform.tfstate`, `terraform.tfstate.*`, `.terraform.lock.hcl` (wait, `.lock.hcl` SHOULD be committed for consistency), or `.terraform/` directory to VCS.
- **Never commit** `.tfvars` files containing sensitive values.
- Always use **encrypted remote state** (e.g., S3 with encryption, Azure Storage with encryption, Terraform Cloud).
- Use provider-specific authentication methods (environment variables, OIDC, dynamic credentials) rather than static keys.

### Linting & Static Analysis (All Mandatory)

Every module must pass:

1. `terraform fmt -check -recursive` (formatting)
2. `terraform init -backend=false` (provider download)
3. `terraform validate` (syntax and consistency)
4. `tflint --format json` (linting)
5. `checkov -d . --framework terraform` or `tfsec .` (security scanning)

Failures block PR creation.

### Module Design (HashiCorp Module Development Pattern)

### Module Structure

- Single responsibility: each module manages one logical component (e.g., networking, compute, storage).
- Shallow composition: avoid deep nesting of child modules.
- **`README.md` is mandatory** for every policy module under `policies/<policy-name>/`. No README = PR blocked.
- No `providers.tf` or `backend.tf` in reusable modules — the consuming root module handles both.
- `terraform.tf` with `required_version` and `required_providers` **must** be present in every module to declare provider constraints for consumers.

### Input Variables

- Limit over-parameterization; expose only values that change between deployments.
- Use sensible defaults for optional values.
- Validate input ranges and constraints with `validation` blocks.

### Outputs

- Document every output with `type` and `description`.
- Output the most commonly needed values (IDs, addresses, connection strings).
- Use consistent naming across similar modules.

### Testing

- Include at least one example in `examples/` directory.
- Write `*.tftest.hcl` files for module testing if complexity warrants.
- Verify that examples run successfully and produce expected outputs.

## Security Best Practices

- **Least Privilege:** IAM roles and security groups default to deny; explicitly whitelist.
- **Encryption:** Enable encryption at rest and in transit for all state, databases, and sensitive resources.
- **Resource Tagging:** Enforce consistent tags for cost allocation, compliance, and resource tracking.
- **Drift Detection:** Use `terraform plan` regularly to detect unmanaged changes.
- **Plan Review:** Never auto-apply; always review `terraform plan` output before `terraform apply`.

## Workflow Discipline

- Use **GitHub Flow:** feature branches, Pull Requests, review + approval before merge.
- Require **speculative plans** on PR (via CI/CD) to preview changes before merge.
- **Plan-apply separation:** `terraform plan -out=tfplan` followed by review + `terraform apply tfplan`.
- **Workspace strategy:** Separate workspaces or state files per environment (dev, staging, prod).
- **Backup & Recovery:** Test state recovery procedures regularly.

## Documentation Expectations

Each change set must include:

- **What changed:** Explicit resource/module names and properties affected.
- **Why it changed:** Business or technical justification.
- **Risk level:** High, Medium, or Low (explain destructive changes, drift risk, IAM changes).
- **Rollback or mitigation notes:** How to revert if needed.

## HashiCorp Sources

- [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- [Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Registry Module Publishing](https://developer.hashicorp.com/terraform/registry/modules/publish)
