# allowed-locations — exclusions

Creates Azure Policy **exemptions** for specific resources, resource groups, subscriptions, or management groups, shielding them from the `allowed-locations` policy assignment.

Clients choose which resources to exempt and can mix `Waiver` (temporary) and `Mitigated` (risk-accepted) categories. All exemptions in one module call must share the same `scope_type`; call the module multiple times for mixed scopes.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `policy_assignment_id` | `string` | Yes | Output from the `assignment` module. |
| `scope_type` | `string` | Yes | One of `subscription`, `management_group`, `resource_group`, `resource`. Applies to all entries in `exemptions`. |
| `exemptions` | `list(object)` | Yes | List of exemptions to create (see schema below). |

### `exemptions` object schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | Yes | Unique name for the exemption resource. |
| `scope_id` | `string` | Yes | Full resource ID of the scope to exempt (subscription ID, resource group ID, resource ID, or management group ID depending on `scope_type`). |
| `exemption_category` | `string` | Yes | `Waiver` (temporary bypass) or `Mitigated` (risk accepted by alternative control). |
| `display_name` | `string` | No | Human-readable display name. |
| `description` | `string` | No | Reason for the exemption. |
| `expires_on` | `string` | No | RFC3339 expiry timestamp (e.g. `"2027-12-31T00:00:00Z"`). Omit for no expiry. |

## Outputs

| Name | Description |
|------|-------------|
| `exemption_ids` | Map of exemption name → resource ID for all created exemptions. |

## Examples

### Exempt two resource groups (Waiver, time-limited)

```hcl
module "allowed_locations_exclusions_rg" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/exclusions?ref=v1.0.0"

  policy_assignment_id = module.allowed_locations_assignment.assignment_id
  scope_type           = "resource_group"

  exemptions = [
    {
      name               = "exempt-legacy-rg"
      scope_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/legacy-rg"
      exemption_category = "Waiver"
      display_name       = "Legacy workload exemption"
      description        = "Temporary waiver while legacy workload is migrated."
      expires_on         = "2027-06-30T00:00:00Z"
    },
    {
      name               = "exempt-sandbox-rg"
      scope_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/sandbox-rg"
      exemption_category = "Mitigated"
      display_name       = "Sandbox exemption"
      description        = "Sandbox environment; location controlled by separate guardrail."
    },
  ]
}
```

### Exempt a specific resource (permanent Mitigated)

```hcl
module "allowed_locations_exclusions_resource" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/exclusions?ref=v1.0.0"

  policy_assignment_id = module.allowed_locations_assignment.assignment_id
  scope_type           = "resource"

  exemptions = [
    {
      name               = "exempt-global-cdn"
      scope_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/cdn-rg/providers/Microsoft.Cdn/profiles/my-cdn"
      exemption_category = "Mitigated"
      display_name       = "Global CDN exemption"
      description        = "CDN profiles are global by design and have no location constraint."
    },
  ]
}
```

### Exempt an entire subscription

```hcl
module "allowed_locations_exclusions_sub" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/exclusions?ref=v1.0.0"

  policy_assignment_id = module.allowed_locations_assignment.assignment_id
  scope_type           = "subscription"

  exemptions = [
    {
      name               = "exempt-dev-subscription"
      scope_id           = "/subscriptions/11111111-1111-1111-1111-111111111111"
      exemption_category = "Waiver"
      display_name       = "Dev subscription waiver"
      description        = "Dev subscription is exempt pending architecture review."
      expires_on         = "2026-12-31T00:00:00Z"
    },
  ]
}
```
