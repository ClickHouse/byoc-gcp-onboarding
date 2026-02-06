resource "azurerm_role_definition" "crossplane_byoc_provisioner" {
  name        = "Crossplane BYOC Provisioner"
  scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  description = "Least-privilege custom role for Crossplane to provision Azure BYOC infrastructure resources"

  permissions {
    actions = [
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
    ]

    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  ]
}
