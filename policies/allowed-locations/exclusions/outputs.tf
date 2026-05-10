output "exemption_ids" {
  description = "Map of exemption name to resource ID for all created exemptions."
  value = merge(
    { for k, v in azurerm_subscription_policy_exemption.this : k => v.id },
    { for k, v in azurerm_management_group_policy_exemption.this : k => v.id },
    { for k, v in azurerm_resource_group_policy_exemption.this : k => v.id },
    { for k, v in azurerm_resource_policy_exemption.this : k => v.id },
  )
}
