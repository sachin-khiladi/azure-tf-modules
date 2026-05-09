variable "allowed_locations" {
  type        = list(string)
  description = "Azure region names permitted by the allowed locations policy."

  validation {
    condition     = length(var.allowed_locations) > 0 && length(distinct(var.allowed_locations)) == length(var.allowed_locations) && alltrue([for location in var.allowed_locations : length(trimspace(location)) > 0])
    error_message = "allowed_locations must contain at least one unique, non-empty Azure location."
  }
}