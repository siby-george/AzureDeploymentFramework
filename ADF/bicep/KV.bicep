@allowed([
  'AZE2'
  'AZC1'
  'AEU2'
  'ACU1'
])
param Prefix string = 'AZE2'

@allowed([
  'I'
  'D'
  'T'
  'U'
  'P'
  'S'
  'G'
  'A'
])
param Environment string = 'D'

@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
])
param DeploymentID string = '1'
param Stage object
param Extensions object
param Global object
param DeploymentInfo object

@secure()
param vmAdminPassword string

@secure()
param devOpsPat string

@secure()
param sshPublic string

var Deployment = '${Prefix}-${Global.OrgName}-${Global.Appname}-${Environment}${DeploymentID}'
var OMSworkspaceName = replace('${Deployment}LogAnalytics', '-', '')
var OMSworkspaceID = resourceId('Microsoft.OperationalInsights/workspaces/', OMSworkspaceName)
var hubRG = Global.hubRGName

var KeyVaultInfo = (contains(DeploymentInfo, 'KVInfo') ? DeploymentInfo.KVInfo : [])

var KVInfo = [for i in range(0, length(KeyVaultInfo)): {
  match: ((Global.CN == '.') || contains(Global.CN, DeploymentInfo.KVInfo[i].name))
}]

//  Role assignments all in subscription deployment, not on KV deployment.
// resource KVUAI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = [for (kv, index) in KeyVaultInfo: if (length(KeyVaultInfo) == 0 && KVInfo[index].match && contains(kv, 'UserAssignedIdentity')) {
//   name: '${Deployment}-uai${(contains(kv, 'UserAssignedIdentity') ? kv.UserAssignedIdentity.name : 'na')}'
//   location: resourceGroup().location
// }]

module KeyVaults 'KV-KeyVault.bicep' = [for (kv, index) in KeyVaultInfo: if (KVInfo[index].match) {
  name: 'dp${Deployment}-kvDeploy${((length(KeyVaultInfo) == 0) ? 'na' : kv.name)}'
  params: {
    Deployment: Deployment
    DeploymentID: DeploymentID
    Environment: Environment
    KVInfo: kv
    Global: Global
    OMSworkspaceID: OMSworkspaceID
  }
}]

module KVPrivateLink 'vNetPrivateLink.bicep' = [for (kv, index) in KeyVaultInfo: if (KVInfo[index].match) {
  name: 'dp${Deployment}-privatelinkloop${((length(KeyVaultInfo) == 0) ? 'na' : kv.name)}'
  params: {
    Deployment: Deployment
    PrivateLinkInfo: kv.privateLinkInfo
    providerType: 'Microsoft.KeyVault/vaults'
    resourceName: '${Deployment}-kv${((length(KeyVaultInfo) == 0) ? 'na' : kv.name)}'
  }
}]

module KVPrivateLinkDNS 'privateLinkDNS.bicep' = [for (kv, index) in KeyVaultInfo: if (KVInfo[index].match) {
  name: 'dp${Deployment}-registerPrivateDNS${((length(KeyVaultInfo) == 0) ? 'na' : kv.name)}'
  scope: resourceGroup(hubRG)
  params: {
    PrivateLinkInfo: kv.privateLinkInfo
    providerURL: '.azure.net/'
    resourceName: '${Deployment}-kv${((length(KeyVaultInfo) == 0) ? 'na' : kv.name)}'
    Nics: (contains(kv, 'privatelinkinfo') && length(KeyVaultInfo) != 0 ? reference(resourceId('Microsoft.Resources/deployments', 'dp${Deployment}-privatelinkloop${kv.name}'), '2018-05-01').outputs.NICID.value : 'na')
  }
}]
