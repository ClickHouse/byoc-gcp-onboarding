# Shared VPC support: granted only when the VPC you bring lives in a separate
# host project (shared_vpc_host_project_id set). All resources here target that host
# project via their explicit project/region/subnetwork arguments, so the
# single google provider's credentials must have IAM admin on both projects.
#
# Prerequisite (customer, org-level): the host project must already be enabled
# as a Shared VPC host and this project attached as a service project.

locals {
  shared_vpc = var.shared_vpc_host_project_id != ""

  # GKE service agents of the service project (this project). These are
  # well-known, derived from the project number, and must be granted access to
  # the host network for a Shared VPC GKE cluster. Referenced only by the
  # Shared-VPC-gated resources below, so the splat is safe when disabled.
  service_project_number   = one(data.google_project.service[*].number)
  gke_service_agent_member = local.shared_vpc ? "serviceAccount:service-${local.service_project_number}@container-engine-robot.iam.gserviceaccount.com" : null
  cloudservices_sa_member  = local.shared_vpc ? "serviceAccount:${local.service_project_number}@cloudservices.gserviceaccount.com" : null

  # Host-project permissions under Shared VPC. Everything ClickHouse touches in
  # the host project is either observed or used, never created: Crossplane
  # manages the brought network/subnet Observe-only, and the PSC NAT subnet is
  # pre-created by the customer. subnetworks.use lets the service-project
  # ServiceAttachment reference that PSC subnet as its NAT subnet — subnets in a
  # Shared VPC belong to the host project. The ServiceAttachment itself lives in
  # the service project and is covered by the service-project clickhouseVPCRole,
  # so no serviceAttachments/forwardingRules permissions are needed here. Using
  # the node subnet is granted separately via the compute.networkUser binding
  # below.
  shared_vpc_host_permissions = [
    "compute.networks.get",
    "compute.subnetworks.get",
    "compute.subnetworks.use",
  ]

  # Under Shared VPC, GKE creates its firewall rules in the host project (the
  # cluster's network lives there), but the service project's GKE service agent
  # has no authority to write them: hostServiceAgentUser + subnet networkUser do
  # not include compute.firewalls. Without these the L4 ILB health-check rule
  # (130.211.0.0/22, 35.191.0.0/16) is never created -> istio-ingress-private
  # backends stay unhealthy -> PrivateLink PSC is dead; and the master->node
  # rule (tcp 10250/443) breaks admission webhooks and metrics-server. This is
  # GCP's documented granular alternative to roles/compute.securityAdmin.
  gke_shared_vpc_firewall_permissions = [
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.firewalls.update",
    "compute.networks.updatePolicy",
  ]
}

data "google_project" "service" {
  count = local.shared_vpc ? 1 : 0

  project_id = var.project_id
}

# Permissions ClickHouse needs in the Shared VPC host project: observe the
# brought network/subnet and use the customer-provided PrivateLink PSC NAT
# subnet. Read + use only; nothing here writes to the host project.
resource "google_project_iam_custom_role" "clickhouse_shared_vpc_host_role" {
  count = local.shared_vpc ? 1 : 0

  project     = var.shared_vpc_host_project_id
  role_id     = "clickhouseSharedVPCHostRole"
  title       = "ClickHouse Shared VPC Host Role"
  description = "Role to allow ClickHouse Cloud to observe the Shared VPC host network/subnet and use the customer-provided PrivateLink PSC NAT subnet"
  permissions = local.shared_vpc_host_permissions
}

resource "google_project_iam_member" "clickhouse_sa_shared_vpc_host_role" {
  count = local.shared_vpc ? 1 : 0

  project = var.shared_vpc_host_project_id
  role    = google_project_iam_custom_role.clickhouse_shared_vpc_host_role[0].id
  member  = google_service_account.clickhouse_management_sa.member
}

# GKE Shared VPC: the service project's GKE service agent must be able to act on
# the host project. It depends on the service project's Container API, enabled
# unconditionally in main.tf, so the agent exists before we grant it anything.
resource "google_project_iam_member" "gke_host_service_agent_user" {
  count = local.shared_vpc ? 1 : 0

  depends_on = [google_project_service.container_api]
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

  depends_on = [google_project_service.container_api]
  project    = var.shared_vpc_host_project_id
  region     = var.shared_vpc_host_subnet_region
  subnetwork = var.shared_vpc_host_private_subnet_id
  role       = "roles/compute.networkUser"
  member     = each.value
}

# Enable the Container API on the host project too. This provisions the host
# project's own GKE service agent and auto-grants it roles/container.serviceAgent
# there, which is what creates the cluster-lifecycle firewall rules in the host
# network via the hostServiceAgentUser delegation above. disable_on_destroy is
# false: other clusters/service-projects may share this host project.
resource "google_project_service" "container_host" {
  count = local.shared_vpc ? 1 : 0

  project            = var.shared_vpc_host_project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

# Scoped firewall authority for the service project's GKE service agent in the
# host project. GKE's in-cluster controllers (e.g. the L4 ILB controller for
# istio-ingress-private) run as this agent and create/update firewall rules in
# the host network; hostServiceAgentUser does not cover compute.firewalls.
resource "google_project_iam_custom_role" "clickhouse_gke_shared_vpc_firewall_role" {
  count = local.shared_vpc ? 1 : 0

  project     = var.shared_vpc_host_project_id
  role_id     = "clickhouseGKESharedVPCFirewallRole"
  title       = "ClickHouse GKE Shared VPC Firewall Role"
  description = "Allows the service project's GKE service agent to manage its cluster/load-balancer firewall rules in the Shared VPC host project"
  permissions = local.gke_shared_vpc_firewall_permissions
}

resource "google_project_iam_member" "gke_shared_vpc_firewall" {
  count = local.shared_vpc ? 1 : 0

  depends_on = [google_project_service.container_api]
  project    = var.shared_vpc_host_project_id
  role       = google_project_iam_custom_role.clickhouse_gke_shared_vpc_firewall_role[0].id
  member     = local.gke_service_agent_member
}
