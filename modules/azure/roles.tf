locals {
  # BYOC+TDE control-plane actions: create and read the infra's default Key Vault (RBAC mode)
  # holding the shared KEK. Deliberately NO vaults/delete and NO deletedVaults purge — key
  # material must never be destroyable by ClickHouse's identity (the vault is orphaned on infra
  # teardown and remains the customer's).
  tde_keyvault_actions = [
    "Microsoft.KeyVault/register/action",
    "Microsoft.KeyVault/checkNameAvailability/read",
    "Microsoft.KeyVault/locations/deletedVaults/read",
    "Microsoft.KeyVault/vaults/read",
    "Microsoft.KeyVault/vaults/write",
  ]

  # BYOC+TDE data-plane actions: manage the KEK inside the vault (keys are created through the
  # Key Vault data plane, so control-plane actions alone are not enough). Deliberately NO
  # keys/delete, NO keys/purge and NO cryptographic actions (encrypt/decrypt/wrap/unwrap) — only
  # the TDE delegate identity gets Key Vault Crypto User on the key.
  tde_keyvault_data_actions = [
    "Microsoft.KeyVault/vaults/keys/read",
    "Microsoft.KeyVault/vaults/keys/create/action",
    "Microsoft.KeyVault/vaults/keys/update/action",
    "Microsoft.KeyVault/vaults/keys/rotationpolicy/read",
  ]
}

resource "azurerm_role_definition" "clickhouse_byoc_provisioner" {
  name        = "ClickHouse BYOC Provisioner (${var.environment})"
  scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  description = "Least-privilege custom role for ClickHouse to provision Azure BYOC infrastructure resources"

  permissions {
    actions = concat([
      # Resource Provider Registration
      "Microsoft.Network/register/action",
      "Microsoft.ContainerService/register/action",
      "Microsoft.ManagedIdentity/register/action",
      "Microsoft.Storage/register/action",

      # Resource Groups
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Resources/subscriptions/resourceGroups/delete",

      # Virtual Networks & Subnets
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Network/virtualNetworks/subnets/delete",
      "Microsoft.Network/virtualNetworks/subnets/join/action",

      # Public IPs
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",

      # NAT Gateways
      "Microsoft.Network/natGateways/read",
      "Microsoft.Network/natGateways/write",
      "Microsoft.Network/natGateways/delete",
      "Microsoft.Network/natGateways/join/action",

      # NSG
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/networkSecurityGroups/delete",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/networkSecurityGroups/securityRules/read",
      "Microsoft.Network/networkSecurityGroups/securityRules/write",
      "Microsoft.Network/networkSecurityGroups/securityRules/delete",

      # Private Link Services & load balancer frontends: ClickHouse fronts the
      # private AKS API server's internal load balancer with a Private Link
      # Service so the ClickHouse management plane can reach it without a
      # public endpoint. The join action authorizes referencing the
      # AKS-managed kube-apiserver frontend when creating the PLS.
      "Microsoft.Network/privateLinkServices/read",
      "Microsoft.Network/privateLinkServices/write",
      "Microsoft.Network/privateLinkServices/delete",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/frontendIPConfigurations/read",
      "Microsoft.Network/loadBalancers/frontendIPConfigurations/join/action",

      # DNS Zones
      "Microsoft.Network/dnszones/read",
      "Microsoft.Network/dnszones/write",
      "Microsoft.Network/dnszones/delete",
      "Microsoft.Network/dnszones/NS/read",
      "Microsoft.Network/dnszones/NS/write",
      "Microsoft.Network/dnszones/NS/delete",

      # Storage Accounts & Containers
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/delete",
      "Microsoft.Storage/storageAccounts/listkeys/action",
      "Microsoft.Storage/storageAccounts/blobServices/read",
      "Microsoft.Storage/storageAccounts/blobServices/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/delete",
      "Microsoft.Storage/storageAccounts/fileServices/read",

      # AKS Clusters & Node Pools
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/write",
      "Microsoft.ContainerService/managedClusters/delete",
      "Microsoft.ContainerService/managedClusters/agentPools/read",
      "Microsoft.ContainerService/managedClusters/agentPools/write",
      "Microsoft.ContainerService/managedClusters/agentPools/delete",
      "Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",

      # Managed Identities & Federated Credentials
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/delete",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/delete",

      # Role Definitions & Assignments
      "Microsoft.Authorization/roleDefinitions/read",
      "Microsoft.Authorization/roleDefinitions/write",
      "Microsoft.Authorization/roleDefinitions/delete",
      "Microsoft.Authorization/roleAssignments/read",
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
    ], var.include_tde_permissions ? local.tde_keyvault_actions : [])

    not_actions = []

    data_actions = var.include_tde_permissions ? local.tde_keyvault_data_actions : []
  }

  assignable_scopes = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  ]
}
