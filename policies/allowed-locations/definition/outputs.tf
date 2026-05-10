output "allowed_locations_policy_definition_id" {
  description = "The resource ID of the allowed locations Azure Policy definition."
  value       = azurerm_policy_definition.allowed_locations.id
}