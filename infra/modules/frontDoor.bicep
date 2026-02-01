targetScope = 'resourceGroup'

param name string
param customDomains array

param originHostWfm string
param originHostDot string
param originHostApi string
param includeApi bool

// Front Door profile (Standard_AzureFrontDoor)
resource profile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: name
  location: 'global'
  sku: { name: 'Standard_AzureFrontDoor' }
  properties: {}
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  name: '${profile.name}/endpoint'
  properties: { enabledState: 'Enabled' }
}

// Origin groups
resource ogWfm 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  name: '${profile.name}/og-wfm'
  properties: {
    healthProbeSettings: { probePath: '/', probeRequestType: 'GET', probeProtocol: 'Https', probeIntervalInSeconds: 60 }
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
  }
}

resource ogDot 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  name: '${profile.name}/og-dot'
  properties: {
    healthProbeSettings: { probePath: '/', probeRequestType: 'GET', probeProtocol: 'Https', probeIntervalInSeconds: 60 }
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
  }
}

resource ogApi 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = if (includeApi) {
  name: '${profile.name}/og-api'
  properties: {
    healthProbeSettings: { probePath: '/health', probeRequestType: 'GET', probeProtocol: 'Https', probeIntervalInSeconds: 60 }
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
  }
}

// Origins (App Service default hostnames)
resource oWfm 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  name: '${profile.name}/og-wfm/o-wfm'
  properties: {
    hostName: originHostWfm
    httpPort: 80
    httpsPort: 443
    originHostHeader: originHostWfm
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource oDot 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  name: '${profile.name}/og-dot/o-dot'
  properties: {
    hostName: originHostDot
    httpPort: 80
    httpsPort: 443
    originHostHeader: originHostDot
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource oApi 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = if (includeApi) {
  name: '${profile.name}/og-api/o-api'
  properties: {
    hostName: originHostApi
    httpPort: 80
    httpsPort: 443
    originHostHeader: originHostApi
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Routes (path-based)
resource routeWfm 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  name: '${profile.name}/endpoint/route-wfm'
  properties: {
    originGroup: { id: ogWfm.id }
    supportedProtocols: [ 'Https' ]
    patternsToMatch: [ '/wfm/*' ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

resource routeDot 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  name: '${profile.name}/endpoint/route-dot'
  properties: {
    originGroup: { id: ogDot.id }
    supportedProtocols: [ 'Https' ]
    patternsToMatch: [ '/dot/*' ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

resource routeApi 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = if (includeApi) {
  name: '${profile.name}/endpoint/route-api'
  properties: {
    originGroup: { id: ogApi.id }
    supportedProtocols: [ 'Https' ]
    patternsToMatch: [ '/api/*' ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

output endpointHostname string = endpoint.properties.hostName
