
# Instalación y configuración básica de Active Directory
# Se van a crear dos UO (Cuates | No cuates) y 
# un usuario en cada una
# Un dominio con dos equipos (Linux | Windows)
Import-Module ".\WS.psm1" -Force


# Instalar el rol de Active Directory Domain Services
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Importar el módulo de AD
Import-Module ADDSDeployment

# Configurar el nuevo dominio
$Dominio = "jorge.com"  # Cambia esto si quieres otro nombre de dominio
Install-ADDSForest `
    -DomainName $Dominio `
    -DomainNetbiosName "jorge" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "Jorge1234$" -AsPlainText -Force) `
    -InstallDns `
    -Force

# Creación las unidades organizativas UO
New-ADOrganizationalUnit -Name "Cuates" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "No_cuates" -ProtectedFromAccidentalDeletion $true

nuevoUsuarioAD -Dominio $Dominio






