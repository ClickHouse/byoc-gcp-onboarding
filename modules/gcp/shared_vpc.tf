# Shared VPC support: granted only when the VPC you bring lives in a separate
# host project (shared_vpc_host_project_id set). All resources here target that host
# project via their explicit project/region/subnetwork arguments, so the
# single google provider's credentials must have IAM admin on both projects.
#
# Prerequisite (customer, org-level): the host project must already be enabled
# as a Shared VPC host and this project attached as a service project.

locals {
  shared_vpc = var.shared_vpc_host_project_id != ""

  # PSC host-project permissions apply only when both Shared VPC is in use and
  # the customer intends to use PrivateLink. When PrivateLink is off we keep the
  # host-project permission surface to the read-only observe set below.
  enable_psc_host = local.shared_vpc && var.enable_shared_vpc_private_link

  # GKE service agents of the service project (this project). These are
  # well-known, derived from the project number, and must be granted access to
  # the host network for a Shared VPC GKE cluster. Referenced only by the
  # Shared-VPC-gated resources below, so the splat is safe when disabled.
  service_project_number   = one(data.google_project.service[*].number)
  gke_service_agent_member = local.shared_vpc ? "serviceAccount:service-${local.service_project_number}@container-engine-robot.iam.gserviceaccount.com" : null
  cloudservices_sa_member  = local.shared_vpc ? "serviceAccount:${local.service_project_number}@cloudservices.gserviceaccount.com" : null

  # Always needed in the host project under Shared VPC: observe the brought
  # network/subnet (Crossplane manages them Observe-only, and the onboarding
  # validator reads them here). Using the node subnet is granted separately via
  # the compute.networkUser binding below.
  shared_vpc_host_base_permissions = [
    "compute.networks.get",
    "compute.subnetworks.get",
  ]

  # PrivateLink only: manage the PSC NAT subnet, which — like every subnet in a
  # Shared VPC — is created in the host project. subnetworks.use lets the
  # service-project ServiceAttachment reference this host subnet as its NAT
  # subnet; regionOperations.get polls the async subnet create/delete. The
  # ServiceAttachment itself lives in the service project and is covered by the
  # service-project clickhouseVPCRole, so no serviceAttachments/forwardingRules
  # permissions are needed here.
  shared_vpc_host_psc_permissions = [
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.update",
    "compute.subnetworks.use",
    "compute.regionOperations.get",
  ]

  shared_vpc_host_permissions = concat(
    local.shared_vpc_host_base_permissions,
    local.enable_psc_host ? local.shared_vpc_host_psc_permissions : [],
  )
}

data "google_project" "service" {
  count = local.shared_vpc ? 1 : 0

  project_id = var.project_id
}

# Permissions ClickHouse needs in the Shared VPC host project: observe the
# brought network/subnet, plus (when PrivateLink is enabled) manage the PSC NAT
# subnet. The exact permission set is assembled in locals from the base +
# optional PSC groups.
resource "google_project_iam_custom_role" "clickhouse_shared_vpc_host_role" {
  count = local.shared_vpc ? 1 : 0

  project     = var.shared_vpc_host_project_id
  role_id     = "clickhouseSharedVPCHostRole"
  title       = "ClickHouse Shared VPC Host Role"
  description = "Role to allow ClickHouse Cloud to observe the Shared VPC host network/subnet (and manage the PrivateLink PSC NAT subnet when enabled)"
  permissions = local.shared_vpc_host_permissions
}

resource "google_project_iam_member" "clickhouse_sa_shared_vpc_host_role" {
  count = local.shared_vpc ? 1 : 0

  project = var.shared_vpc_host_project_id
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
  project    = var.shared_vpc_host_project_id
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

  # The region/subnet are consumed here, so this is where we assert they were
  # supplied alongside shared_vpc_host_project_id (Terraform < 1.9 can't do
  # cross-variable validation in the variable block itself).
  lifecycle {
    precondition {
      condition     = var.shared_vpc_host_subnet_region != "" && var.shared_vpc_host_private_subnet_id != ""
      error_message = "shared_vpc_host_subnet_region and shared_vpc_host_private_subnet_id are required when shared_vpc_host_project_id is set."
    }
  }

  depends_on = [google_project_service.container]
  project    = var.shared_vpc_host_project_id
  region     = var.shared_vpc_host_subnet_region
  subnetwork = var.shared_vpc_host_private_subnet_id
  role       = "roles/compute.networkUser"
  member     = each.value
}
