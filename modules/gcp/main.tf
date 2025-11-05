# Create Clickhouse Management SA
resource "google_service_account" "clickhouse_management_sa" {
  account_id   = "clickhouse-management"
  display_name = "ClickHouse Management Service Account"
  description  = "Service account for ClickHouse Management"
}

# Make sure that Cloud Resource Manager is enabled
resource "google_project_service" "cloud_resource_manager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Grant IAM roles to ClickHouse Management SA
resource "google_project_iam_member" "clickhouse_sa_roles" {
  for_each = local.clickhouse_custom_roles

  depends_on = [google_project_service.cloud_resource_manager]
  project    = var.project_id
  role       = each.value
  member     = google_service_account.clickhouse_management_sa.member
}

# Allow Crossplane to impersonate ClickHouse Management SA
resource "google_service_account_iam_binding" "impersonation_binding" {
  service_account_id = google_service_account.clickhouse_management_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = local.clickhouse_crossplane_sa_map[var.environment]
}
