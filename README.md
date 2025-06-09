# Azure Template Sammlung 🚀

Eine Sammlung von Azure Resource Manager (ARM) Templates und Bicep-Dateien für schnelle Cloud-Deployments mit gebrauchsfertigen Deployment-Scripts.

## 📁 Repository-Struktur

```
azure-templates/
├── bicep-templates/          # Moderne Bicep Templates
│   ├── windows-vm-2025.bicep # Windows VM mit neuesten APIs
│   └── windows-vm-2025.bicepparam # Parameter-Datei für einfache Deployments
├── examples/                 # 🆕 Gebrauchsfertige Deployment-Scripts
│   ├── README.md            # Detaillierte Deployment-Anleitung
│   ├── azure-cli/           # Scripts für Linux/macOS/WSL
│   │   ├── deploy-dev.sh    # Development Environment
│   │   └── deploy-prod.sh   # Production Environment
│   └── powershell/          # Scripts für Windows
│       └── deploy-dev.ps1   # Development Environment  
├── json-templates/           # Klassische ARM Templates (JSON)
│   └── windows-vm-2025.json # JSON-Version für Legacy-Support
└── README.md                # Diese Dokumentation
```

## 🛠️ Verfügbare Templates

### Bicep Templates

| Template | Beschreibung | API Version | Features |
|----------|--------------|-------------|----------|
| `windows-vm-2025.bicep` | Windows Server VM | 2024-11-01 | TrustedLaunch, ConfidentialVM, Premium SSD |
| `windows-vm-2025.bicepparam` | Parameter-Datei | - | Vordefinierte Konfigurationen für verschiedene Umgebungen |

### JSON Templates
| Template | Beschreibung | Kompatibilität |
|----------|--------------|----------------|
| `windows-vm-2025.json` | ARM Template (JSON) | Azure DevOps, GitHub Actions, Jenkins |

### 🆕 Deployment Scripts
| Script | Plattform | Umgebung | VM-Größe | Kosten |
|--------|-----------|----------|----------|---------|
| `examples/azure-cli/deploy-dev.sh` | Linux/macOS | Development | B2s | ~37€/Monat |
| `examples/azure-cli/deploy-prod.sh` | Linux/macOS | Production | D4s_v3 | ~140€/Monat |
| `examples/powershell/deploy-dev.ps1` | Windows | Development | B2s | ~37€/Monat |

## 🚀 Schnellstart

### Option 1: Mit Deployment-Scripts (Empfohlen) ⚡

**Linux/macOS Development:**
```bash
# Repository klonen
git clone https://github.com/Zaza017/azure-templates.git
cd azure-templates

# Script ausführbar machen
chmod +x examples/azure-cli/deploy-dev.sh

# Deployment starten
./examples/azure-cli/deploy-dev.sh
```

**Windows Development:**
```powershell
# Repository klonen
git clone https://github.com/Zaza017/azure-templates.git
cd azure-templates

# PowerShell Script ausführen
.\examples\powershell\deploy-dev.ps1
```

**📚 Detaillierte Anleitung:** Siehe [`examples/README.md`](examples/README.md)

### Option 2: Manuelle Deployment-Befehle

#### Bicep Template deployen

**Voraussetzungen:**
- Azure CLI installiert
- Bicep CLI installiert
- Azure-Anmeldung: `az login`

**Deployment-Befehle:**

```bash
# Resource Group erstellen
az group create --name myResourceGroup --location "West Europe"

# Mit Parameter-Datei (einfach)
az deployment group create \
  --resource-group myResourceGroup \
  --template-file bicep-templates/windows-vm-2025.bicep \
  --parameters @bicep-templates/windows-vm-2025.bicepparam \
  --parameters adminPassword="IhrSicheresPasswort123!"

# Mit direkten Parametern
az deployment group create \
  --resource-group myResourceGroup \
  --template-file bicep-templates/windows-vm-2025.bicep \
  --parameters adminUsername=azureuser \
  --parameters adminPassword="IhrSicheresPasswort123!" \
  --parameters vmName=MyWindowsVM \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters securityType=TrustedLaunch
```

#### JSON Template deployen

