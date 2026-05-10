locals {
  exemptions_map = { for e in var.exemptions : e.name => e }

  subscription_exemptions     = var.scope_type == "subscription" ? local.exemptions_map : {}
  management_group_exemptions = var.scope_type == "management_group" ? local.exemptions_map : {}
  resource_group_exemptions   = var.scope_type == "resource_group" ? local.exemptions_map : {}
  resource_exemptions         = var.scope_type == "resource" ? local.exemptions_map : {}
}
