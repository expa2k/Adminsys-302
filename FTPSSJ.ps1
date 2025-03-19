function Verificar-CaracteristicaWindows {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)] [string]$NombreCaracteristica 
    )  
    return (Get-WindowsOptionalFeature -FeatureName $NombreCaracteristica -Online).State -eq "Enabled"
}

if(-not (Verificar-CaracteristicaWindows "Web-Server")){
    Install-WindowsFeature Web-Server -IncludeManagementTools
}

if(-not (Verificar-CaracteristicaWindows "Web-Ftp-Server")){
    Install-WindowsFeature Web-Ftp-Server -IncludeAllSubFeature
}

if(-not (Verificar-CaracteristicaWindows "Web-Basic-Auth")){
    Install-WindowsFeature Web-Basic-Auth
}

Import-Module WebAdministration

function Asegurar-Carpeta([String]$ruta){
    if(!(Test-Path $ruta)){
        New-Item -ItemType Directory -Path $ruta | Out-Null
    }
}

function Crear-FTP([String]$nombre, [Int]$puerto = 21, [String]$directorio){
    New-WebFtpSite -Name $nombre -Port $puerto -PhysicalPath $directorio -Force
    return $nombre
}

function Obtener-ADSI(){
    return [ADSI]"WinNT://$env:ComputerName"
}

Function Evaluar-Contrasena {
    param (
        [string]$Clave
    )
    
    $minimo = 8
    $mayus = "[A-Z]"
    $minus = "[a-z]"
    $numero = "[0-9]"
    $especial = "[!@#$%^&*()\-+=]"
    
    return ($Clave.Length -ge $minimo -and $Clave -match $mayus -and $Clave -match $minus -and $Clave -match $numero -and $Clave -match $especial)
}

function Crear-GrupoFTP([String]$nombre, [String]$descripcion){
    $grupo = Obtener-ADSI().Create("Group", "$nombre")
    $grupo.Description = $descripcion
    $grupo.SetInfo()
    return $nombre
}

function Crear-UsuarioFTP([String]$usuario, [String]$clave){
    $nuevoUsuario = Obtener-ADSI().Create("User", "$usuario")
    $nuevoUsuario.SetInfo()
    $nuevoUsuario.SetPassword("$clave")
    $nuevoUsuario.SetInfo()
}

function Agregar-UsuarioAGrupo([String]$usuario, [String]$grupo){
    $cuenta = New-Object System.Security.Principal.NTAccount("$usuario")
    $sid = $cuenta.Translate([System.Security.Principal.SecurityIdentifier])
    $grupoAD = [ADSI]"WinNT://$env:ComputerName/$grupo,Group"
    $usuarioAD = [ADSI]"WinNT://$sid"
    $grupoAD.Add($usuarioAD.Path)
}

function Configurar-AutenticacionFTP(){
    Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.Security.authentication.basicAuthentication.enabled -Value $true
}

function Configurar-Permisos([String]$grupo, [Int]$nivel = 3, [String]$carpeta){
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$grupo";permissions=$nivel} -PSPath IIS:\ -location "FTP_Servidor/$carpeta"
}

function Configurar-SSL($activar){
    if ($activar){
        $certificado = "96D9BFD93676F3BC2E9F54D9138C4C92801EB6DD"
        Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.security.ssl.serverCertHash -Value $certificado
        Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslRequire"
        Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslRequire"
    } else {
        Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
        Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
    }
}

function Reiniciar-FTP(){
    Restart-WebItem "IIS:\Sites\FTP_Servidor"
}

# Configuración inicial
$rutaFTP = "C:\FTP"
Asegurar-Carpeta $rutaFTP
Crear-FTP -nombre "FTP_Servidor" -puerto 21 -directorio $rutaFTP
Set-ItemProperty "IIS:\Sites\FTP_Servidor" -Name ftpServer.userIsolation.mode -Value 3

if(!(Get-LocalGroup -Name "UsuariosFTP")){
    Crear-GrupoFTP -nombre "UsuariosFTP" -descripcion "Usuarios permitidos en el servidor FTP"
}

Configurar-AutenticacionFTP

$habilitarSSL = Read-Host "¿Desea activar SSL? (si/no)"
Configurar-SSL ($habilitarSSL -eq "si")
Reiniciar-FTP

# Menú
while($true){
    echo "\nOpciones:"
    echo "1. Agregar usuario"
    echo "2. Salir"
    
    try{
        $opcion = Read-Host "Seleccione una opción"
        $opcionNum = [int]$opcion
    }
    catch{
        echo "Por favor, ingrese un número válido"
        continue
    }
    
    if($opcionNum -eq 2){
        echo "Saliendo..."
        break
    }
    
    if($opcionNum -eq 1){
        try{
            $usuario = Read-Host "Ingrese nombre de usuario"
            $clave = Read-Host "Ingrese contraseña"
            
            if(-not (Evaluar-Contrasena -Clave $clave)){
                echo "La contraseña no cumple con los requisitos de seguridad"
            } else {
                Crear-UsuarioFTP -usuario $usuario -clave $clave
                Agregar-UsuarioAGrupo -usuario $usuario -grupo "UsuariosFTP"
                echo "Usuario $usuario agregado con éxito"
            }
        } catch {
            echo "Error: $_"
        }
    }
    echo "\n"
}