# =======================================================
# Azure VM Deployment Script - DEVELOPMENT Environment
# PowerShell Version für Windows
# =======================================================
# Dieses Script deployt eine kostengünstige VM für Entwicklungszwecke
# 
# Voraussetzungen:
# - Azure PowerShell installiert (Install-Module -Name Az)
# - Angemeldet bei Azure (Connect-AzAccount)
# - PowerShell 5.1 oder höher
#
# Verwendung:
# .\deploy-dev.ps1
# =======================================================

# Farben für bessere Lesbarkeit
function Write-Header {
    param([string]$Message)
    Write-Host "=================================================" -ForegroundColor Blue
    Write-Host " $Message" -ForegroundColor Blue
    Write-Host "=================================================" -ForegroundColor Blue
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# =======================================================
# KONFIGURATION - ENTWICKLUNGSUMGEBUNG
# =======================================================

Write-Header "Azure VM Deployment - Development Environment (PowerShell)"

# Basis-Konfiguration
$ResourceGroupName = "rg-vm-dev-$(Get-Date -Format 'yyyyMMdd')"
$Location = "West Europe"
$VMName = "vm-dev-$env:USERNAME"
$AdminUsername = "azureuser"

# Development-spezifische Einstellungen (kostengünstig)
$VMSize = "Standard_B2s"                                    # 2 vCPUs, 4 GB RAM - günstig
$OSVersion = "2022-datacenter-azure-edition-core"          # Core = günstiger
$SecurityType = "Standard"                                  # Standard Sicherheit für Dev
$PublicIPMethod = "Dynamic"                                 # Dynamic = günstiger

Write-Info "Resource Group: $ResourceGroupName"
Write-Info "Location: $Location"
Write-Info "VM Name: $VMName"
Write-Info "VM Size: $VMSize (Development)"
Write-Info "OS Version: $OSVersion"

# =======================================================
# VORAUSSETZUNGEN PRÜFEN
# =======================================================

Write-Header "Überprüfe Voraussetzungen"

# Azure PowerShell prüfen
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Error "Azure PowerShell ist nicht installiert!"
    Write-Info "Installation: Install-Module -Name Az -Repository PSGallery -Force"
    Write-Info "Dokumentation: https://docs.microsoft.com/powershell/azure/install-az-ps"
    exit 1
}
Write-Success "Azure PowerShell gefunden"

# Azure Login prüfen
try {
    $Context = Get-AzContext
    if (-not $Context) {
        throw "Nicht angemeldet"
    }
    Write-Success "Angemeldet bei Azure: $($Context.Subscription.Name)"
} catch {
    Write-Error "Nicht bei Azure angemeldet!"
    Write-Info "Bitte ausführen: Connect-AzAccount"
    exit 1
}

# PowerShell Version prüfen
$PSVersionRequired = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $PSVersionRequired) {
    Write-Error "PowerShell $PSVersionRequired oder höher erforderlich!"
    Write-Info "Aktuelle Version: $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Success "PowerShell Version: $($PSVersionTable.PSVersion)"

# =======================================================
# PASSWORT EINGABE
# =======================================================

Write-Header "Administrator-Passwort festlegen"

Write-Info "Das Passwort muss mindestens 12 Zeichen haben und Groß-/Kleinbuchstaben, Zahlen und Sonderzeichen enthalten."

do {
    $AdminPassword = Read-Host "Administrator Passwort für VM '$VMName'" -AsSecureString
    $AdminPasswordConfirm = Read-Host "Passwort bestätigen" -AsSecureString
    
    # SecureString zu Plain Text für Vergleich
    $AdminPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
    $AdminPasswordConfirmPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPasswordConfirm))
    
    if ($AdminPasswordPlain -ne $AdminPasswordConfirmPlain) {
        Write-Error "Passwörter stimmen nicht überein!"
        continue
    }
    
    if ($AdminPasswordPlain.Length -lt 12) {
        Write-Error "Passwort muss mindestens 12 Zeichen haben!"
        continue
    }
    
    # Passwort-Komplexität prüfen
    $HasUpper = $AdminPasswordPlain -cmatch '[A-Z]'
    $HasLower = $AdminPasswordPlain -cmatch '[a-z]'
    $HasDigit = $AdminPasswordPlain -match '\d'
    $HasSpecial = $AdminPasswordPlain -match '[^A-Za-z0-9]'
    
    if (-not ($HasUpper -and $HasLower -and $HasDigit -and $HasSpecial)) {
        Write-Error "Passwort muss Groß- und Kleinbuchstaben, Zahlen und Sonderzeichen enthalten!"
        continue
    }
    
    Write-Success "Passwort festgelegt"
    break
    
} while ($true)

# =======================================================
# DEPLOYMENT STARTEN
# =======================================================

Write-Header "Starte Deployment"

