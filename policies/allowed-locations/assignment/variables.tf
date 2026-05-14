variable "name" {
  type        = string
  description = "Name for the policy assignment (max 24 characters, alphanumeric and hyphens only)."

  validation {
    condition     = length(var.name) <= 24 && can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "name must be 24 characters or fewer and contain only alphanumeric characters and hyphens."
  }
}

variable "policy_definition_id" {
  type        = string
  description = "Resource ID of the Azure Policy definition to assign. Use the output from the definition module."
}

variable "scope_type" {
  type        = string
  description = "Scope at which to assign the policy. One of: subscription, management_group, resource_group."

  validation {
    condition     = contains(["subscription", "management_group", "resource_group"], var.scope_type)
    error_message = "scope_type must be one of: subscription, management_group, resource_group."
  }
}

variable "subscription_id" {
  type        = string
  description = "Subscription resource ID (/subscriptions/<id>). Required when scope_type is subscription."
  default     = null
}

variable "management_group_id" {
  type        = string
  description = "Management group resource ID. Required when scope_type is management_group."
  default     = null
}

variable "resource_group_id" {
  type        = string
  description = "Resource group resource ID. Required when scope_type is resource_group."
  default     = null
}

variable "allowed_locations" {
  type        = list(string)
  description = "Azure regions to permit. Passed as the allowedLocations policy parameter to the assignment."

  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "allowed_locations must contain at least one location."
  }
}

variable "display_name" {
  type        = string
  description = "Human-readable display name for the policy assignment."
  default     = "Allowed locations"
}

variable "description" {
  type        = string
  description = "Description for the policy assignment."
  default     = "Restricts resource deployment to approved Azure regions."
}

variable "not_scopes" {
  type        = list(string)
  description = "List of resource group or child scope resource IDs to exclude from this assignment. Excluded scopes are not subject to the policy deny effect."
  default     = []
}
