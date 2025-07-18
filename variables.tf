variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be deployed. This value is passed in by Infrastructure Manager."
}

variable "region" {
  type        = string
  description = "Deployment region. This value is passed in by Infrastructure Manager."

  validation {
    condition     = contains(["us-east1"], var.region)
    error_message = "Region must be one of: us-east1"
  }
}

variable "environment" {
  type        = string
  description = "Environment. This value is passed in by Infrastructure Manager."
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}
