# ClickHouse BYOC GCP Onboarding Terraform Module

This repository contains Terraform module to bootstrap a BYOC GCP project for ClickHouse Cloud.

## Usage

```hcl
provider "google" {
  project = "replace-with-your-clickhouse-byoc-project-id"
}

module "clickhouse_onboarding" {
  source     = "github.com/ClickHouse/terraform-byoc-onboarding.git//modules/gcp?ref=<version>"
  project_id = "replace-with-your-clickhouse-byoc-project-id"
}
```

Replace `<version>` with the latest tag from the module's
[releases page](https://github.com/ClickHouse/terraform-byoc-onboarding/releases)
— always use the latest release.

### Bring your own VPC (same project)

If you pre-create and manage the VPC network, routes, and Cloud NAT yourself within the BYOC project, set `include_vpc_write_permissions = false`. ClickHouse then does **not** get permissions to create, delete, or modify the network topology (networks, routes, Cloud Routers, subnet attributes), but retains read and use access to it. ClickHouse still creates and manages the resources it owns inside your VPC — the PrivateLink (PSC) NAT subnet and service attachment, and ingress/static IP addresses — so PrivateLink and load balancers keep working.

```hcl
module "clickhouse_onboarding" {
  source                        = "github.com/ClickHouse/terraform-byoc-onboarding.git//modules/gcp?ref=<version>"
  project_id                    = "replace-with-your-clickhouse-byoc-project-id"
  include_vpc_write_permissions = false
}
```

Replace `<version>` with the latest tag from the module's
[releases page](https://github.com/ClickHouse/terraform-byoc-onboarding/releases)
— always use the latest release.

If the VPC you bring instead lives in a **different** project, use the Shared VPC setup below.

### Shared VPC (bring a VPC from a different project)

If the VPC you bring lives in a **different** GCP project (the Shared VPC *host* project) than the BYOC *service* project where ClickHouse runs GKE, set `shared_vpc_host_project_id` (plus the host subnet's `shared_vpc_host_subnet_region` and `shared_vpc_host_private_subnet_id`). The module then grants the network and GKE Shared VPC permissions in the host project, in addition to the standard service-project setup.

```hcl
module "clickhouse_onboarding" {
  source                            = "github.com/ClickHouse/terraform-byoc-onboarding.git//modules/gcp?ref=<version>"
  project_id                        = "replace-with-your-clickhouse-byoc-service-project-id"
  shared_vpc_host_project_id        = "replace-with-your-shared-vpc-host-project-id"
  shared_vpc_host_subnet_region     = "us-central1"
  shared_vpc_host_private_subnet_id = "replace-with-your-host-subnet-name"
  enable_shared_vpc_private_link    = true # only if you will use ClickHouse Private Service Connect (PrivateLink)
}
```

Replace `<version>` with the latest tag from the module's
[releases page](https://github.com/ClickHouse/terraform-byoc-onboarding/releases)
— always use the latest release.

By default the host project grants are read-only (observe the brought network/subnet); GKE consumes the host subnet via a `compute.networkUser` binding. Set `enable_shared_vpc_private_link = true` to additionally grant the host-project permissions needed to manage the PrivateLink PSC NAT subnet (subnets in a Shared VPC belong to the host project). Leave it `false` to keep the host-project permission surface minimal.

**Prerequisites for Shared VPC:**

- The host project must already be enabled as a [Shared VPC host](https://cloud.google.com/vpc/docs/provisioning-shared-vpc) and the service project (`project_id`) attached to it. This is an org-level operation (`compute.xpnAdmin`) and is **not** performed by this module.
- The credentials running this module must have IAM admin on **both** the service project (`project_id`) and the host project (`shared_vpc_host_project_id`).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | (Required) The GCP project ID where resources will be provisioned | string | n/a | yes |
| environment | (Optional) Environment. Default is `production`. The other values are reserved for internal use | string | `production` | no |
| include_vpc_write_permissions | (Optional) Whether to grant permissions to manage your VPC network topology (create/delete/modify of networks, routes, Cloud Routers, and subnet attributes). Set to `false` for bring-your-own-VPC onboarding. ClickHouse always retains read and use access to the VPC and manages the resources it owns inside it (PrivateLink/PSC NAT subnet and service attachment, ingress/static IP addresses) | bool | `true` | no |
| shared_vpc_host_project_id | (Optional) The GCP project ID of the Shared VPC host project, when the VPC you bring lives in a different project than `project_id`. Leave empty for the standard same-project setup. When set, `shared_vpc_host_subnet_region` and `shared_vpc_host_private_subnet_id` are required | string | `""` | no |
| shared_vpc_host_subnet_region | (Optional) The region of the Shared VPC host subnet. Required only when `shared_vpc_host_project_id` is set | string | `""` | no |
| shared_vpc_host_private_subnet_id | (Optional) The name of the existing Shared VPC host subnet used for GKE nodes. Required only when `shared_vpc_host_project_id` is set | string | `""` | no |
| enable_shared_vpc_private_link | (Optional) Set to true if you will use ClickHouse Private Service Connect (PrivateLink) with this Shared VPC. Grants the additional host-project permissions to manage the PSC NAT subnet. Only takes effect when `shared_vpc_host_project_id` is set | bool | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| clickhouse_management_sa_name | The name of the ClickHouse Management Service Account | string |
| clickhouse_management_sa_roles | List of role IDs assigned to the ClickHouse Management Service Account | list(string) |
| shared_vpc_enabled | Whether Shared VPC host-project resources were provisioned (true when `shared_vpc_host_project_id` is set) | bool |
| shared_vpc_host_role | The ID of the ClickHouse Shared VPC host role granted in the host project, or null when Shared VPC is not used | string |
| gke_service_agent_member | The service project's GKE service agent granted access to the Shared VPC host project, or null when Shared VPC is not used | string |

## Resources

| Name | Description |
|------|------|
| google_service_account.clickhouse_management_sa | Service Account to manage ClickHouse resources in BYOC project |
| google_project_service.cloud_resource_manager | Enables Cloud Resource Manager service API |
| google_project_iam_custom_role.clickhouse_common_role | Role to allow ClickHouse Cloud common operations |
| google_project_iam_custom_role.clickhouse_vpc_role | Role to allow ClickHouse Cloud to read and use VPC resources, and to create/manage the ClickHouse-owned subnets, addresses, and PrivateLink (PSC) it provisions within the VPC |
| google_project_iam_custom_role.clickhouse_vpc_write_role | Role to allow ClickHouse Cloud to create/delete/modify the VPC network topology (networks, routes, Cloud Routers, subnet attributes); created only when `include_vpc_write_permissions` is true |
| google_project_iam_custom_role.clickhouse_cluster_role | Role to allow ClickHouse Cloud to manage cluster resources in your project |
| google_project_iam_custom_role.clickhouse_storage_role | Role to allow ClickHouse Cloud to manage Object Storage resources in your project |
| google_project_iam_custom_role.clickhouse_iam_role | Role to allow ClickHouse Cloud to manage IAM resources in your project |
| google_project_iam_member.clickhouse_sa_roles["common_role"] | Grants `clickhouseCommonRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["vpc_role"] | Grants `clickhouseVPCRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["vpc_write_role"] | Grants `clickhouseVPCWriteRole` to ClickHouse Management Service Account; present only when `include_vpc_write_permissions` is true |
| google_project_iam_member.clickhouse_sa_roles["cluster_role"] | Grants `clickhouseClusterRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["storage_role"] | Grants `clickhouseStorageRole` to ClickHouse Management Service Account |
| google_project_iam_member.clickhouse_sa_roles["iam_role"] | Grants `clickhouseIamRole` to ClickHouse Management Service Account |
| google_service_account_iam_binding.impersonation_binding | Allows ClickHouse Crossplane Service Account to impersonate ClickHouse Management Service Account |
| google_project_iam_custom_role.clickhouse_shared_vpc_host_role | [Shared VPC] Role to observe the host network/subnet, plus manage the PrivateLink PSC NAT subnet when `enable_shared_vpc_private_link` is true |
| google_project_iam_member.clickhouse_sa_shared_vpc_host_role | [Shared VPC] Grants `clickhouseSharedVPCHostRole` to ClickHouse Management Service Account in the host project |
| google_project_service.container | [Shared VPC] Enables the Container API on the service project so its GKE service agent exists |
| google_project_iam_member.gke_host_service_agent_user | [Shared VPC] Grants `roles/container.hostServiceAgentUser` to the service project's GKE service agent on the host project |
| google_compute_subnetwork_iam_member.network_user | [Shared VPC] Grants `roles/compute.networkUser` on the host subnet to the GKE service agent, Google APIs SA, and ClickHouse Management Service Account |

## Requirements

| Name | Version |
|------|---------|
| terraform | >=1.3 |
| google provider | >=6.38.0, <7 |
