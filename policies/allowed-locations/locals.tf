locals {
  allowed_locations_policy_metadata = jsonencode({
    category = "General"
  })

  allowed_locations_policy_parameters = jsonencode({
    allowedLocations = {
      type = "Array"

      metadata = {
        displayName = "Allowed locations"
        description = "The list of Azure regions that are permitted."
      }

      defaultValue = []
    }
  })

  allowed_locations_policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }

    then = {
      effect = "deny"
    }
  })
}