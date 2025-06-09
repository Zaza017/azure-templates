// Parameter-Datei für Windows VM Template
// Verwendung: az deployment group create --template-file windows-vm-2025.bicep --parameters @windows-vm-2025.bicepparam

using './windows-vm-2025.bicep'

// === GRUNDLEGENDE PARAMETER ===
// WICHTIG: Passe diese Werte an deine Anforderungen an!

// VM-Administrator Zugangsdaten
param adminUsername = 'azureuser'
// HINWEIS: adminPassword muss beim Deployment über Kommandozeile gesetzt werden
// Beispiel: --parameters adminPassword="IhrSicheresPasswort123!"

// VM-Konfiguration
param vmName = 'MyWindowsVM2025'
param vmSize = 'Standard_D2s_v3'          // 2 vCPUs, 8 GB RAM - gut für Tests
param location = 'West Europe'             // Oder deine bevorzugte Region

// Netzwerk-Konfiguration
param publicIpName = 'MyWindowsVM-PublicIP'
param publicIPAllocationMethod = 'Static'   // Static für permanente IP
param publicIpSku = 'Standard'             // Standard für bessere Features

// === WINDOWS & SICHERHEIT ===
param OSVersion = '2022-datacenter-azure-edition'  // Neueste Windows Server Version
param securityType = 'TrustedLaunch'               // Empfohlene Sicherheit

// DNS-Konfiguration (wird automatisch generiert, kann aber überschrieben werden)
// param dnsLabelPrefix = 'myvm-eindeutig-123'     // Entkommentieren für custom DNS

// === VERSCHIEDENE DEPLOYMENT-SZENARIEN ===

// Für ENTWICKLUNG (Klein & Günstig):
// param vmSize = 'Standard_B2s'              // 2 vCPUs, 4 GB RAM
// param OSVersion = '2022-datacenter-azure-edition-core'  // Core = günstiger
// param securityType = 'Standard'            // Standard Sicherheit

// Für PRODUKTION (Groß & Sicher):
// param vmSize = 'Standard_D4s_v3'           // 4 vCPUs, 16 GB RAM
// param securityType = 'ConfidentialVM'      // Höchste Sicherheit
// param publicIPAllocationMethod = 'Static'  // Feste IP für Produktion

// Für TESTING (Mittel):
// param vmSize = 'Standard_D2s_v3'           // Standard-Größe
// param securityType = 'TrustedLaunch'       // Gute Sicherheit
