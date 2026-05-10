# allowed-locations — definition

Creates the Azure Policy **definition** that restricts resource deployment to approved regions.

This module is consumed standalone or paired with the `assignment` and `exclusions` modules.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `allowed_locations` | `list(string)` | Yes | One or more unique, non-empty Azure region names (e.g. `"eastus"`). |

## Outputs

| Name | Description |
|------|-------------|
| `allowed_locations_policy_definition_id` | Resource ID of the policy definition — pass this to the `assignment` module. |

## Usage

```hcl
module "allowed_locations_definition" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/definition?ref=v1.0.0"

  allowed_locations = ["eastus", "westeurope"]
}
```

Pass the output to the assignment module:

```hcl
module "allowed_locations_assignment" {
  source = "git::https://github.com/<org>/tf-polices.git//policies/allowed-locations/assignment?ref=v1.0.0"

  name                 = "allowed-locations"
  policy_definition_id = module.allowed_locations_definition.allowed_locations_policy_definition_id
  scope_type           = "subscription"
  subscription_id      = "/subscriptions/<subscription-id>"
  allowed_locations    = ["eastus", "westeurope"]
}
```
