#  Observations on ARM (Bicep) Templates # 

## - Azure Deployment Framework ## 
- Go Home [Documentation Home](./index.md)
- Go Next [Naming Standards Bicep](./Naming_Standards_Bicep.md)

### Naming Standards - These are configurable, however built into this project by design.

#### *Azure Resource Group Deployment - Multi-Region/Multi-Tier Hub/Spoke Environments*
<br/>


    Common naming standards/conventions/examples for PREFIX:

```powershell

Install-Module FormatMarkdownTable -Force

Get-AzLocation | ForEach-Object {
    $parts = $_.displayname -split '\s' ;
    $location = $_.location
    # Build the Naming Standard based on the name parts, then prefix with A for Azure
    $NameFormat = $($Parts[0][0] + $Parts[1][0] ) + $(if ($parts[2]) { $parts[2][0] }else { 1 })
    $Prefix = 'A' + $NameFormat

    # override the 3 duplicates, maintain new ones in this lookup as new regions come online
    $manualOverrides = @{
        'brazilsoutheast' = 'BSE'
        'northeurope'     = 'NEU'
        'westeurope'      = 'WEU'
    }
    
    [pscustomobject]@{
        displayname  = $_.displayname; 
        location     = $location; 
        first        = $Parts[0]; 
        second       = $parts[1]; 
        third        = $parts[2]; 
        Name         = $NameFormat
        NameOverRide = $manualOverrides[$location]
        PREFIX       = if ($manualOverrides[$location]) { 'A' + $manualOverrides[$location] } else { $Prefix }
    } 
} | Sort-Object name | 
Format-MarkdownTableTableStyle -Property DisplayName, Location, First, Second, Third, Name, Name, NameOverRide, PREFIX

```

    - Some references in the project templates/docs may still refer to the OLD naming AZE2 and AZC1 (now replaced by AEU2 and ACU1)
        - These will be removed over time.

**Overrides for duplicates in BOLD**

    - 3 Name overrides are currently in place
        - Brazil Southeast    BS1 --> BSE
        - North Europe        NE1 --> NEU
        - West Europe         WE1 --> WEU


|displayname|location|first|second|third|Name|NameOverRide|PREFIX|
|:--|:--|:--|:--|:--|:--|:--|:--|
|Australia Central|australiacentral|Australia|Central||AC1||AAC1|
|Australia Central 2|australiacentral2|Australia|Central|2|AC2||AAC2|
|Australia East|australiaeast|Australia|East||AE1||AAE1|
|Australia Southeast|australiasoutheast|Australia|Southeast||AS1||AAS1|
|Brazil Southeast|brazilsoutheast|Brazil|Southeast||BS1|BSE|ABSE|
|Brazil South|brazilsouth|Brazil|South||BS1||ABS1|
|Canada Central|canadacentral|Canada|Central||CC1||ACC1|
|Canada East|canadaeast|Canada|East||CE1||ACE1|
|Central India|centralindia|Central|India||CI1||ACI1|
|Central US|centralus|Central|US||CU1||ACU1|
|East Asia|eastasia|East|Asia||EA1||AEA1|
|East US|eastus|East|US||EU1||AEU1|
|East US 2|eastus2|East|US|2|EU2||AEU2|
|France Central|francecentral|France|Central||FC1||AFC1|
|France South|francesouth|France|South||FS1||AFS1|
|Germany North|germanynorth|Germany|North||GN1||AGN1|
|Germany West Central|germanywestcentral|Germany|West|Central|GWC||AGWC|
|Japan East|japaneast|Japan|East||JE1||AJE1|
|Jio India Central|jioindiacentral|Jio|India|Central|JIC||AJIC|
|Jio India West|jioindiawest|Jio|India|West|JIW||AJIW|
|Japan West|japanwest|Japan|West||JW1||AJW1|
|Korea Central|koreacentral|Korea|Central||KC1||AKC1|
|Korea South|koreasouth|Korea|South||KS1||AKS1|
|North Central US|northcentralus|North|Central|US|NCU||ANCU|
|North Europe|northeurope|North|Europe||NE1|NEU|ANEU|
|Norway East|norwayeast|Norway|East||NE1||ANE1|
|Norway West|norwaywest|Norway|West||NW1||ANW1|
|Southeast Asia|southeastasia|Southeast|Asia||SA1||ASA1|
|South Africa North|southafricanorth|South|Africa|North|SAN||ASAN|
|South Africa West|southafricawest|South|Africa|West|SAW||ASAW|
|Sweden Central|swedencentral|Sweden|Central||SC1||ASC1|
|South Central US|southcentralus|South|Central|US|SCU||ASCU|
|South India|southindia|South|India||SI1||ASI1|
|Switzerland North|switzerlandnorth|Switzerland|North||SN1||ASN1|
|Switzerland West|switzerlandwest|Switzerland|West||SW1||ASW1|
|UAE Central|uaecentral|UAE|Central||UC1||AUC1|
|UAE North|uaenorth|UAE|North||UN1||AUN1|
|UK South|uksouth|UK|South||US1||AUS1|
|UK West|ukwest|UK|West||UW1||AUW1|
|West Central US|westcentralus|West|Central|US|WCU||AWCU|
|West Europe|westeurope|West|Europe||WE1|WEU|AWEU|
|West India|westindia|West|India||WI1||AWI1|
|West US|westus|West|US||WU1||AWU1|
|West US 2|westus2|West|US|2|WU2||AWU2|
|West US 3|westus3|West|US|3|WU3||AWU3|




---
