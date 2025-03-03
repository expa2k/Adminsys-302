# dns.ps1
function Install-DNS {
    Install-WindowsFeature -Name DNS -IncludeManagementTools
}

function Restart-DNS {
    Restart-Service DNS
}

function Configure-DNS {
    param (
        [string]$Dominio,
        [string]$IP
    )
    if (-not (Get-DnsServerZone -Name $Dominio -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $Dominio -ZoneFile "$Dominio.dns"
        Write-Host "Zona DNS '$Dominio' creada exitosamente"
    } else {
        Write-Host "Este dominio ya existe"
    }
    Add-DnsServerResourceRecordA -ZoneName $Dominio -Name "@" -IPv4Address $IP
    Add-DnsServerResourceRecordA -ZoneName $Dominio -Name "www" -IPv4Address $IP
    Set-DnsClientServerAddress -InterfaceIndex 4 -ServerAddresses $IP
    Restart-DNS
    Write-Host "Configuracion DNS creada con exito"
}

Install-DNS
Configure-DNS -Dominio "reprobados.com" -IP "192.168.0.157"
