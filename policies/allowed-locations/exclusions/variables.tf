variable "policy_assignment_id" {
  type        = string
  description = "Resource ID of the policy assignment to create exemptions against."
}

variable "scope_type" {
  type        = string
  description = "Scope type for all exemptions in this module call. One of: subscription, management_group, resource_group, resource."

  validation {
    condition     = contains(["subscription", "management_group", "resource_group", "resource"], var.scope_type)
    error_message = "scope_type must be one of: subscription, management_group, resource_group, resource."
  }
}

variable "exemptions" {
  type = list(object({
    name               = string
    scope_id           = string
    exemption_category = string
    display_name       = optional(string)
    description        = optional(string)
    # RFC3339 timestamp after which the exemption automatically expires. Omit for no expiry.
    expires_on = optional(string)
  }))
  description = "List of exemptions to create. All entries share the same scope_type."

  validation {
    condition     = length(var.exemptions) > 0 && alltrue([for e in var.exemptions : contains(["Waiver", "Mitigated"], e.exemption_category)])
    error_message = "exemptions must not be empty and each exemption_category must be Waiver or Mitigated."
  }
}
