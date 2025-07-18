locals {
  clickhouse_sa_roles = {
    network_admin = {
      # Manage VPC
      role = "roles/compute.networkAdmin"
    }
    service_account_admin = {
      # Manage SA
      role = "roles/iam.serviceAccountAdmin"
    }
    service_account_user = {
      # We need iam.serviceAccounts.actAs permission to deploy GKE
      role = "roles/iam.serviceAccountUser"
    }
    storage_admin = {
      # Manage storage
      role = "roles/storage.admin"
    }
    container_admin = {
      # Manage GKE
      role = "roles/container.admin"
    }
  }
}
