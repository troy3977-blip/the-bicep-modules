targetScope = 'resourceGroup'

param acrId string
param keyVaultId string

param wfmPrincipalId string
param dotPrincipalId string
param apiPrincipalId string
param includeApi bool

// Built-in role definition IDs (stable)
var roleAcrPull = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
var roleKvSecretsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User

resource wfmAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, wfmPrincipalId, roleAcrPull)
  scope: acrId
  properties: {
    roleDefinitionId: roleAcrPull
    principalId: wfmPrincipalId
  }
}

resource dotAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, dotPrincipalId, roleAcrPull)
  scope: acrId
  properties: {
    roleDefinitionId: roleAcrPull
    principalId: dotPrincipalId
  }
}

resource apiAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (includeApi) {
  name: guid(acrId, apiPrincipalId, roleAcrPull)
  scope: acrId
  properties: {
    roleDefinitionId: roleAcrPull
    principalId: apiPrincipalId
  }
}

resource wfmKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, wfmPrincipalId, roleKvSecretsUser)
  scope: keyVaultId
  properties: {
    roleDefinitionId: roleKvSecretsUser
    principalId: wfmPrincipalId
  }
}

resource dotKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, dotPrincipalId, roleKvSecretsUser)
  scope: keyVaultId
  properties: {
    roleDefinitionId: roleKvSecretsUser
    principalId: dotPrincipalId
  }
}

resource apiKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (includeApi) {
  name: guid(keyVaultId, apiPrincipalId, roleKvSecretsUser)
  scope: keyVaultId
  properties: {
    roleDefinitionId: roleKvSecretsUser
    principalId: apiPrincipalId
  }
}
