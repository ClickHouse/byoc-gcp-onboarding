output "clickhouse_management_sa_name" {
  value       = google_service_account.clickhouse_management_sa.name
  description = "The name of the ClickHouse Management Service Account"
}

output "clickhouse_management_sa_roles" {
  value = [
    for role_assignment in google_project_iam_member.clickhouse_sa_roles : role_assignment.role
  ]
  description = "List of role IDs assigned to the ClickHouse Management Service Account"
}

output "clickhouse_management_sa_roles" {
  value = [
    for role_assignment in google_project_iam_member.clickhouse_sa_roles : role_assignment.role
  ]
  description = "List of role IDs assigned to the ClickHouse Management Service Account"
}
