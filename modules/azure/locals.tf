locals {
  clickhouse_byoc_app_registration_map = {
    "development" = "8b46064b-904c-4f95-9bea-bafff8d5dcc7"
    "staging"     = "34ea6e0e-f1f8-47b0-9d5b-851cfffe02d5"
    "production"  = "a3a33a9e-cea2-47e6-a160-fd2add78f73e"
  }

  # https://learn.microsoft.com/en-us/graph/permissions-reference
  graph_permissions = {
    "Application.ReadWrite.All" = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"
    "User.Invite.All"           = "09850681-111b-4a89-9bed-3f2cae46d706"
    "User.ReadWrite.All"        = "741f803b-c850-494e-b5df-cde7c675a1ca"
  }
}
