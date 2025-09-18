locals {
  clickhouse_custom_roles = {
    common_role  = google_project_iam_custom_role.clickhouse_common_role.id
    vpc_role     = google_project_iam_custom_role.clickhouse_vpc_role.id
    cluster_role = google_project_iam_custom_role.clickhouse_cluster_role.id
    storage_role = google_project_iam_custom_role.clickhouse_storage_role.id
    iam_role     = google_project_iam_custom_role.clickhouse_iam_role.id
  }
  clickhouse_crossplane_sa_map = {
    "production" = [
      "serviceAccount:asia-southeast1-gke-crossplane@dataplane-production.iam.gserviceaccount.com",
      "serviceAccount:europe-west4-gke-crossplane@dataplane-production.iam.gserviceaccount.com",
      "serviceAccount:us-central1-gke-crossplane@dataplane-production.iam.gserviceaccount.com",
      "serviceAccount:us-east1-gke-crossplane@dataplane-production.iam.gserviceaccount.com",
    ]
    "staging" = [
      "serviceAccount:us-central1-gke-crossplane@dataplane-staging.iam.gserviceaccount.com",
    ]
    "development" = [
      "serviceAccount:us-east1-gke-crossplane@dataplane-development.iam.gserviceaccount.com",
    ]
  }
}
