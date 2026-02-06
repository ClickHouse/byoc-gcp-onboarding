output "tenant_id" {
  description = "The Azure AD tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "The Azure subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
}

output "service_principal_client_id" {
  description = "The application (client) ID of the service principal"
  value       = azuread_service_principal.this.client_id
}
