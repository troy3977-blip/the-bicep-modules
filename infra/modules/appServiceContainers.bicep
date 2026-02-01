targetScope = 'resourceGroup'

param location string
param planName string
param sku string

param acrLoginServer string
param acrResourceId string
param appInsightsConnectionString string

param wfmAppName string
param dotAppName string
param apiAppName string

param imageWfm string
param imageDot string
param imageApi string  // empty => skip

param keyVaultName string

param enableDataPlatform bool
param sqlServerFqdn string
param sqlDbName string
param storageAccountName string

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  sku: {
    name: sku
    tier: 'PremiumV3'
  }
  properties: {
    reserved: true // Linux
  }
}

resource wfm 'Microsoft.Web/sites@2023-12-01' = {
  name: wfmAppName
  location: location
  kind: 'app,linux,container'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${imageWfm}'
      appSettings: [
        { name: 'WEBSITES_PORT'; value: '8501' } // Streamlit default
        { name: 'DOCKER_REGISTRY_SERVER_URL'; value: 'https://${acrLoginServer}' }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'; value: appInsightsConnectionString }
        { name: 'KEYVAULT_NAME'; value: keyVaultName }

        // Optional data platform pointers (your app can choose to use them)
        { name: 'SQL_SERVER'; value: enableDataPlatform ? sqlServerFqdn : '' }
        { name: 'SQL_DATABASE'; value: enableDataPlatform ? sqlDbName : '' }
        { name: 'STORAGE_ACCOUNT'; value: enableDataPlatform ? storageAccountName : '' }
      ]
    }
  }
}

resource dot 'Microsoft.Web/sites@2023-12-01' = {
  name: dotAppName
  location: location
  kind: 'app,linux,container'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${imageDot}'
      appSettings: [
        { name: 'WEBSITES_PORT'; value: '8501' }
        { name: 'DOCKER_REGISTRY_SERVER_URL'; value: 'https://${acrLoginServer}' }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'; value: appInsightsConnectionString }
        { name: 'KEYVAULT_NAME'; value: keyVaultName }
        { name: 'SQL_SERVER'; value: enableDataPlatform ? sqlServerFqdn : '' }
        { name: 'SQL_DATABASE'; value: enableDataPlatform ? sqlDbName : '' }
        { name: 'STORAGE_ACCOUNT'; value: enableDataPlatform ? storageAccountName : '' }
      ]
    }
  }
}

resource api 'Microsoft.Web/sites@2023-12-01' = if (!empty(imageApi)) {
  name: apiAppName
  location: location
  kind: 'app,linux,container'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${imageApi}'
      appSettings: [
        { name: 'WEBSITES_PORT'; value: '8000' } // typical FastAPI
        { name: 'DOCKER_REGISTRY_SERVER_URL'; value: 'https://${acrLoginServer}' }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'; value: appInsightsConnectionString }
        { name: 'KEYVAULT_NAME'; value: keyVaultName }
        { name: 'SQL_SERVER'; value: enableDataPlatform ? sqlServerFqdn : '' }
        { name: 'SQL_DATABASE'; value: enableDataPlatform ? sqlDbName : '' }
        { name: 'STORAGE_ACCOUNT'; value: enableDataPlatform ? storageAccountName : '' }
      ]
    }
  }
}

output wfmDefaultHostname string = wfm.properties.defaultHostName
output dotDefaultHostname string = dot.properties.defaultHostName
output apiDefaultHostname string = !empty(imageApi) ? api.properties.defaultHostName : ''

output wfmPrincipalId string = wfm.identity.principalId
output dotPrincipalId string = dot.identity.principalId
output apiPrincipalId string = !empty(imageApi) ? api.identity.principalId : ''
