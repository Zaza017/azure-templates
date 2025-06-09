#!/bin/bash

# =======================================================
# Azure VM Deployment Script - PRODUCTION Environment
# =======================================================
# Dieses Script deployt eine hochsichere VM für Produktionsumgebungen
# 
# Voraussetzungen:
# - Azure CLI installiert (az --version)
# - Angemeldet bei Azure (az login)
# - Bicep CLI installiert (az bicep install)
# - Produktionsberechtigungen in Azure
#
# Verwendung:
# chmod +x deploy-prod.sh
# ./deploy-prod.sh
# =======================================================

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Funktionen für Output
print_header() {
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}=================================================${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${RED}⚠️  $1${NC}"
}

# =======================================================
# PRODUCTION SAFETY CHECK
# =======================================================

print_header "PRODUCTION DEPLOYMENT - SICHERHEITSCHECK"

print_warning "ACHTUNG: Du deployest eine PRODUKTIONS-VM!"
print_warning "Dies erstellt kostenpflichtige, hochperformante Ressourcen."
echo ""
print_info "Produktions-Features:"
echo "  • Große VM-Größe (Standard_D4s_v3)"
echo "  • ConfidentialVM Sicherheit"
echo "  • Premium SSD Storage"
echo "  • Static Public IP"
echo "  • Windows Server Full Edition"
echo "  • Erweiterte Monitoring"
echo ""

read -p "Sind Sie sicher, dass Sie in PRODUKTION deployen möchten? (Tippen Sie 'PRODUCTION' um fortzufahren): " CONFIRM
if [ "$CONFIRM" != "PRODUCTION" ]; then
    print_info "Deployment abgebrochen. Verwenden Sie deploy-dev.sh für Entwicklung."
    exit 0
fi

# =======================================================
# KONFIGURATION - PRODUKTIONSUMGEBUNG
# =======================================================

print_header "Azure VM Deployment - Production Environment"

# Basis-Konfiguration
RESOURCE_GROUP="rg-vm-prod-$(date +%Y%m%d)"
LOCATION="West Europe"
VM_NAME="vm-prod-$(date +%Y%m%d-%H%M)"
ADMIN_USERNAME="azureproduser"

# Production-spezifische Einstellungen (hochperformant & sicher)
VM_SIZE="Standard_D4s_v3"                     # 4 vCPUs, 16 GB RAM - leistungsstark
OS_VERSION="2022-datacenter-azure-edition"   # Full Edition für Produktion
SECURITY_TYPE="ConfidentialVM"               # Höchste Sicherheit
PUBLIC_IP_METHOD="Static"                    # Static für Produktion
PUBLIC_IP_SKU="Standard"                     # Standard für erweiterte Features

print_info "Resource Group: $RESOURCE_GROUP"
print_info "Location: $LOCATION"
print_info "VM Name: $VM_NAME"
print_info "VM Size: $VM_SIZE (Production)"
print_info "OS Version: $OS_VERSION"
print_info "Security Type: $SECURITY_TYPE"

# =======================================================
# ERWEITERTE VORAUSSETZUNGEN PRÜFEN
# =======================================================

print_header "Überprüfe Production-Voraussetzungen"

# Azure CLI prüfen
if ! command -v az &> /dev/null; then
    print_error "Azure CLI ist nicht installiert!"
    print_info "Installation: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
print_success "Azure CLI gefunden: $(az --version | head -n1)"

# Azure Login prüfen
if ! az account show &> /dev/null; then
    print_error "Nicht bei Azure angemeldet!"
    print_info "Bitte ausführen: az login"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_success "Angemeldet bei Azure: $SUBSCRIPTION_NAME"
print_info "Subscription ID: $SUBSCRIPTION_ID"

# Berechtigungen prüfen
print_info "Prüfe Berechtigungen für Produktions-Deployment..."
ROLE_ASSIGNMENTS=$(az role assignment list --assignee $(az account show --query user.name -o tsv) --scope "/subscriptions/$SUBSCRIPTION_ID" --query "[?roleDefinitionName=='Contributor' || roleDefinitionName=='Owner'].roleDefinitionName" -o tsv)

if [ -z "$ROLE_ASSIGNMENTS" ]; then
    print_warning "Keine Contributor/Owner Berechtigungen gefunden!"
    print_info "Stelle sicher, dass du die nötigen Berechtigungen für Produktions-Deployments hast."
    read -p "Trotzdem fortfahren? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        exit 0
    fi
else
    print_success "Berechtigungen gefunden: $ROLE_ASSIGNMENTS"
fi

# ConfidentialVM Support prüfen
print_info "Prüfe ConfidentialVM Support in Region $LOCATION..."
CONF_VM_SUPPORT=$(az vm list-skus --location "$LOCATION" --size "$VM_SIZE" --query "[?capabilities[?name=='ConfidentialComputingType' && value=='DVM-nisolation']].name" -o tsv)

