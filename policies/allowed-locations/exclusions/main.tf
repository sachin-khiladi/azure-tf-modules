resource "azurerm_subscription_policy_exemption" "this" {
  for_each = local.subscription_exemptions

  name                 = each.value.name
  subscription_id      = each.value.scope_id
  policy_assignment_id = var.policy_assignment_id
  exemption_category   = each.value.exemption_category
  display_name         = each.value.display_name
  description          = each.value.description
  expires_on           = each.value.expires_on
}

resource "azurerm_management_group_policy_exemption" "this" {
  for_each = local.management_group_exemptions

  name                 = each.value.name
  management_group_id  = each.value.scope_id
  policy_assignment_id = var.policy_assignment_id
  exemption_category   = each.value.exemption_category
  display_name         = each.value.display_name
  description          = each.value.description
  expires_on           = each.value.expires_on
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = local.resource_group_exemptions

  name                 = each.value.name
  resource_group_id    = each.value.scope_id
  policy_assignment_id = var.policy_assignment_id
  exemption_category   = each.value.exemption_category
  display_name         = each.value.display_name
  description          = each.value.description
  expires_on           = each.value.expires_on
}

resource "azurerm_resource_policy_exemption" "this" {
  for_each = local.resource_exemptions

  name                 = each.value.name
  resource_id          = each.value.scope_id
  policy_assignment_id = var.policy_assignment_id
  exemption_category   = each.value.exemption_category
  display_name         = each.value.display_name
  description          = each.value.description
  expires_on           = each.value.expires_on
}
