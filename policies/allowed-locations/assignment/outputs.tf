output "assignment_id" {
  description = "Resource ID of the policy assignment."
  value = coalesce(
    try(azurerm_subscription_policy_assignment.this[0].id, null),
    try(azurerm_management_group_policy_assignment.this[0].id, null),
    try(azurerm_resource_group_policy_assignment.this[0].id, null),
  )
}
