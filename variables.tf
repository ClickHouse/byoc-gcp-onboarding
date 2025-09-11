variable "project_id" {
  type        = string
  description = "(Required) The GCP project ID where resources will be deployed"
}

variable "region" {
  type        = string
  description = "(Required) Deployment region"

  validation {
    condition     = contains(["us-east1"], var.region)
    error_message = "Region must be one of: us-east1"
  }
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
