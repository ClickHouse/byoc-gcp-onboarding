output "clickhouse_management_sa_name" {
  value       = google_service_account.clickhouse_management_sa.name
  description = "The name of the ClickHouse Management Service Account"
}
