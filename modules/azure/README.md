# ClickHouse BYOC Azure Onboarding Terraform Module

This repository contains Terraform module to bootstrap a BYOC Azure tenant & subscription for ClickHouse Cloud.

## Usage

```hcl
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

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID to onboard"
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  resource_provider_registrations = "none"

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

module "clickhouse_onboarding" {
  source        = "github.com/ClickHouse/terraform-byoc-onboarding.git//modules/azure"
  subscriptions = [var.subscription_id]
}
```

## Inputs

| Name          | Description                                      | Type         | Default | Required |
|---------------|--------------------------------------------------|--------------|---------|:--------:|
| subscriptions | (Required) The Azure subscription IDs to onboard | list(string) | n/a     |   yes    |

## Outputs
