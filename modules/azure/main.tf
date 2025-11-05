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