if [ -z "$CONF_VM_SUPPORT" ]; then
    print_warning "ConfidentialVM nicht unterstützt in $LOCATION für $VM_SIZE"
    print_info "Fallback auf TrustedLaunch..."
    SECURITY_TYPE="TrustedLaunch"
else
    print_success "ConfidentialVM unterstützt"
fi

# Quota prüfen
print_info "Prüfe vCPU Quota..."
USAGE=$(az vm list-usage --location "$LOCATION" --query "[?name.value=='standardDSv3Family'].currentValue" -o tsv)
LIMIT=$(az vm list-usage --location "$LOCATION" --query "[?name.value=='standardDSv3Family'].limit" -o tsv)

if [ ! -z "$USAGE" ] && [ ! -z "$LIMIT" ]; then
    REMAINING=$((LIMIT - USAGE))
    if [ $REMAINING -lt 4 ]; then
        print_warning "Möglicherweise nicht genügend vCPU Quota verfügbar!"
        print_info "Verwendet: $USAGE/$LIMIT vCPUs, benötigt: 4 vCPUs"
    else
        print_success "vCPU Quota ausreichend: $REMAINING verfügbar"
    fi
fi

# Bicep CLI prüfen
if ! az bicep version &> /dev/null; then
    print_info "Bicep CLI wird installiert..."
    az bicep install
fi
print_success "Bicep CLI bereit"

# =======================================================
# PRODUCTION PASSWORT EINGABE
# =======================================================

print_header "Production Administrator-Passwort festlegen"

print_warning "PRODUKTIONS-PASSWORT: Höchste Sicherheitsanforderungen!"
print_info "Das Passwort muss mindestens 16 Zeichen haben und sehr komplex sein."
print_info "Verwenden Sie einen Passwort-Manager für sichere Generierung."

