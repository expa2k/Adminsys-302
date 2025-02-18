# Verificar si el script tiene privilegios de administrador
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $principal.IsInRole($adminRole)) {
    Write-Host "Este script necesita permisos de administrador. Reiniciando como administrador..."
    Start-Process PowerShell -ArgumentList ("-File `"$PSCommandPath`"") -Verb RunAs
    exit
}

# Instalar DHCP si no está instalado
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Solicitar datos al usuario
$ScopeID = Read-Host "Ingrese la red (ej. 192.168.1.0)"
$StartRange = Read-Host "Ingrese la IP inicial (ej. 192.168.1.100)"
$EndRange = Read-Host "Ingrese la IP final (ej. 192.168.1.200)"

# Convertir entradas a direcciones IP válidas
try {
    $StartRange = [System.Net.IPAddress]::Parse($StartRange)
    $EndRange = [System.Net.IPAddress]::Parse($EndRange)
} catch {
    Write-Host "Error: Ingresaste una dirección IP inválida. Verifica los valores e intenta de nuevo." -ForegroundColor Red
    exit
}

# Iniciar servicio DHCP
Start-Service DHCPServer

# Si el servidor está en un dominio, intentar agregarlo a Active Directory
try {
    if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain) {
        Add-DhcpServerInDC
    } else {
        Write-Host "El servidor no está en un dominio, omitiendo autorización en Active Directory."
    }
} catch {
    Write-Host "Advertencia: No se pudo autorizar el servidor en AD. Verifica si tienes permisos de administrador." -ForegroundColor Yellow
}

# Crear el ámbito DHCP
try {
    Add-DhcpServerv4Scope -Name "RedLocal" -StartRange $StartRange -EndRange $EndRange `
    -SubnetMask "255.255.255.0" -State Active
    Write-Host "Servidor DHCP configurado correctamente." -ForegroundColor Green
} catch {
    Write-Host "Error al crear el ámbito DHCP: $_" -ForegroundColor Red
}
