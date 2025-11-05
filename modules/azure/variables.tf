variable "environment" {
  type        = string
  description = "(Optional) Environment. Default is `production`. The other values are reserved for internal use"
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}

variable "subscriptions" {
  type        = list(string)
  description = <<-EOT
  List of subscription IDs to onboard. **MUST be known at plan time** (e.g. variables, hardcoded, or data sources in root module).
  Using `for_each` with dynamic values (data sources, resource outputs) will cause plan failures.
  EOT
}
