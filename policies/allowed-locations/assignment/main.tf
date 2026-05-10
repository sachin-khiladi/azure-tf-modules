resource "azurerm_subscription_policy_assignment" "this" {
  count = var.scope_type == "subscription" ? 1 : 0

  name                 = var.name
  subscription_id      = var.subscription_id
  policy_definition_id = var.policy_definition_id
  display_name         = var.display_name
  description          = var.description
  not_scopes           = var.not_scopes

  parameters = jsonencode({
    allowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_management_group_policy_assignment" "this" {
  count = var.scope_type == "management_group" ? 1 : 0

  name                 = var.name
  management_group_id  = var.management_group_id
  policy_definition_id = var.policy_definition_id
  display_name         = var.display_name
  description          = var.description
  not_scopes           = var.not_scopes

  parameters = jsonencode({
    allowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_resource_group_policy_assignment" "this" {
  count = var.scope_type == "resource_group" ? 1 : 0

  name                 = var.name
  resource_group_id    = var.resource_group_id
  policy_definition_id = var.policy_definition_id
  display_name         = var.display_name
  description          = var.description
  not_scopes           = var.not_scopes

  parameters = jsonencode({
    allowedLocations = { value = var.allowed_locations }
  })
}
