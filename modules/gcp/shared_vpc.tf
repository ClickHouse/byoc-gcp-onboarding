# Shared VPC support: granted only when the VPC you bring lives in a separate
# host project (network_project_id set). All resources here target that host
# project via their explicit project/region/subnetwork arguments, so the
# single google provider's credentials must have IAM admin on both projects.
#
# Prerequisite (customer, org-level): the host project must already be enabled
# as a Shared VPC host and this project attached as a service project.

locals {
  shared_vpc = var.network_project_id != ""

  # GKE service agents of the service project (this project). These are
  # well-known, derived from the project number, and must be granted access to
  # the host network for a Shared VPC GKE cluster. Referenced only by the
  # Shared-VPC-gated resources below, so the splat is safe when disabled.
  service_project_number   = one(data.google_project.service[*].number)
  gke_service_agent_member = local.shared_vpc ? "serviceAccount:service-${local.service_project_number}@container-engine-robot.iam.gserviceaccount.com" : null
  cloudservices_sa_member  = local.shared_vpc ? "serviceAccount:${local.service_project_number}@cloudservices.gserviceaccount.com" : null
}

data "google_project" "service" {
  count = local.shared_vpc ? 1 : 0

  project_id = var.project_id
}

# Network/PSC permissions ClickHouse needs in the host project: observe the
# brought network/subnet and create the PrivateLink PSC subnet + service
# attachment in the host VPC.
resource "google_project_iam_custom_role" "clickhouse_shared_vpc_host_role" {
  count = local.shared_vpc ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.region != "" && var.private_subnet_id != ""
      error_message = "region and private_subnet_id are required when network_project_id is set."
    }
  }

  project     = var.network_project_id
  role_id     = "clickhouseSharedVPCHostRole"
  title       = "ClickHouse Shared VPC Host Role"
  description = "Role to allow ClickHouse Cloud to use the Shared VPC host network and manage PrivateLink resources in the host project"
  permissions = [
    # Network
    "compute.networks.get",
    "compute.networks.use",

    # Subnetwork (observe brought subnet, manage PSC NAT subnet)
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.use",

    # Private Service Connect
    "compute.serviceAttachments.create",
    "compute.serviceAttachments.delete",
    "compute.serviceAttachments.get",
    "compute.serviceAttachments.list",
    "compute.serviceAttachments.update",
    "compute.forwardingRules.use",
    "compute.regionOperations.get",
  ]
}

resource "google_project_iam_member" "clickhouse_sa_shared_vpc_host_role" {
  count = local.shared_vpc ? 1 : 0

  project = var.network_project_id
  role    = google_project_iam_custom_role.clickhouse_shared_vpc_host_role[0].id
  member  = google_service_account.clickhouse_management_sa.member
}

# Enable the Container API on the service project so its GKE service agent is
# created before we grant it access to the host network.
resource "google_project_service" "container" {
  count = local.shared_vpc ? 1 : 0

  service            = "container.googleapis.com"
  disable_on_destroy = false
}

# GKE Shared VPC: the service project's GKE service agent must be able to act on
# the host project.
resource "google_project_iam_member" "gke_host_service_agent_user" {
  count = local.shared_vpc ? 1 : 0

  depends_on = [google_project_service.container]
  project    = var.network_project_id
  role       = "roles/container.hostServiceAgentUser"
  member     = local.gke_service_agent_member
}

# compute.networkUser on the host subnet for the principals that consume it:
# the GKE service agent, the Google APIs (cloudservices) SA, and the ClickHouse
# management SA that creates the cluster and PSC resources.
resource "google_compute_subnetwork_iam_member" "network_user" {
  for_each = local.shared_vpc ? {
    gke_service_agent = local.gke_service_agent_member
    cloudservices     = local.cloudservices_sa_member
    management_sa     = google_service_account.clickhouse_management_sa.member
  } : {}

  depends_on = [google_project_service.container]
  project    = var.network_project_id
  region     = var.region
  subnetwork = var.private_subnet_id
  role       = "roles/compute.networkUser"
  member     = each.value
}
