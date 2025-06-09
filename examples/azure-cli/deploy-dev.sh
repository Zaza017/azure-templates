#!/bin/bash

# =======================================================
# Azure VM Deployment Script - DEVELOPMENT Environment
# =======================================================
# Dieses Script deployt eine kostengünstige VM für Entwicklungszwecke
# 
# Voraussetzungen:
# - Azure CLI installiert (az --version)
# - Angemeldet bei Azure (az login)
# - Bicep CLI installiert (az bicep install)
#
# Verwendung:
# chmod +x deploy-dev.sh
# ./deploy-dev.sh
# =======================================================

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktionen für Output
print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}=================================================${NC}"
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

# =======================================================
# KONFIGURATION - ENTWICKLUNGSUMGEBUNG
# =======================================================

print_header "Azure VM Deployment - Development Environment"

# Basis-Konfiguration
RESOURCE_GROUP="rg-vm-dev-$(date +%Y%m%d)"
LOCATION="West Europe"
VM_NAME="vm-dev-$(whoami)"
ADMIN_USERNAME="azureuser"

# Development-spezifische Einstellungen (kostengünstig)
VM_SIZE="Standard_B2s"                    # 2 vCPUs, 4 GB RAM - günstig
OS_VERSION="2022-datacenter-azure-edition-core"  # Core = günstiger
SECURITY_TYPE="Standard"                  # Standard Sicherheit für Dev
PUBLIC_IP_METHOD="Dynamic"                # Dynamic = günstiger

print_info "Resource Group: $RESOURCE_GROUP"
print_info "Location: $LOCATION"
print_info "VM Name: $VM_NAME"
print_info "VM Size: $VM_SIZE (Development)"
print_info "OS Version: $OS_VERSION"

# =======================================================
# VORAUSSETZUNGEN PRÜFEN
# =======================================================

print_header "Überprüfe Voraussetzungen"

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
print_success "Angemeldet bei Azure: $SUBSCRIPTION_NAME"

# Bicep CLI prüfen
if ! az bicep version &> /dev/null; then
    print_info "Bicep CLI wird installiert..."
    az bicep install
fi
print_success "Bicep CLI bereit"

# =======================================================
# PASSWORT EINGABE
# =======================================================

print_header "Administrator-Passwort festlegen"

print_info "Das Passwort muss mindestens 12 Zeichen haben und Groß-/Kleinbuchstaben, Zahlen und Sonderzeichen enthalten."
echo -n "Administrator Passwort für VM '$VM_NAME': "
read -s ADMIN_PASSWORD
echo
echo -n "Passwort bestätigen: "
read -s ADMIN_PASSWORD_CONFIRM
echo

if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    print_error "Passwörter stimmen nicht überein!"
    exit 1
fi

if [ ${#ADMIN_PASSWORD} -lt 12 ]; then
    print_error "Passwort muss mindestens 12 Zeichen haben!"
    exit 1
fi

print_success "Passwort festgelegt"

# =======================================================
# DEPLOYMENT STARTEN
# =======================================================

print_header "Starte Deployment"

# Resource Group erstellen
print_info "Erstelle Resource Group: $RESOURCE_GROUP"
if az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none; then
    print_success "Resource Group erstellt"
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

# VM deployen
print_info "Deploye VM: $VM_NAME"
print_info "Dies kann 5-10 Minuten dauern..."

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
    --parameters location="$LOCATION" \
    --output table; then
    
    print_success "VM erfolgreich deployed!"
else
    print_error "Deployment fehlgeschlagen!"
    print_info "Überprüfe die Azure Portal für Details"
    exit 1
fi

# =======================================================
# DEPLOYMENT-INFORMATIONEN ANZEIGEN
# =======================================================

print_header "Deployment-Informationen"

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

print_success "VM Details:"
echo "  • Resource Group: $RESOURCE_GROUP"
echo "  • VM Name: $VM_NAME"
echo "  • Location: $LOCATION"
echo "  • VM Size: $VM_SIZE"
echo "  • Admin Username: $ADMIN_USERNAME"
echo "  • Public IP: $PUBLIC_IP"
echo "  • FQDN: $FQDN"

print_info "RDP-Verbindung:"
echo "  • Adresse: $PUBLIC_IP (oder $FQDN)"
echo "  • Port: 3389"
echo "  • Username: $ADMIN_USERNAME"
echo "  • Password: [Das eingegebene Passwort]"

print_info "Kosten-Hinweis:"
echo "  • Development VM mit günstigen Einstellungen"
echo "  • Vergiss nicht, die VM zu stoppen wenn nicht genutzt!"
echo "  • Stop: az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_NAME"

# =======================================================
# CLEANUP-INFORMATIONEN
# =======================================================

print_header "Cleanup-Informationen"

print_info "Zum Löschen aller Ressourcen:"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"

print_info "Zum Stoppen der VM (behält Ressourcen):"
echo "  az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_NAME"

print_info "Zum Starten der VM:"
echo "  az vm start --resource-group $RESOURCE_GROUP --name $VM_NAME"

print_success "Deployment abgeschlossen! 🎉"
