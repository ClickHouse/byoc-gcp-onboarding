locals {
  clickhouse_custom_roles = {
    common_role  = google_project_iam_custom_role.clickhouse_common_role.id
    vpc_role     = google_project_iam_custom_role.clickhouse_vpc_role.id
    cluster_role = google_project_iam_custom_role.clickhouse_cluster_role.id
    storage_role = google_project_iam_custom_role.clickhouse_storage_role.id
    iam_role     = google_project_iam_custom_role.clickhouse_iam_role.id
  }
}
