terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  resource_provider_registrations = "none"

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_ids[0]
  features {}
}

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID"
  default     = "c17da9aa-b8c3-4664-a7a7-35ac07447f9c"
}

variable "subscription_ids" {
  type        = list(string)
  description = "The Azure subscription IDs to onboard"
  default     = ["6cdb6084-3501-4c8c-b349-0a0a01f08781"]
}

module "clickhouse_onboarding" {
  source        = "../../modules//azure"
  environment   = "development"
  subscriptions = var.subscription_ids
}
