using './main.bicep'

param env = 'dev'
param location = 'eastus'
param namePrefix = 'troywfm'
param appServiceSku = 'P0v3'

param imageTag = 'dev'
param imageRepoWfm = 'wfm-staffing-app'
param imageRepoDot = 'dot-strategy'
param imageRepoApi = '' // set to 'wfm-api' later if you add it

param enableDataPlatform = true
param customDomains = []
