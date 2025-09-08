locals {
  clickhouse_custom_roles = [
    google_project_iam_custom_role.clickhouse_common_role.id,
    google_project_iam_custom_role.clickhouse_vpc_role.id,
    google_project_iam_custom_role.clickhouse_cluster_role.id,
    google_project_iam_custom_role.clickhouse_storage_role.id,
    google_project_iam_custom_role.clickhouse_iam_role.id,
  ]
}
