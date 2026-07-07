# ClickHouse BYOC AWS Onboarding — Per-Infra IAM

> **GENERATED MODULE — do not edit.**
> This module is generated and published automatically by ClickHouse.
> Manual edits will be overwritten by the next sync.

This Terraform module provisions the per-infrastructure IAM roles (EKS pod
identity roles, the ClickHouse S3 access role, and the data-plane management
role) required to run a ClickHouse BYOC (Bring Your Own Cloud) deployment in a
specific AWS region.

> [!IMPORTANT]
> Keep `byoc_env = "production"` (this is the default). Do **not** change it.
> `production` is the only supported value for customer onboarding. Setting any
> other value points the roles at non-production ClickHouse accounts and will
> break onboarding.

> [!IMPORTANT]
> ClickHouse periodically adds roles and permissions to this module. Always use
> the **latest release**, and re-apply the module when ClickHouse notifies you
> of an update — otherwise provisioning and upgrades of your BYOC
> infrastructure can fail.

## Usage

```hcl
module "clickhouse_per_infra_iam" {
  source = "github.com/ClickHouse/terraform-byoc-onboarding.git//modules/aws-per-infra-iam?ref=<version>"

  # Required
  spoken_name = "<spoken-name-provided-by-clickhouse>"
  region      = "us-west-2"
  external_id = "<external-id-provided-by-clickhouse>"
}
```

Replace `<version>` with the latest tag from the module's
[releases page](https://github.com/ClickHouse/terraform-byoc-onboarding/releases)
— always use the latest release.

The module is also published as a tarball at
`https://s3.us-east-2.amazonaws.com/clickhouse-public-resources.clickhouse.cloud/tf/iam_per_infra.tar.gz`,
which can be used as `source` directly; the GitHub module above is the
recommended source.

## Inputs

| Name          | Description                                                        | Type     | Default | Required |
| ------------- | ------------------------------------------------------------------ | -------- | ------- | :------: |
| `spoken_name` | The spoken name of the BYOC infra, provided by ClickHouse.         | `string` | n/a     |   yes    |
| `region`      | The AWS region to deploy the BYOC infra into.                      | `string` | n/a     |   yes    |
| `external_id` | Unique identifier for role assumption, provided by ClickHouse.     | `string` | n/a     |   yes    |

> `byoc_env` exists for internal ClickHouse use only. Leave it at its default
> (`production`). See the note above.

## Outputs

| Name                            | Description                                       |
| ------------------------------- | ------------------------------------------------- |
| `data_plane_management_role_arn`| ARN of the created data-plane management role.    |
| `ch_s3_role_arn`                | ARN of the created ClickHouse S3 access role.     |