try {
    # Resource Group erstellen
    Write-Info "Erstelle Resource Group: $ResourceGroupName"
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    Write-Success "Resource Group erstellt: $($ResourceGroup.ResourceGroupName)"
    
    # Template-Pfad bestimmen
    $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $TemplatePath = Join-Path $ScriptPath "..\..\bicep-templates\windows-vm-2025.bicep"
    
    if (-not (Test-Path $TemplatePath)) {
        Write-Error "Template nicht gefunden: $TemplatePath"
        Write-Info "Stelle sicher, dass du das Script aus dem examples\powershell\ Ordner ausführst"
        exit 1
    }
    
    Write-Info "Template gefunden: $TemplatePath"
    
    # Parameter für Deployment vorbereiten
    $DeploymentParameters = @{
        adminUsername = $AdminUsername
        adminPassword = $AdminPassword
        vmName = $VMName
        vmSize = $VMSize
        OSVersion = $OSVersion
        securityType = $SecurityType
        publicIPAllocationMethod = $PublicIPMethod
        location = $Location
    }
    
    # VM deployen
    Write-Info "Deploye VM: $VMName"
    Write-Info "Dies kann 5-10 Minuten dauern..."
    
    $DeploymentName = "vm-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $Deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -Name $DeploymentName `
        -TemplateFile $TemplatePath `
        -TemplateParameterObject $DeploymentParameters `
        -Verbose
    
    if ($Deployment.ProvisioningState -eq "Succeeded") {
        Write-Success "VM erfolgreich deployed!"
    } else {
        Write-Error "Deployment fehlgeschlagen! Status: $($Deployment.ProvisioningState)"
        exit 1
    }
    
} catch {
    Write-Error "Fehler beim Deployment: $($_.Exception.Message)"
    Write-Info "Überprüfe das Azure Portal für Details"
    exit 1
}

# =======================================================
# DEPLOYMENT-INFORMATIONEN ANZEIGEN
# =======================================================

Write-Header "Deployment-Informationen"

try {
    # VM-Details abrufen
    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    
    # Public IP ermitteln
    $NetworkInterface = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName | Where-Object { $_.VirtualMachine.Id -eq $VM.Id }
    $PublicIPResourceId = $NetworkInterface.IpConfigurations[0].PublicIpAddress.Id
    
    if ($PublicIPResourceId) {
        $PublicIP = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName | Where-Object { $_.Id -eq $PublicIPResourceId }
        $PublicIPAddress = $PublicIP.IpAddress
        $FQDN = $PublicIP.DnsSettings.Fqdn
    } else {
        $PublicIPAddress = "Nicht verfügbar"
        $FQDN = "Nicht verfügbar"
    }
    
    Write-Success "VM Details:"
    Write-Host "  • Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "  • VM Name: $VMName" -ForegroundColor White
    Write-Host "  • Location: $Location" -ForegroundColor White
    Write-Host "  • VM Size: $VMSize" -ForegroundColor White
    Write-Host "  • Admin Username: $AdminUsername" -ForegroundColor White
    Write-Host "  • Public IP: $PublicIPAddress" -ForegroundColor White
    Write-Host "  • FQDN: $FQDN" -ForegroundColor White
    
    Write-Info "RDP-Verbindung:"
    Write-Host "  • Adresse: $PublicIPAddress$(if ($FQDN -ne 'Nicht verfügbar') { " (oder $FQDN)" })" -ForegroundColor White
    Write-Host "  • Port: 3389" -ForegroundColor White
    Write-Host "  • Username: $AdminUsername" -ForegroundColor White
    Write-Host "  • Password: [Das eingegebene Passwort]" -ForegroundColor White
    
    Write-Info "Kosten-Hinweis:"
    Write-Host "  • Development VM mit günstigen Einstellungen" -ForegroundColor White
    Write-Host "  • Vergiss nicht, die VM zu stoppen wenn nicht genutzt!" -ForegroundColor White
    Write-Host "  • Stop: Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force" -ForegroundColor White
    
} catch {
    Write-Error "Fehler beim Abrufen der VM-Details: $($_.Exception.Message)"
}

# =======================================================
# CLEANUP-INFORMATIONEN
# =======================================================

Write-Header "Cleanup-Informationen"

Write-Info "PowerShell Befehle für VM-Management:"
Write-Host ""
Write-Host "# Alle Ressourcen löschen:" -ForegroundColor Cyan
Write-Host "Remove-AzResourceGroup -Name '$ResourceGroupName' -Force -AsJob" -ForegroundColor White
Write-Host ""
Write-Host "# VM stoppen (behält Ressourcen, spart Kosten):" -ForegroundColor Cyan
Write-Host "Stop-AzVM -ResourceGroupName '$ResourceGroupName' -Name '$VMName' -Force" -ForegroundColor White
Write-Host ""
Write-Host "# VM starten:" -ForegroundColor Cyan
Write-Host "Start-AzVM -ResourceGroupName '$ResourceGroupName' -Name '$VMName'" -ForegroundColor White
Write-Host ""
Write-Host "# VM-Status prüfen:" -ForegroundColor Cyan
Write-Host "Get-AzVM -ResourceGroupName '$ResourceGroupName' -Name '$VMName' -Status" -ForegroundColor White

Write-Success "Deployment abgeschlossen! 🎉"
Write-Info "Du kannst jetzt per RDP auf die VM zugreifen."
