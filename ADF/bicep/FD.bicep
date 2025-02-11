param Prefix string

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
#disable-next-line no-unused-params
param Extensions object
param Global object
param DeploymentInfo object



var Deployment = '${Prefix}-${Global.OrgName}-${Global.Appname}-${Environment}${DeploymentID}'
var DeploymentURI = toLower('${Prefix}${Global.OrgName}${Global.Appname}${Environment}${DeploymentID}')

var regionLookup = json(loadTextContent('./global/region.json'))
var primaryPrefix = regionLookup[Global.PrimaryLocation].prefix

var GlobalRGJ = json(Global.GlobalRG)

var gh = {
  globalRGPrefix: contains(GlobalRGJ, 'Prefix') ? GlobalRGJ.Prefix : primaryPrefix
  globalRGOrgName: contains(GlobalRGJ, 'OrgName') ? GlobalRGJ.OrgName : Global.OrgName
  globalRGAppName: contains(GlobalRGJ, 'AppName') ? GlobalRGJ.AppName : Global.AppName
  globalRGName: contains(GlobalRGJ, 'name') ? GlobalRGJ.name : '${Environment}${DeploymentID}'
}

var globalRGName = '${gh.globalRGPrefix}-${gh.globalRGOrgName}-${gh.globalRGAppName}-RG-${gh.globalRGName}'

resource OMS 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${DeploymentURI}LogAnalytics'
}

var frontDoorInfo = contains(DeploymentInfo, 'frontDoorInfo') ? DeploymentInfo.frontDoorInfo : []

var frontDoor = [for i in range(0, length(frontDoorInfo)): {
  match: ((Global.CN == '.') || contains(array(Global.CN), DeploymentInfo.fd.Name))
}]

module FD 'FD-frontDoor.bicep'= [for (fd,index) in frontDoorInfo: if (frontDoor[index].match) {
  name: 'dp${Deployment}-FD-Deploy${fd.name}'
  params: {
    Deployment: Deployment
    DeploymentURI: DeploymentURI
    globalRGName: globalRGName
    frontDoorInfo: fd
    Global: Global
    DeploymentID: DeploymentID
    Environment: Environment
    Prefix: Prefix
  }
}]
