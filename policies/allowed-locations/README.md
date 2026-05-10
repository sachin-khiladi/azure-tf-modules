# allowed-locations

Policy suite that restricts Azure resource deployment to approved regions. Split into three independently consumable modules — clients implement only what they need.

| Module | Path | Purpose |
|--------|------|---------|
| **definition** | `policies/allowed-locations/definition` | Creates the Azure Policy definition |
| **assignment** | `policies/allowed-locations/assignment` | Assigns the policy at subscription, management group, or resource group scope |
| **exclusions** | `policies/allowed-locations/exclusions` | Creates Azure Policy exemptions for specific resources or scopes |

## Typical consumption patterns

### Definition only (policy registration, no assignment)

```hcl
module "allowed_locations_definition" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/definition?ref=v1.0.0"

  allowed_locations = ["eastus", "westeurope"]
}
```

### Definition + assignment

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

### Full stack — definition + assignment + exclusions

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

module "allowed_locations_exclusions" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/exclusions?ref=v1.0.0"

  policy_assignment_id = module.allowed_locations_assignment.assignment_id
  scope_type           = "resource_group"

  exemptions = [
    {
      name               = "exempt-legacy-rg"
      scope_id           = "/subscriptions/<subscription-id>/resourceGroups/legacy-rg"
      exemption_category = "Waiver"
      display_name       = "Legacy workload exemption"
      expires_on         = "2027-06-30T00:00:00Z"
    },
  ]
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
