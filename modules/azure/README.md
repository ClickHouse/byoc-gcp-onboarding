# ClickHouse BYOC Azure Onboarding Terraform Module

This repository contains Terraform module to bootstrap a BYOC Azure tenant & subscription for ClickHouse Cloud.

In accordance with Azure guidance for cross-tenant authentication, the module provisions the multitenant application as an Enterprise Application (service principal) in the target tenant and assigns it the required permissions scoped to the target subscription. This allows the ClickHouse provisioner to create Azure resources in the target subscription.

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
  source = "github.com/ClickHouse/terraform-byoc-onboarding.git//modules/azure?ref=v1.1.0"
}

output "tenant_id" {
  value = module.clickhouse_onboarding.tenant_id
}

output "subscription_id" {
  value = module.clickhouse_onboarding.subscription_id
}

output "service_principal_client_id" {
  value = module.clickhouse_onboarding.service_principal_client_id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | (Optional) Environment. Default is `production`. The other values are reserved for internal use" | string | production | no |

## Outputs

| Name | Description |
|------|-------------|
| tenant_id | The Azure AD tenant ID |
| subscription_id | The Azure subscription ID |
| service_principal_client_id | The application (client) ID of the service principal |

## Resources

| Name | Description |
|------|------|
| azuread_service_principal.this | Service Principal for ClickHouse BYOC application |
| azurerm_role_definition.clickhouse_byoc_provisioner | Custom role for ClickHouse to provision Azure BYOC infrastructure resources |
| azurerm_role_assignment.this | Assigns 'ClickHouse BYOC Provisioner' role to the service principal |
| azuread_app_role_assignment.graph_permissions["Application.ReadWrite.OwnedBy"] | Grants Application.ReadWrite.OwnedBy Microsoft Graph permission |
| azuread_app_role_assignment.graph_permissions["User.Invite.All"] | Grants User.Invite.All Microsoft Graph permission |
| azuread_app_role_assignment.graph_permissions["User.ReadWrite.All"] | Grants User.ReadWrite.All Microsoft Graph permission |

## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.3 |
| azuread provider | >=2.0 |
| azurerm provider | >=3.0 |