```bash
# JSON ARM Template verwenden
az deployment group create \
  --resource-group myResourceGroup \
  --template-file json-templates/windows-vm-2025.json \
  --parameters adminUsername=azureuser \
  --parameters adminPassword="IhrSicheresPasswort123!"
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
- **Standard:** Basis-Sicherheit (günstig)
- **TrustedLaunch:** Erweiterte Sicherheit mit vTPM (empfohlen)
- **ConfidentialVM:** Ultra-sichere VMs für sensible Workloads (teuer)

## 💰 Kosten-Übersicht

### Development Environment
- **VM-Größe:** Standard_B2s (2 vCPUs, 4 GB RAM)
- **Monatliche Kosten:** ~37€ (bei 24/7 Betrieb)
- **Ideal für:** Entwicklung, Testing, Lernen

### Production Environment  
- **VM-Größe:** Standard_D4s_v3 (4 vCPUs, 16 GB RAM)
- **Monatliche Kosten:** ~140€ (bei 24/7 Betrieb)
- **Ideal für:** Produktionsworkloads, kritische Anwendungen

> **💡 Kosten-Tipp:** VMs stoppen wenn nicht genutzt!
> ```bash
> az vm deallocate --resource-group <rg-name> --name <vm-name>
> ```

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

### ConfidentialVM Features (Production):
- ✅ **Hardware-basierte Isolation**
- ✅ **Verschlüsselung zur Laufzeit**
- ✅ **Höchste Sicherheitsstufe**

## 📋 Deployment-Checkliste

- [ ] Azure CLI/PowerShell installiert
- [ ] Bei Azure angemeldet (`az login` / `Connect-AzAccount`)
- [ ] Resource Group erstellt oder geplant
- [ ] Parameter definiert (Username, Password)
- [ ] Template/Script heruntergeladen
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

**Fehler: "Insufficient quota for resource"**
```
Lösung: Azure-Quota erhöhen oder kleinere VM-Größe wählen.
```

**Weitere Troubleshooting-Hilfe:** Siehe [`examples/README.md`](examples/README.md)

## 🔗 Nützliche Links

- [Azure Bicep Dokumentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure VM Größen](https://docs.microsoft.com/azure/virtual-machines/sizes)
- [Azure CLI Installation](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure PowerShell Installation](https://docs.microsoft.com/powershell/azure/install-az-ps)
- [Microsoft Learn - Bicep](https://docs.microsoft.com/learn/paths/bicep-deploy/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

## 🎯 Erweiterte Nutzung

### Verschiedene Umgebungen
```bash
# Development (günstig)
./examples/azure-cli/deploy-dev.sh

# Production (sicher & performant)
./examples/azure-cli/deploy-prod.sh
```

### CI/CD Integration
```yaml
# Azure DevOps Pipeline Beispiel
- task: AzureCLI@2
  inputs:
    azureSubscription: 'Azure-Connection'
    scriptType: 'bash'
    scriptLocation: 'scriptPath'
    scriptPath: 'examples/azure-cli/deploy-dev.sh'
```

### Automatisierung
```bash
# Mehrere VMs parallel deployen
for env in dev test prod; do
  ./examples/azure-cli/deploy-${env}.sh &
done
wait
```

## 📝 Changelog

### v2.0 (Juni 2025) - 🆕 Deployment Scripts
- ✅ **Gebrauchsfertige Scripts** für Linux/macOS/Windows
- ✅ **Development & Production** Umgebungen
- ✅ **Automatische Validierung** und Fehlerbehandlung
- ✅ **Kosten-optimierte** Konfigurationen
- ✅ **Umfassende Dokumentation** mit Troubleshooting

### v1.0 (Juni 2025) - Basis Templates
- ✅ Windows VM Bicep Template mit API 2024-11-01
- ✅ JSON ARM Template für Legacy-Support
- ✅ TrustedLaunch und ConfidentialVM Support
- ✅ Moderne Sicherheitsfeatures
- ✅ Premium SSD Standard
- ✅ Parameter-Datei für Wiederverwendbarkeit

## 🤝 Beitragen

Verbesserungsvorschläge und neue Templates sind willkommen!

1. **Fork** this repository
2. **Create** feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** changes (`git commit -m 'Add AmazingFeature'`)
4. **Push** to branch (`git push origin feature/AmazingFeature`)
5. **Create** Pull Request

### Gewünschte Beiträge:
- **Linux VM Templates** (Ubuntu, CentOS, RHEL)
- **Web App Templates** (App Service, Container Apps)
- **Database Templates** (SQL Server, PostgreSQL)
- **Networking Templates** (VNet, Load Balancer)
- **Weitere Deployment-Scripts** (Terraform, Ansible)

## 📄 Lizenz

Dieses Repository steht unter MIT-Lizenz - siehe LICENSE-Datei für Details.

## 🙋‍♂️ Support

**Bei Fragen oder Problemen:**
- **Issues:** Erstelle ein GitHub Issue
- **Discussions:** Nutze GitHub Discussions für allgemeine Fragen
- **Documentation:** Ausführliche Anleitungen in [`examples/README.md`](examples/README.md)

---

**Erstellt von Zaza017** | **Powered by Azure & Bicep** | **Enterprise-Ready** 🚀
