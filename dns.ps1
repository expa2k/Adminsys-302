Install-WindowsFeature -Name DNS -IncludeManagementTools

$Dominio = "reprobados.com"
$IP = "192.168.0.157"

if(-not (Get-DnsServerZone -Name $Dominio -ErrorAction SilentlyContinue))
{
    Add-DnsServerPrimaryZone -Name $Dominio -ZoneFile "$Dominio.dns"
    Write-Host "Zona DNS '$Dominio' creada exitosamente"
} else {
    Write-Host "Este dominio ya existe"
}

Add-DnsServerResourceRecordA -ZoneName $Dominio -Name "@" -IPv4Address $IP
Write-Host "Registro A para '$Dominio' agregado exitosamente"

Add-DnsServerResourceRecordA -ZoneName $Dominio -Name "www" -IPv4Address $IP
Write-Host "Registro a para 'www.$Dominio' agregado exitosamente"

Set-DnsClientServerAddress -InterfaceIndex 4 -ServerAddresses 192.168.0.157

Restart-Service DNS
Write-Host "Configuracion DNS creada con exito"