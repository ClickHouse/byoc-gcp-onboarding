# ClickHouse BYOC GCP Onboarding Terraform Module

This repository contains Terraform module to bootstrap a BYOC GCP project for ClickHouse Cloud.

## Usage

```hcl
module "clickhouse_onboarding" {
  source      = "github.com/ClickHouse/byoc-gcp-onboarding.git?ref=main"
  project_id  = "ch-byoc-test-3842"
  region      = "us-east1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | (Required) The GCP project ID where resources will be deployed | string | n/a | yes |
| region | (Required) Deployment region. The list of available BYOC regions: https://clickhouse.com/docs/cloud/reference/supported-regions#google-cloud-regions | string | n/a | yes |
| environment | (Optional) Environment. Default is `production`. The other values are reserved for internal use | string | `production` | no |

## Outputs

| Name | Description |
|------|-------------|
| clickhouse_management_sa_name | The name of the ClickHouse Management Service Account | string |
| clickhouse_management_sa_roles | List of role IDs assigned to the ClickHouse Management Service Account | list(string) |

## Resources

| Name | Description |
|------|------|
| google_service_account.clickhouse_management_sa | Service Account to manage ClickHouse resources in BYOC project |
| google_project_service.cloud_resource_manager | Enables Cloud Resource Manager service API |
| google_project_iam_custom_role.clickhouse_common_role | Role to allow ClickHouse Cloud common operations |
| google_project_iam_custom_role.clickhouse_vpc_role | Role to allow ClickHouse Cloud to manage VPC resources in your project |
| google_project_iam_custom_role.clickhouse_cluster_role | Role to allow ClickHouse Cloud to manage cluster resources in your project |
| google_project_iam_custom_role.clickhouse_storage_role | Role to allow ClickHouse Cloud to manage Object Storage resources in your project |
| google_project_iam_custom_role.clickhouse_iam_role | Role to allow ClickHouse Cloud to manage IAM resources in your project |
| google_project_iam_member.clickhouse_sa_roles["common_role"] | Grants `clickhouseCommonRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["vpc_role"] | Grants `clickhouseVPCRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["cluster_role"] | Grants `clickhouseClusterRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["storage_role"] | Grants `clickhouseStorageRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["iam_role"] | Grants `clickhouseIamRole` to ClickHouse Management Service Account |
| google_service_account_iam_binding.impersonation_binding | Allows ClickHouse Crossplane Service Account to impersonate ClickHouse Management Service Account |

## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.3 |
| google provider | >=6.38.0, <7 |


