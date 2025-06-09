# Deployment Examples 🚀

Dieses Verzeichnis enthält gebrauchsfertige Deployment-Scripts für verschiedene Umgebungen und Plattformen.

## 📁 Ordner-Struktur

```
examples/
├── azure-cli/              # Azure CLI Scripts (Linux/macOS/WSL)
│   ├── deploy-dev.sh       # Development Environment
│   └── deploy-prod.sh      # Production Environment
└── powershell/             # PowerShell Scripts (Windows)
    └── deploy-dev.ps1      # Development Environment
```

## 🎯 Welches Script soll ich verwenden?

| Script | Plattform | Umgebung | VM-Größe | Kosten | Sicherheit |
|--------|-----------|----------|----------|---------|------------|
| `azure-cli/deploy-dev.sh` | Linux/macOS | Development | B2s (2 vCPU, 4GB) | Niedrig | Standard |
| `azure-cli/deploy-prod.sh` | Linux/macOS | Production | D4s_v3 (4 vCPU, 16GB) | Hoch | ConfidentialVM |
| `powershell/deploy-dev.ps1` | Windows | Development | B2s (2 vCPU, 4GB) | Niedrig | Standard |

## 🔧 Voraussetzungen

### Für Azure CLI Scripts (Linux/macOS/WSL)
```bash
# Azure CLI installieren
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Anmelden
az login

# Bicep CLI installieren
az bicep install
```

### Für PowerShell Scripts (Windows)
```powershell
# Azure PowerShell installieren
Install-Module -Name Az -Repository PSGallery -Force

# Anmelden
Connect-AzAccount
```

## 🚀 Schnellstart

### 1. Development VM (Linux/macOS)
```bash
# Script ausführbar machen
chmod +x examples/azure-cli/deploy-dev.sh

# Deployment starten
./examples/azure-cli/deploy-dev.sh
```

### 2. Development VM (Windows PowerShell)
```powershell
# Script ausführen
.\examples\powershell\deploy-dev.ps1
```

### 3. Production VM (Linux/macOS)
```bash
# Script ausführbar machen
chmod +x examples/azure-cli/deploy-prod.sh

# Production Deployment (Vorsicht: Hohe Kosten!)
./examples/azure-cli/deploy-prod.sh
```

## ⚙️ Script-Features

### Development Scripts
- ✅ **Kostengünstig:** B2s VM-Größe
- ✅ **Schnell:** Einfache Konfiguration
- ✅ **Automatisch:** Resource Group Creation
- ✅ **Benutzerfreundlich:** Farbiger Output
- ✅ **Sicher:** Passwort-Validierung

### Production Script
- ✅ **Hochsicher:** ConfidentialVM Support
- ✅ **Performance:** D4s_v3 VM-Größe
- ✅ **Berechtigungen:** Erweiterte Validierung
- ✅ **Compliance:** Automatische Tags
- ✅ **Monitoring:** Post-Deployment Anleitung

## 📋 Script-Parameter

Alle Scripts verwenden diese Parameter:

| Parameter | Development | Production | Beschreibung |
|-----------|-------------|------------|--------------|
| VM Size | Standard_B2s | Standard_D4s_v3 | Virtuelle Maschinen-Größe |
| OS Version | Core Edition | Full Edition | Windows Server Edition |
| Security | Standard | ConfidentialVM | Sicherheitslevel |
| IP Type | Dynamic | Static | Public IP Allocation |
| Storage | Standard SSD | Premium SSD | Disk-Performance |

## 🔒 Sicherheits-Hinweise

### Development
- **Passwort:** Mindestens 12 Zeichen
- **Zugang:** RDP über Public IP
- **Sicherheit:** Standard (ausreichend für Dev)

### Production
- **Passwort:** Mindestens 16 Zeichen, komplex
- **Zugang:** RDP über Static IP
- **Sicherheit:** ConfidentialVM (höchste Stufe)
- **Compliance:** Automatische Tags für Audit

## 💰 Kosten-Übersicht

### Development VM (B2s)
- **VM:** ~30€/Monat (bei 24/7 Betrieb)
- **Storage:** ~5€/Monat
- **Network:** ~2€/Monat
- **Total:** ~37€/Monat

### Production VM (D4s_v3)
- **VM:** ~120€/Monat (bei 24/7 Betrieb)
- **Storage:** ~15€/Monat (Premium SSD)
- **Network:** ~5€/Monat
- **Total:** ~140€/Monat

> **💡 Kosten-Tipp:** VMs stoppen wenn nicht genutzt!
> ```bash
> az vm deallocate --resource-group <rg-name> --name <vm-name>
> ```

## 🛠️ Troubleshooting

### Häufige Fehler

#### "Insufficient quota"
```bash
# Quota prüfen
az vm list-usage --location "West Europe" --output table

# Lösung: Andere VM-Größe oder Quota-Erhöhung beantragen
```

#### "ConfidentialVM not supported"
```bash
# Verfügbare VM-Größen prüfen
az vm list-skus --location "West Europe" --size Standard_D4s_v3 --output table

# Lösung: Script wechselt automatisch zu TrustedLaunch
```

#### "Password complexity requirements"
```
Lösung: Passwort muss enthalten:
- Großbuchstaben (A-Z)
- Kleinbuchstaben (a-z)  
- Zahlen (0-9)
- Sonderzeichen (!@#$%^&*)
- Mindestlänge: 12 (Dev) / 16 (Prod) Zeichen
```

#### "Resource already exists"
```bash
# Lösung: Anderen Namen verwenden oder bestehende Ressource löschen
az group delete --name <resource-group-name> --yes
```

## 📚 Weiterführende Links

- [Azure CLI Dokumentation](https://docs.microsoft.com/cli/azure/)
- [Azure PowerShell Dokumentation](https://docs.microsoft.com/powershell/azure/)
- [Bicep Dokumentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure VM Pricing](https://azure.microsoft.com/pricing/details/virtual-machines/)
- [ConfidentialVM Dokumentation](https://docs.microsoft.com/azure/confidential-computing/)

## 🤝 Unterstützung

Bei Problemen:
1. **Logs prüfen:** Scripts zeigen detaillierte Fehlermeldungen
2. **Azure Portal:** Deployment-Status überprüfen
3. **Azure CLI:** `az --debug` für detaillierte Debug-Infos
4. **PowerShell:** `$VerbosePreference = 'Continue'` für Details

---

**Erstellt für azure-templates Repository** | **Optimiert für Entwickler** 🚀
