# Azure Template Sammlung 🚀

Eine Sammlung von Azure Resource Manager (ARM) Templates und Bicep-Dateien für schnelle Cloud-Deployments.

## 📁 Repository-Struktur

```
json-sammlung/
├── bicep-templates/          # Moderne Bicep Templates
│   └── windows-vm-2025.bicep # Windows VM mit neuesten APIs
├── json-templates/           # Klassische ARM Templates (JSON)
└── README.md                # Diese Dokumentation
```

## 🛠️ Verfügbare Templates

### Bicep Templates

| Template | Beschreibung | API Version | Features |
|----------|--------------|-------------|----------|
| `windows-vm-2025.bicep` | Windows Server VM | 2024-11-01 | TrustedLaunch, ConfidentialVM, Premium SSD |

### JSON Templates
*Coming soon - Klassische ARM Templates*

## 🚀 Deployment-Anleitung

### Bicep Template deployen

#### Voraussetzungen
- Azure CLI installiert
- Bicep CLI installiert
- Azure-Anmeldung: `az login`

#### Deployment-Befehle

```bash
# Resource Group erstellen
az group create --name myResourceGroup --location "West Europe"

# Bicep Template deployen
az deployment group create \
  --resource-group myResourceGroup \
  --template-file bicep-templates/windows-vm-2025.bicep \
  --parameters adminUsername=azureuser \
  --parameters adminPassword="IhrSicheresPasswort123!"
```

#### Parameter-Beispiele

```bash
# Mit benutzerdefinierten Parametern
az deployment group create \
  --resource-group myResourceGroup \
  --template-file bicep-templates/windows-vm-2025.bicep \
  --parameters adminUsername=myadmin \
  --parameters vmName=MyWindowsVM \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters securityType=TrustedLaunch \
  --parameters OSVersion=2022-datacenter-azure-edition
```

## ⚙️ Template-Konfiguration

### Windows VM Template - Parameter

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `adminUsername` | string | - | Benutzername für VM-Admin |
| `adminPassword` | securestring | - | Passwort (min. 12 Zeichen) |
| `vmName` | string | myWindowsVM | Name der virtuellen Maschine |
| `vmSize` | string | Standard_D2s_v3 | VM-Größe |
| `OSVersion` | string | 2022-datacenter-azure-edition | Windows Server Version |
| `securityType` | string | TrustedLaunch | Sicherheitstyp der VM |

### Unterstützte Windows-Versionen
- `2019-datacenter-gensecond`
- `2022-datacenter-azure-edition`
- `2022-datacenter-azure-edition-core`
- `2025-datacenter-azure-edition`

### Sicherheitstypen
- **Standard:** Basis-Sicherheit
- **TrustedLaunch:** Erweiterte Sicherheit mit vTPM
- **ConfidentialVM:** Ultra-sichere VMs für sensible Workloads

## 🔒 Sicherheitsfeatures

### In allen Templates enthalten:
- ✅ **TLS 1.2** Enforcement für Storage
- ✅ **Premium SSD** für bessere Performance
- ✅ **Network Security Groups** mit RDP-Zugang
- ✅ **Boot Diagnostics** aktiviert
- ✅ **Automatische Windows Updates**

### TrustedLaunch Features:
- ✅ **Secure Boot** aktiviert
- ✅ **vTPM** (Virtual Trusted Platform Module)
- ✅ **Guest Attestation** Extension

## 📋 Deployment-Checkliste

- [ ] Azure CLI installiert
- [ ] Resource Group erstellt
- [ ] Parameter definiert (Username, Password)
- [ ] Template heruntergeladen
- [ ] Deployment gestartet
- [ ] VM-Zugang über RDP getestet

## 🆘 Troubleshooting

### Häufige Probleme:

**Fehler: "Password does not meet complexity requirements"**
```
Lösung: Passwort muss mindestens 12 Zeichen haben und Groß-/Kleinbuchstaben, Zahlen und Sonderzeichen enthalten.
```

**Fehler: "VM size not available in region"**
```
Lösung: Andere VM-Größe wählen oder andere Region verwenden.
```

**Fehler: "Bicep CLI not found"**
```
Lösung: Bicep CLI installieren: az bicep install
```

## 🔗 Nützliche Links

- [Azure Bicep Dokumentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure VM Größen](https://docs.microsoft.com/azure/virtual-machines/sizes)
- [Azure CLI Installation](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Microsoft Learn - Bicep](https://docs.microsoft.com/learn/paths/bicep-deploy/)

## 📝 Changelog

### v1.0 (Juni 2025)
- ✅ Windows VM Bicep Template mit API 2024-11-01
- ✅ TrustedLaunch und ConfidentialVM Support
- ✅ Moderne Sicherheitsfeatures
- ✅ Premium SSD Standard

## 🤝 Beitragen

Verbesserungsvorschläge und neue Templates sind willkommen!

1. Fork this repository
2. Create feature branch
3. Commit changes
4. Create Pull Request

## 📄 Lizenz

Dieses Repository steht unter MIT-Lizenz - siehe LICENSE-Datei für Details.

---

**Erstellt von Zaza017** | **Powered by Azure & Bicep** 🚀
