# allowed-locations

Policy suite that restricts Azure resource deployment to approved regions. Split into two independently consumable modules — clients implement only what they need.

| Module | Path | Purpose |
|--------|------|---------|
| **definition** | `policies/allowed-locations/definition` | Creates the Azure Policy definition |
| **assignment** | `policies/allowed-locations/assignment` | Assigns the policy at subscription, management group, or resource group scope. Supports `not_scopes` to exclude specific resource groups. |

## Typical consumption patterns

### Definition only (policy registration, no enforcement)

```hcl
module "allowed_locations_definition" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/definition?ref=v1.0.0"

  allowed_locations = ["eastus", "westeurope"]
}
```

### Definition + assignment at subscription scope

```hcl
module "allowed_locations_definition" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/definition?ref=v1.0.0"

  allowed_locations = ["eastus", "westeurope"]
}

module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "subscription"
  subscription_id      = "/subscriptions/<subscription-id>"
  allowed_locations    = ["eastus", "westeurope"]
}
```

### Definition + assignment with not_scopes (exclude resource groups)

```hcl
module "allowed_locations_definition" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/definition?ref=v1.0.0"

  allowed_locations = ["eastus", "westeurope"]
}

module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "subscription"
  subscription_id      = "/subscriptions/<subscription-id>"
  allowed_locations    = ["eastus", "westeurope"]

  # Resource groups excluded from the deny effect
  not_scopes = [
    "/subscriptions/<subscription-id>/resourceGroups/legacy-rg",
    "/subscriptions/<subscription-id>/resourceGroups/sandbox-rg",
  ]
}
```

### Definition + assignment at resource group scope

```hcl
module "allowed_locations_definition" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/definition?ref=v1.0.0"

  allowed_locations = ["eastus"]
}

module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "resource_group"
  resource_group_id    = "/subscriptions/<subscription-id>/resourceGroups/my-rg"
  allowed_locations    = ["eastus"]
}
```

## Provider configuration (consuming repo responsibility)

Each sub-module declares `required_providers` in its `terraform.tf`, but the consuming root module must configure the provider:

```hcl
provider "azurerm" {
  features {}
  subscription_id = "<subscription-id>"
}
```

See each sub-module's own `README.md` for full input/output documentation.
