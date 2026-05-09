resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed locations"
  description  = "Restricts resource creation to the approved Azure regions."
  metadata     = local.allowed_locations_policy_metadata
  parameters   = local.allowed_locations_policy_parameters
  policy_rule  = local.allowed_locations_policy_rule
}