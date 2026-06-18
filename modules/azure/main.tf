data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {
  subscription_id = data.azurerm_client_config.current.subscription_id
}
data "azuread_service_principal" "microsoft_graph" {
  client_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
}

# Create a service principle of the BYOC application
resource "azuread_service_principal" "this" {
  client_id = local.clickhouse_byoc_app_registration_map[var.environment]
  # it's recommended to always set owner of service principal (using current user here)
  owners = [data.azuread_client_config.current.object_id]
}

# Assign proper role definitions to the service principle
resource "azurerm_role_assignment" "this" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.clickhouse_byoc_provisioner.role_definition_resource_id
  principal_id       = azuread_service_principal.this.object_id

  # Constrained delegation: the provisioner may create/delete role assignments,
  # but NOT for the privileged roles (Owner, Contributor, User Access Admin,
  # RBAC Admin) — removes the escalate-to-Owner path while leaving the scoped
  # data-plane and dynamic per-instance custom-role assignments unaffected.
  condition_version = "2.0"
  condition         = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, b24988ac-6180-42a0-ab88-20f7382dd24c, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, b24988ac-6180-42a0-ab88-20f7382dd24c, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
     )
    )
  EOT
}

# Grant Microsoft Graph permissions to the service principal
resource "azuread_app_role_assignment" "graph_permissions" {
  for_each            = local.graph_permissions
  app_role_id         = each.value
  principal_object_id = azuread_service_principal.this.object_id
  resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id
}
