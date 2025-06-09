@description('Benutzername für die Virtual Machine')
param adminUsername string

@description('Passwort für die Virtual Machine')
@minLength(12)
@secure()
param adminPassword string

@description('Name der Virtual Machine')
param vmName string = 'myWindowsVM'

@description('Eindeutiger DNS-Name für die öffentliche IP')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Name für die öffentliche IP')
param publicIpName string = 'myPublicIP'

@description('Zuweisungsmethode für die öffentliche IP')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU für die öffentliche IP')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Standard'

@description('Windows-Version für die VM')
@allowed([
  '2019-datacenter-gensecond'
  '2022-datacenter-azure-edition'
  '2022-datacenter-azure-edition-core'
  '2025-datacenter-azure-edition'
])
param OSVersion string = '2022-datacenter-azure-edition'

@description('Größe der Virtual Machine')
param vmSize string = 'Standard_D2s_v3'

@description('Standort für alle Ressourcen')
param location string = resourceGroup().location

@description('Sicherheitstyp der Virtual Machine')
@allowed([
  'Standard'
  'TrustedLaunch'
  'ConfidentialVM'
])
param securityType string = 'TrustedLaunch'

// Variables - moderne Naming Convention
var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = '${vmName}-nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'default-subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${vmName}-vnet'
var networkSecurityGroupName = '${vmName}-nsg'

// Security Profile für TrustedLaunch/ConfidentialVM
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

// Extensions für moderne Sicherheit
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'

// ===== RESSOURCEN mit neuesten API-Versionen =====

// Storage Account - API 2023-05-01
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Public IP - API 2024-05-01
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

// Network Security Group - API 2024-05-01
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network - API 2024-05-01
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
    // Neue Security Features
    enableDdosProtection: false
    enableVmProtection: false
  }
}

// Network Interface - API 2024-05-01
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Virtual Machine - API 2024-11-01 (NEUESTE!)
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 127
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    // Moderne Security Features
    securityProfile: (securityType == 'TrustedLaunch' || securityType == 'ConfidentialVM') ? securityProfileJson : null
  }
}

// Guest Attestation Extension für TrustedLaunch - API 2024-11-01
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = if (securityType == 'TrustedLaunch') {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

// ===== OUTPUTS =====
output adminUsername string = adminUsername
output hostname string = publicIp.properties.dnsSettings.fqdn
output vmName string = vmName
output securityType string = securityType
