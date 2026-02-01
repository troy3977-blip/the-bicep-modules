targetScope = 'resourceGroup'

param location string
param serverName string
param databaseName string
param allowAzureServices bool = true

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
    administrators: null
  }
}

resource firewallAzure 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (allowAzureServices) {
  name: '${sqlServer.name}/AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource db 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: '${sqlServer.name}/${databaseName}'
  sku: { name: 'GP_S_Gen5_2' }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

output serverFqdn string = '${sqlServer.name}.database.windows.net'
output serverId string = sqlServer.id
output databaseId string = db.id
