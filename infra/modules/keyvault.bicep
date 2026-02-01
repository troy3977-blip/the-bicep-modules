targetScope = 'resourceGroup'

param name string
param location string
param enableRbacAuthorization bool = true

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A'; name: 'standard' }
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: 'Enabled'
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
  }
}

output keyVaultId string = kv.id
output keyVaultUri string = kv.properties.vaultUri
