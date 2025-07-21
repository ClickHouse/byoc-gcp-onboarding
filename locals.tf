locals {
  clickhouse_sa_roles = {
    compute_network_admin = {
      # Manage VPC
      role = "roles/compute.networkAdmin"
    }
    iam_service_account_admin = {
      # Manage SA
      role = "roles/iam.serviceAccountAdmin"
    }
    iam_service_account_key_admin = {
      # Manage SA keys
      role = "roles/iam.serviceAccountKeyAdmin"
    }
    iam_service_account_user = {
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
    resourcemanager_project_iam_admin = {
      # Required to grant roles/container.defaultNodeServiceAccount to nodePool SA
      role = "roles/resourcemanager.projectIamAdmin"
    }
  }
}
