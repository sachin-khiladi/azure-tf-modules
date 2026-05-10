# allowed-locations — assignment

Assigns the `allowed-locations` policy definition at subscription, management group, or resource group scope. Clients choose which scope to target; only the matching resource is created.

Supports inline scope exclusions via `not_scopes`. For richer per-resource exemptions use the `exclusions` module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | `string` | Yes | Assignment name (max 24 chars, alphanumeric + hyphens). |
| `policy_definition_id` | `string` | Yes | Output from the `definition` module. |
| `scope_type` | `string` | Yes | One of `subscription`, `management_group`, `resource_group`. |
| `subscription_id` | `string` | When `scope_type = subscription` | Subscription resource ID (`/subscriptions/<id>`). |
| `management_group_id` | `string` | When `scope_type = management_group` | Management group resource ID. |
| `resource_group_id` | `string` | When `scope_type = resource_group` | Resource group resource ID. |
| `allowed_locations` | `list(string)` | Yes | Regions to permit (passed as `allowedLocations` parameter). |
| `display_name` | `string` | No | Display name. Default: `"Allowed locations"`. |
| `description` | `string` | No | Description. Default: `"Restricts resource deployment to approved Azure regions."` |
| `not_scopes` | `list(string)` | No | Scope IDs excluded from this assignment. Default: `[]`. |

## Outputs

| Name | Description |
|------|-------------|
| `assignment_id` | Resource ID of the policy assignment — pass this to the `exclusions` module. |

## Examples

### Subscription scope

```hcl
module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "subscription"
  subscription_id      = "/subscriptions/00000000-0000-0000-0000-000000000000"
  allowed_locations    = ["eastus", "eastus2"]
}
```

### Management group scope

```hcl
module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "management_group"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/my-mg"
  allowed_locations    = ["eastus", "westeurope", "northeurope"]
}
```

### Resource group scope with inline not_scopes

```hcl
module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "resource_group"
  resource_group_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg"
  allowed_locations    = ["eastus"]

  # Exclude a specific child resource group from the assignment
  not_scopes = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/exempt-rg",
  ]
}
```