while true; do
    echo -n "Administrator Passwort für PRODUCTION VM '$VM_NAME': "
    read -s ADMIN_PASSWORD
    echo
    echo -n "Passwort bestätigen: "
    read -s ADMIN_PASSWORD_CONFIRM
    echo

    if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
        print_error "Passwörter stimmen nicht überein!"
        continue
    fi

    if [ ${#ADMIN_PASSWORD} -lt 16 ]; then
        print_error "PRODUCTION Passwort muss mindestens 16 Zeichen haben!"
        continue
    fi

    # Erweiterte Passwort-Validierung für Produktion
    if ! echo "$ADMIN_PASSWORD" | grep -q '[A-Z]'; then
        print_error "Passwort muss Großbuchstaben enthalten!"
        continue
    fi

    if ! echo "$ADMIN_PASSWORD" | grep -q '[a-z]'; then
        print_error "Passwort muss Kleinbuchstaben enthalten!"
        continue
    fi

    if ! echo "$ADMIN_PASSWORD" | grep -q '[0-9]'; then
        print_error "Passwort muss Zahlen enthalten!"
        continue
    fi

    if ! echo "$ADMIN_PASSWORD" | grep -q '[^A-Za-z0-9]'; then
        print_error "Passwort muss Sonderzeichen enthalten!"
        continue
    fi

    # Überprüfung auf schwache Muster
    if echo "$ADMIN_PASSWORD" | grep -qi "password\|admin\|user\|prod\|123"; then
        print_error "Passwort enthält schwache Muster (password, admin, etc.)!"
        continue
    fi

    print_success "Production-Passwort akzeptiert"
    break
done

# =======================================================
# PRODUCTION DEPLOYMENT STARTEN
# =======================================================

print_header "Starte Production Deployment"

# Resource Group mit Tags erstellen
print_info "Erstelle Production Resource Group: $RESOURCE_GROUP"
if az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags Environment=Production \
           Purpose="Production VM" \
           Owner="$(whoami)" \
           CostCenter="Production" \
           CreatedDate="$(date +%Y-%m-%d)" \
    --output none; then
    print_success "Resource Group erstellt mit Production-Tags"
else
    print_error "Fehler beim Erstellen der Resource Group"
    exit 1
fi

# Template-Pfad bestimmen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/../../bicep-templates/windows-vm-2025.bicep"

if [ ! -f "$TEMPLATE_PATH" ]; then
    print_error "Template nicht gefunden: $TEMPLATE_PATH"
    print_info "Stelle sicher, dass du das Script aus dem examples/azure-cli/ Ordner ausführst"
    exit 1
fi

print_info "Template gefunden: $TEMPLATE_PATH"

# Deployment mit erweiterten Production-Parametern
print_info "Deploye PRODUCTION VM: $VM_NAME"
print_warning "PRODUCTION DEPLOYMENT - Dies kann 10-15 Minuten dauern..."

if az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_PATH" \
    --parameters adminUsername="$ADMIN_USERNAME" \
    --parameters adminPassword="$ADMIN_PASSWORD" \
    --parameters vmName="$VM_NAME" \
    --parameters vmSize="$VM_SIZE" \
    --parameters OSVersion="$OS_VERSION" \
    --parameters securityType="$SECURITY_TYPE" \
    --parameters publicIPAllocationMethod="$PUBLIC_IP_METHOD" \
    --parameters publicIpSku="$PUBLIC_IP_SKU" \
    --parameters location="$LOCATION" \
    --output table; then
    
    print_success "PRODUCTION VM erfolgreich deployed!"
else
    print_error "PRODUCTION Deployment fehlgeschlagen!"
    print_info "Überprüfe das Azure Portal für Details"
    exit 1
fi

# =======================================================
# PRODUCTION POST-DEPLOYMENT KONFIGURATION
# =======================================================

print_header "Production Post-Deployment Konfiguration"

# Zusätzliche Sicherheits-Tags setzen
print_info "Setze Production-Sicherheits-Tags..."
az resource tag \
    --ids "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/$VM_NAME" \
    --tags SecurityLevel="High" \
           BackupRequired="Yes" \
           MonitoringRequired="Yes" \
           ComplianceRequired="Yes" \
    --operation merge

print_success "Production-Tags gesetzt"

# =======================================================
# PRODUCTION DEPLOYMENT-INFORMATIONEN
# =======================================================

print_header "Production Deployment-Informationen"

# Public IP ermitteln
PUBLIC_IP=$(az vm show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --show-details \
    --query publicIps \
    --output tsv)

# FQDN ermitteln  
FQDN=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "myPublicIP" \
    --query dnsSettings.fqdn \
    --output tsv 2>/dev/null || echo "Nicht verfügbar")

print_success "PRODUCTION VM Details:"
echo "  • Resource Group: $RESOURCE_GROUP"
echo "  • VM Name: $VM_NAME"
echo "  • Location: $LOCATION"
echo "  • VM Size: $VM_SIZE (Production)"
echo "  • Security Type: $SECURITY_TYPE"
echo "  • Admin Username: $ADMIN_USERNAME"
echo "  • Public IP: $PUBLIC_IP (Static)"
echo "  • FQDN: $FQDN"

print_warning "PRODUCTION RDP-Verbindung:"
echo "  • Adresse: $PUBLIC_IP (oder $FQDN)"
echo "  • Port: 3389"
echo "  • Username: $ADMIN_USERNAME"
echo "  • Password: [Ihr Production-Passwort]"

print_info "PRODUCTION Sicherheits-Hinweise:"
echo "  • ConfidentialVM/TrustedLaunch aktiviert"
echo "  • Premium SSD für beste Performance"
echo "  • Static IP für stabile Verbindungen"
echo "  • Backup-Strategie implementieren!"
echo "  • Monitoring konfigurieren!"
echo "  • Update-Strategie festlegen!"

# =======================================================
# PRODUCTION NEXT STEPS
# =======================================================

print_header "Production Next Steps"

print_warning "WICHTIGE PRODUCTION SCHRITTE:"
echo ""
echo "1. BACKUP KONFIGURIEREN:"
echo "   az backup protection enable-for-vm \\"
echo "     --resource-group $RESOURCE_GROUP \\"
echo "     --vm $VM_NAME \\"
echo "     --vault-name <backup-vault-name> \\"
echo "     --policy-name <backup-policy>"
echo ""
echo "2. MONITORING AKTIVIEREN:"
echo "   - Azure Monitor für VM aktivieren"
echo "   - Log Analytics Workspace verbinden"
echo "   - Custom Alerts konfigurieren"
echo ""
echo "3. SICHERHEIT VERSTÄRKEN:"
echo "   - Network Security Group Rules anpassen"
echo "   - Azure Security Center aktivieren"
echo "   - Just-In-Time Access konfigurieren"
echo ""
echo "4. COMPLIANCE:"
echo "   - Azure Policy anwenden"
echo "   - Compliance Dashboard überprüfen"
echo "   - Audit Logs aktivieren"

print_info "Management-Befehle:"
echo "  • Stop (spart Kosten): az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_NAME"
echo "  • Start: az vm start --resource-group $RESOURCE_GROUP --name $VM_NAME"
echo "  • Löschen: az group delete --name $RESOURCE_GROUP --yes --no-wait"

print_success "PRODUCTION Deployment abgeschlossen! 🎉"
print_warning "Vergessen Sie nicht die Post-Deployment Sicherheitskonfiguration!"
