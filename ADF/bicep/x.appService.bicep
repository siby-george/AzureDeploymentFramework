param ws object
param appprefix string
param Deployment string
param DeploymentURI string
param diagLogs array
param linuxFxVersion string = ''
param Global object
param globalRGName string
param Prefix string
param Environment string
param DeploymentID string

var MSILookup = {
  SQL: 'Cluster'
  UTL: 'DefaultKeyVault'
  FIL: 'Cluster'
  OCR: 'Storage'
  PS01: 'VMOperator'
}

var HubRGJ = json(Global.hubRG)

var gh = {
  hubRGPrefix: contains(HubRGJ, 'Prefix') ? HubRGJ.Prefix : Prefix
  hubRGOrgName: contains(HubRGJ, 'OrgName') ? HubRGJ.OrgName : Global.OrgName
  hubRGAppName: contains(HubRGJ, 'AppName') ? HubRGJ.AppName : Global.AppName
  hubRGRGName: contains(HubRGJ, 'name') ? HubRGJ.name : contains(HubRGJ, 'name') ? HubRGJ.name : '${Environment}${DeploymentID}'
}

var HubRGName = '${gh.hubRGPrefix}-${gh.hubRGOrgName}-${gh.hubRGAppName}-RG-${gh.hubRGRGName}'

resource OMS 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${DeploymentURI}LogAnalytics'
}

var userAssignedIdentities = {
  Default: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', '${Deployment}-uaiStorageAccountOperator')}': {}
  }
  VMOperator: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', '${Deployment}-uaiVMOperator')}': {}
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', '${Deployment}-uaiKeyVaultSecretsGetApp')}': {}
  }
}

resource SA 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: '${DeploymentURI}sa${ws.saname}'
}

module WebSiteDNS 'x.DNS.CNAME.bicep' = if (contains(ws, 'customDNS') && bool(ws.customDNS)) {
  name: 'setdns-public-${Deployment}-${appprefix}${ws.Name}-${Global.DomainNameExt}'
  scope: resourceGroup((contains(Global, 'DomainNameExtSubscriptionID') ? Global.DomainNameExtSubscriptionID : subscription().subscriptionId), (contains(Global, 'DomainNameExtRG') ? Global.DomainNameExtRG : globalRGName))
  params: {
    hostname: toLower('${Deployment}-${appprefix}${ws.Name}')
    cname: '${Deployment}-${appprefix}${ws.Name}.azurewebsites.net'
    Global: Global
  }
}

resource FARM 'Microsoft.Web/serverfarms@2021-02-01' existing = {
  name: '${Deployment}-asp${ws.AppSVCPlan}'
}

resource WS 'Microsoft.Web/sites@2021-01-01' = {
  name: '${Deployment}-${appprefix}${ws.Name}'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: (contains(MSILookup, ws.NAME) ? userAssignedIdentities[MSILookup[ws.NAME]] : userAssignedIdentities.Default)
  }
  kind: ws.kind
  location: resourceGroup().location
  properties: {
    enabled: true
    httpsOnly: true
    serverFarmId: FARM.id
    siteConfig: {
      // az webapp list-runtimes, this setting is linux only
      linuxFxVersion: empty(linuxFxVersion) ? null : linuxFxVersion
    }
  }
  dependsOn: [
    WebSiteDNS
  ]
}

module wsBinding 'x.appServiceBinding.bicep' = if (contains(ws, 'initialDeploy') && bool(ws.initialDeploy) && contains(ws, 'customDNS') && bool(ws.customDNS)) {
  name: 'dp-binding-${ws.name}'
  params: {
    externalDNS: Global.DomainNameExt
    siteName: WS.name
    sslState: 'Disabled'
  }
}

resource certificates 'Microsoft.Web/certificates@2021-02-01' = if (contains(ws, 'customDNS') && bool(ws.customDNS)) {
  name: toLower('${WS.name}.${Global.DomainNameExt}')
  location: resourceGroup().location
  properties: {
    canonicalName: toLower('${WS.name}.${Global.DomainNameExt}')
    serverFarmId: resourceId('Microsoft.Web/serverfarms', '${Deployment}-asp${ws.AppSVCPlan}')
  }
  dependsOn: [
    wsBinding
  ]
}

module wsBindingSNI 'x.appServiceBinding.bicep' = if (contains(ws, 'customDNS') && bool(ws.customDNS)) {
  name: 'dp-binding-sni-${ws.name}'
  params: {
    externalDNS: Global.DomainNameExt
    siteName: WS.name
    sslState: 'SniEnabled'
    thumbprint: certificates.properties.thumbprint
  }
}

// resource extDNSBinding 'Microsoft.Web/sites/hostNameBindings@2021-02-01' = if (contains(ws,'customDNS') && bool(ws.customDNS)) {
//   name: toLower('${WS.name}.${Global.DomainNameExt}')
//   parent: WS
//   properties: {
//     siteName: WS.name
//     hostNameType: 'Verified'
//     sslState: 'SniEnabled'
//     customHostNameDnsRecordType: 'CName'
//     thumbprint: certificates.properties.thumbprint
//   }
// }

// Create File share used for Function WEBSITE_CONTENTSHARE
module SAFileShares 'x.storageFileShare.bicep' = {
  name: 'dp${Deployment}-SA-${ws.saname}-FileShare-${replace(toLower('${WS.name}'), '-', '')}'
  params: {
    SAName: SA.name
    fileShare: {
      name: replace(toLower('${WS.name}'), '-', '')
      quota: 5120
    }
    Global: Global
    deployment: Deployment
  }
}

resource WSDiags 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'service'
  scope: WS
  properties: {
    workspaceId: OMS.id
    logs: diagLogs
    metrics: [
      {
        timeGrain: 'PT5M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

resource WSVirtualNetwork 'Microsoft.Web/sites/config@2021-01-15' = if (contains(ws, 'subnet')) {
  name: '${WS.name}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', '${Deployment}-vn', ws.subnet)
    swiftSupported: true
  }
}

resource WSWebConfig 'Microsoft.Web/sites/config@2021-01-01' = if (contains(ws, 'preWarmedCount')) {
  name: 'web'
  parent: WS
  properties: {
    preWarmedInstanceCount: ws.preWarmedCount
  }
}

module vnetPrivateLink 'x.vNetPrivateLink.bicep' = if (contains(ws, 'privatelinkinfo')) {
  name: 'dp${Deployment}-privatelinkloop${ws.name}'
  params: {
    Deployment: Deployment
    PrivateLinkInfo: ws.privateLinkInfo
    providerType: 'Microsoft.Web/sites'
    resourceName: WS.name
  }
}

module webprivateLinkDNS 'x.vNetprivateLinkDNS.bicep' = if (contains(ws, 'privatelinkinfo')) {
  name: 'dp${Deployment}-registerPrivateDNS${ws.name}'
  scope: resourceGroup(HubRGName)
  params: {
    PrivateLinkInfo: ws.privateLinkInfo
    providerURL: '.net/'
    resourceName: WS.name
    Nics: contains(ws, 'privatelinkinfo') ? array(vnetPrivateLink.outputs.NICID) : array('na')
  }
}

output WebSite object = WS
