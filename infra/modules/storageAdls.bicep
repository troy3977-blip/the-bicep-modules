targetScope = 'resourceGroup'

param name string
param location string

resource st 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

output storageId string = st.id
output blobEndpoint string = st.properties.primaryEndpoints.blob
