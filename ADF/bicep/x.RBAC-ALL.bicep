param resourceId string
param Global object
param roleInfo object
param principalType string = ''
param Type string
param deployment string

var objectIdLookup = json(Global.objectIdLookup)
var rolesGroupsLookup = json(Global.RolesGroupsLookup)

resource UAI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
    name: '${deployment}-uai${roleInfo.name}'
}

var roleAssignment = [for (rbac,index) in roleInfo.RBAC: {
    RoleName: rbac.Name
    RoleID: rolesGroupsLookup[rbac.Name].Id
    principalType: principalType
    GUID: guid(roleInfo.Name, rbac.Name, resourceId)
    FriendlyName: 'user: ${roleInfo.Name} --> roleInfoName: ${rbac.Name} --> resourceId: ${resourceId}'
}]

module RBACRAResource 'x.RBAC-ALL-RA-Resource.bicep' = [for (rbac, index) in roleAssignment: {
    name: replace('dp-rbac-all-ra-${roleInfo.name}-${index}', '@', '_')
    params: {
        resourceId: resourceId
        description: roleInfo.name
        roledescription: rbac.RoleName
        name: rbac.GUID
        roleDefinitionId: rbac.RoleID
        principalId: Type == 'lookup' ? objectIdLookup[roleInfo.name] : UAI.properties.principalId
        principalType: rbac.principalType
    }
}]

output RoleAssignments array = roleAssignment
