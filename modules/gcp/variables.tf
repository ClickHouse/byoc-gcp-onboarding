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

variable "include_vpc_write_permissions" {
  type        = bool
  description = "(Optional) Whether to grant permissions to manage your VPC network topology (create/delete/modify of networks, routes, Cloud Routers, and subnet attributes). Set to `false` for bring-your-own-VPC onboarding, where you pre-create and manage the VPC, routes, Cloud NAT, and the PrivateLink/PSC NAT subnet yourself. Regardless of this setting, ClickHouse always retains read and use access to the VPC and manages the resources it owns inside it (the PrivateLink/PSC service attachment, and ingress/static IP addresses in the service project)."
  default     = true
}

variable "shared_vpc_host_project_id" {
  type        = string
  description = "(Optional) The GCP project ID of the Shared VPC host project, when the VPC you bring lives in a different project than `project_id`. Leave empty for the standard same-project setup. When set, `shared_vpc_host_subnet_region` and `shared_vpc_host_private_subnet_id` are required."
  default     = ""
}

variable "shared_vpc_host_subnet_region" {
  type        = string
  description = "(Optional) The region of the Shared VPC host subnet. Required only when `shared_vpc_host_project_id` is set."
  default     = ""
}

variable "shared_vpc_host_private_subnet_id" {
  type        = string
  description = "(Optional) The name of the existing Shared VPC host subnet used for GKE nodes. Required only when `shared_vpc_host_project_id` is set."
  default     = ""
}
