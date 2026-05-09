# allowed-locations

Terraform module that creates an Azure Policy definition restricting resource creation to approved regions.

## Description

This module creates a custom Azure Policy definition of type `deny` that prevents resource deployment to any Azure location not included in the `allowed_locations` list. The policy is applied at subscription or management group level by the consuming module via an assignment resource.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `allowed_locations` | `list(string)` | Yes | One or more Azure region names to permit (e.g. `"eastus"`, `"westeurope"`). Must be unique and non-empty. |

## Outputs

| Name | Description |
|------|-------------|
| `allowed_locations_policy_definition_id` | Resource ID of the Azure Policy definition. Pass this to an assignment resource. |

## Usage

### Minimal example — single region

```hcl
module "allowed_locations" {
  source  = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations?ref=v1.0.0"

  allowed_locations = ["eastus"]
}

# Assign the policy at subscription scope
resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  subscription_id      = "/subscriptions/<subscription-id>"
  policy_definition_id = module.allowed_locations.allowed_locations_policy_definition_id
  display_name         = "Allowed locations"
  description          = "Restricts resource deployment to approved regions."
}
```

### Multi-region example

```hcl
module "allowed_locations" {
  source  = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations?ref=v1.0.0"

  allowed_locations = [
    "eastus",
    "eastus2",
    "westeurope",
    "northeurope",
  ]
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  subscription_id      = "/subscriptions/<subscription-id>"
  policy_definition_id = module.allowed_locations.allowed_locations_policy_definition_id
  display_name         = "Allowed locations"
}
```

### Management group scope example

```hcl
module "allowed_locations" {
  source  = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations?ref=v1.0.0"

  allowed_locations = ["eastus", "westus2"]
}

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/<mg-id>"
  policy_definition_id = module.allowed_locations.allowed_locations_policy_definition_id
  display_name         = "Allowed locations"
}
```

## Notes

- The module creates the **policy definition only**. The consuming repository is responsible for creating the policy assignment and configuring the provider.
- `terraform.tf` in this module declares provider requirements; the consuming root module must configure the `azurerm` provider.
- The policy effect is `deny` — resources in non-listed locations will be blocked at deployment time.
