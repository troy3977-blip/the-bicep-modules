targetScope = 'resourceGroup'

param name string
param location string
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: { name: sku }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output loginServer string = acr.properties.loginServer
output acrId string = acr.id
