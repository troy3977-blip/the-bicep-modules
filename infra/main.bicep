targetScope = 'resourceGroup'

@description('Environment name: dev|prod')
param env string

@description('Azure region for regional resources (Front Door is global)')
param location string = resourceGroup().location

@description('Base name prefix for all resources (keep short)')
param namePrefix string

@description('DNS hostnames you will map to Front Door (optional)')
param customDomains array = []

@description('Container image tags')
param imageTag string = 'latest'

@description('Image names in ACR (repositories)')
param imageRepoWfm string = 'wfm-staffing-app'
param imageRepoDot string = 'dot-strategy'
@description('Optional API repo (FastAPI), set empty to skip API app')
param imageRepoApi string = ''

@description('App Service SKU, e.g. P0v3, B1, S1')
param appServiceSku string = 'P0v3'

@description('Enable SQL/ADLS/ADF layer (can toggle off for minimal runtime)')
param enableDataPlatform bool = true

// Names (consistent, deterministic)
var acrName = toLower('${namePrefix}${env}acr')
var kvName  = toLower('${namePrefix}-${env}-kv')
var lawName = toLower('${namePrefix}-${env}-law')
var aiName  = toLower('${namePrefix}-${env}-appi')
var planName = '${namePrefix}-${env}-asp'

var wfmAppName = '${namePrefix}-${env}-wfm'
var dotAppName = '${namePrefix}-${env}-dot'
var apiAppName = '${namePrefix}-${env}-api'

var storageName = toLower(replace('${namePrefix}${env}adls', '-', ''))
var sqlServerName = toLower('${namePrefix}-${env}-sql')
var sqlDbName = '${namePrefix}-${env}-db'

// 1) Container registry
module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: 'Basic'
  }
}

// 2) Observability (Log Analytics + App Insights)
module appi './modules/appInsights.bicep' = {
  name: 'observability'
  params: {
    location: location
    logAnalyticsName: lawName
    appInsightsName: aiName
  }
}

// 3) Key Vault
module kv './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: kvName
    location: location
    enableRbacAuthorization: true
  }
}

// 4) Optional Data Platform (ADLS + SQL)
module adls './modules/storageAdls.bicep' = if (enableDataPlatform) {
  name: 'adls'
  params: {
    name: storageName
    location: location
  }
}

module sql './modules/sql.bicep' = if (enableDataPlatform) {
  name: 'sql'
  params: {
    location: location
    serverName: sqlServerName
    databaseName: sqlDbName
    // For portfolio: SQL auth OFF by default; use Entra later, or set SQL admin here if needed.
    allowAzureServices: true
  }
}

// 5) App Service Plan + 2 Web Apps (+ optional API)
module apps './modules/appServiceContainers.bicep' = {
  name: 'apps'
  params: {
    location: location
    planName: planName
    sku: appServiceSku

    acrLoginServer: acr.outputs.loginServer
    acrResourceId: acr.outputs.acrId

    appInsightsConnectionString: appi.outputs.connectionString

    wfmAppName: wfmAppName
    dotAppName: dotAppName
    apiAppName: apiAppName

    imageWfm: '${acr.outputs.loginServer}/${imageRepoWfm}:${imageTag}'
    imageDot: '${acr.outputs.loginServer}/${imageRepoDot}:${imageTag}'
    imageApi: empty(imageRepoApi) ? '' : '${acr.outputs.loginServer}/${imageRepoApi}:${imageTag}'

    keyVaultName: kvName

    enableDataPlatform: enableDataPlatform
    sqlServerFqdn: enableDataPlatform ? sql.outputs.serverFqdn : ''
    sqlDbName: enableDataPlatform ? sqlDbName : ''
    storageAccountName: enableDataPlatform ? storageName : ''
  }
  dependsOn: [
    acr
    appi
    kv
  ]
}

// 6) RBAC assignments (Web Apps -> Key Vault secrets, ACR pull)
module rbac './modules/roleAssignments.bicep' = {
  name: 'rbac'
  params: {
    acrId: acr.outputs.acrId
    keyVaultId: kv.outputs.keyVaultId
    wfmPrincipalId: apps.outputs.wfmPrincipalId
    dotPrincipalId: apps.outputs.dotPrincipalId
    apiPrincipalId: apps.outputs.apiPrincipalId
    includeApi: !empty(imageRepoApi)
  }
}

// 7) Front Door (routes /wfm and /dot, and optionally /api)
module fd './modules/frontDoor.bicep' = {
  name: 'frontdoor'
  params: {
    name: '${namePrefix}-${env}-fd'
    customDomains: customDomains

    originHostWfm: apps.outputs.wfmDefaultHostname
    originHostDot: apps.outputs.dotDefaultHostname
    originHostApi: apps.outputs.apiDefaultHostname
    includeApi: !empty(imageRepoApi)
  }
  dependsOn: [
    apps
  ]
}

output frontDoorEndpoint string = fd.outputs.endpointHostname
output wfmUrl string = 'https://${fd.outputs.endpointHostname}/wfm'
output dotUrl string = 'https://${fd.outputs.endpointHostname}/dot'
output apiUrl string = !empty(imageRepoApi) ? 'https://${fd.outputs.endpointHostname}/api' : ''
