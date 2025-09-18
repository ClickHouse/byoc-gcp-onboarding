variable "project_id" {
  type        = string
  description = "(Required) The GCP project ID where resources will be provisioned"
}

variable "environment" {
  type        = string
  description = "(Optional) Environment. Default is `production`. The other values are reserved for internal use"
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}
