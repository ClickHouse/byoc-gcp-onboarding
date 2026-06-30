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

variable "network_project_id" {
  type        = string
  description = "(Optional) The GCP project ID of the Shared VPC host project, when the VPC you bring lives in a different project than `project_id`. Leave empty for the standard same-project setup. When set, `region` and `private_subnet_id` are required."
  default     = ""
}

variable "region" {
  type        = string
  description = "(Optional) The region of the Shared VPC host subnet. Required only when `network_project_id` is set."
  default     = ""
}

variable "private_subnet_id" {
  type        = string
  description = "(Optional) The name of the existing Shared VPC host subnet used for GKE nodes. Required only when `network_project_id` is set."
  default     = ""
}
