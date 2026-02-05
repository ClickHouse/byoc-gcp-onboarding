data "azuread_client_config" "current" {}

# Create a service principle of the BYOC application
resource "azuread_service_principal" "this" {
  client_id = local.clickhouse_byoc_app_registration_map[var.environment]
  # it's recommended to always set owner of service principal (using current user here)
  owners = [data.azuread_client_config.current.object_id]
}

data "azurerm_subscription" "it" {
  for_each        = toset(var.subscriptions)
  subscription_id = each.value
}

# Assign proper role definitions to the service principle
resource "azurerm_role_assignment" "this" {
  for_each             = toset(var.subscriptions)
  scope                = data.azurerm_subscription.it[each.key].id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.this.object_id
}

# Get Microsoft Graph service principal
data "azuread_service_principal" "microsoft_graph" {
  client_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
}

# Grant Microsoft Graph permissions to the service principal
resource "azuread_app_role_assignment" "graph_permissions" {
  for_each            = local.graph_permissions
  app_role_id         = each.value
  principal_object_id = azuread_service_principal.this.object_id
  resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id
}
