locals {
  clickhouse_byoc_app_registration_map = {
    "development" = "8b46064b-904c-4f95-9bea-bafff8d5dcc7"
    "staging"     = "34ea6e0e-f1f8-47b0-9d5b-851cfffe02d5"
    "production"  = "a3a33a9e-cea2-47e6-a160-fd2add78f73e"
  }

  # https://learn.microsoft.com/en-us/graph/permissions-reference
  graph_permissions = {
    # OwnedBy (not .All): provisioner only manages apps/SPs it creates and owns.
    # Used for the AKS workload-identity Application/ServicePrincipal — unrelated to
    # engineer access.
    "Application.ReadWrite.OwnedBy" = "18a4783c-866b-4cc7-a460-3d5e5662c884"
    # User.Invite.All / User.ReadWrite.All removed (BYOC-480): engineer access is now
    # granted via per-engineer in-cluster Kubernetes ServiceAccounts + short-lived
    # bound tokens, not Entra B2B guest invitations — so no directory/Graph user
    # permission is required for engineer access.
  }
}
