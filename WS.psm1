

# Función usada para configurar la red estatica
function ConfigurarIpEstatica {
    # Capturar IP
    while ($true) {
        $Ip = Read-Host "Ingrese la dirección IP"
        if (ValidarIp -Ip $Ip) {
            break
        }
    }

    # Capturar Gateway 
    while ($true) {
        $SegRed = ExtraerSegmento -Ip $Ip
        $PuertaEnlace = "$SegRed.1"
        $Opc = Read-Host "¿Desea cambiar la puerta de enlace? [y/n]"
        
        if ($Opc.ToLower() -eq 'y') {
            while ($true) {
                $PuertaEnlace = Read-Host "Ingrese el nuevo gateway"
                if (ValidarIp -Ip $PuertaEnlace) {
                    break
                }
            }
        }
        break
    }

    # Configurar IP en la interfaz de red
    $PrefijoRed = CalcularMascara -Ip $Ip
    if ($PrefijoRed -ne $null) {
        New-NetIPAddress -IPAddress $Ip -PrefixLength $PrefijoRed -DefaultGateway $PuertaEnlace -InterfaceIndex 6 -ErrorAction SilentlyContinue *>$null
        Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses @("8.8.8.8", "8.8.4.4") -ErrorAction SilentlyContinue *> $null
        Restart-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue *>$null
    }
}

# Función para extraer el segmento de red de una IP
function ExtraerSegmento {
    param ([String] $Ip)
    $Seg = $Ip.Split(".")
    return "$($Seg[0]).$($Seg[1]).$($Seg[2])"
}

# Función para calcular la máscara de subred en formato de prefijo (CIDR)
function CalcularMascara {
    param ([String] $Ip)
    $Seg = $Ip.Split(".")
    $SegRed = $Seg[0] -as [int]  # Convertir a número
    switch ($SegRed) {
        {$_ -ge 0 -and $_ -le 127} { return 8 }   # Clase A
        {$_ -ge 128 -and $_ -le 191} { return 16 } # Clase B
        {$_ -ge 192 -and $_ -le 223} { return 24 } # Clase C
        default { return $null }  # IP no válida
    }
}

# Función para validar una dirección IP
function ValidarIp {
    param ([String] $Ip)
    $Patron = '^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$'
    return $Ip -match $Patron
}

# Función para validar un dominio
function ValidarDominio {
    param ([String] $Dominio)
    $Patron = '(^(([a-z]{2,})+\.)+([a-z]{2,})+)$'
    return $Dominio.ToLower() -match $Patron
}

function nuevoUsuarioAD {
    param([string] $Dominio)
    $Seg = $Dominio.Split(".")
    $Seg0 = $Seg[0]
    $Seg1 = $Seg[1]
    while($true){
        while ($true){
            write-host "Ingresa el nombre del usuario:"
            $Usuario = Read-Host

            if(validarUsuario -Usuario $Usuario)
            {
                break
            }
        }
        while ($true){
            write-host "Crea una contraseña:"
            write-host "(8-20 Caracteres, NO espacios, NO caracteres especiales)"
            $Contra = read-host 
            if(validarContra -Contra $Contra)
            {
                break
            }
        }
        while ($true){
            write-host "Ingresa el nombre:"
            $Nombre = Read-Host 
            if(validarNombre -Nombre $Nombre)
            {
                break
            }
        }
            
        while ($true){
            write-host "Ingresa su 1er apellido:"
            $Apellido = Read-Host
            if(validarNombre -Nombre $Apellido)
            {
                break
            }
        }
        while ($true){
            write-host "Elige UO"
            write-host "[1] Cuates"
            write-host "[2] No_cuates"
            write-host "Selecciona una opción:"
            $UO = Read-Host
            if ($UO -eq 1 ) {
                $UO = "Cuates"
                break
            } elseif ($UO -eq 2) {
                $UO = "No_cuates"
                break
            } else {
                write-host "Selecciona una opción valida..."
            }
        }

        #Creación del usuario
        New-ADUser -Name $Usuario `
            -GivenName $Nombre `
            -Surname $Apellido `
            -SamAccountName $Usuario `
            -UserPrincipalName "$Usuario@$Dominio" `
            -Path "OU=$UO,DC=$Seg0,DC=$Seg1" `
            -AccountPassword (ConvertTo-SecureString $Contra -AsPlainText -Force) `
            -Enabled $true

        #Validar que si creo el usario
        if (Get-ADUser -Filter {Name -eq $Usuario}){
            write-host "Usuario creado exitosamente"
            return
        } else {
            Write-host "Usuario no creado"
        }
        
    }
}
function validarContra {
    param([String] $Contra)
    # 8-20 Caracteres, Una Mayuscula,  NO espacios, NO caracteres especiales)"
    if (($Contra.Length -ge 8) -and ($Contra.Length -le 20) -and ($Contra -match "^[a-zA-Z0-9]+$") -and ($Contra -match "[A-Z]")) {
        return $true
    }
    else {
        Write-Host "Contraseña inválida. Debe tener entre 8-20 caracteres, al menos una mayúscula, sin espacios ni caracteres especiales."
        return $false
    }
}
function validarNombre {
    param (
        [string] $Nombre
    )
    # Condiciones 
    <#
        -No espacios
        -No caracteres especiales
    #>    
    if ($Nombre -match "^[a-zA-Z]+$") {
        return $true
    }
    else {
        Write-Host "Nombre inválido. Solo letras permitidas."
        return $false
    }



    return $true
}
function validarUsuario {
    param (
        [string] $Usuario
    )
    # Condiciones 
    <#
        -No espacios
        -Maximo 20 caracteres
        -No caracteres especiales
    #>
    if (($Usuario.Length -le 20) -and ($Usuario -match "^[a-zA-Z0-9]+$")) {
        return $true
    }
    else {
        Write-Host "Usuario inválido. Max 20 caracteres, solo letras y números, sin espacios ni especiales."
        return $false
    }


    return $true
}
# ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ======
# HTTPS Typo
function MenuServidores {
    while ($true)
    {
        Write-Host " ========= ========= ========="
        Write-Host " SERVIDOES WEB DISPONIBLES"
        Write-Host " [0] Apache"
        Write-Host " [1] Nginx"
        Write-Host " [2] ISS"
        Write-Host " [3] Salir"
        Write-Host "Selecciona un servidor:"
        $opc = Read-Host 
        if(($opc -eq 0) -or ($opc -eq 1) -or ($opc -eq 2) -or ($opc -eq 3) )
        {
            Return $opc
        }
        else
        {
            Write-Host "Opción no valida, vuelva a intentarlo..."    
        }
    }
}

function MenuDescarga {
    param (
        [INT] $opc, [array] $Servidores
    )
    $ServidorActual = $Servidores[$opc]
    while ($true)
    {
        Write-Host "====== DESCARGAS DISPONIBLES ======"
        Write-Host "$($ServidorActual.NombreLTS) $($ServidorActual.VersionLTS)"
        Write-Host "$($ServidorActual.NombreDEV) $($ServidorActual.VersionDEV)"

        <#elseif($opc = 1)
        {
            Write-Host " [1] $($ServidorActual.NombreLTS) --Version $($ServidorActual.VersionLTS)"
            Write-Host " [2] $($ServidorActual.NombreDEV) --Version $($ServidorActual.VersionDEV)"
        }#>
        
        Write-Host "Seleccione una opción:" 
        $X = Read-Host 

        # Solicitar el puerto y validar que no este en uso
        while ($true)
        {
            Write-Host "Elige un puerto para instalar:" 
            $Puerto = Read-Host 
            if(!(ProbarPuerto -Puerto $Puerto))
            {
                Break
            }
            else
            {
                Write-Host "ERROR: Seleccione un puerto valido"
            }
            
        }

        if ($X -eq 1)
        {
            if ($opc -eq 2)
            {
                InstalarIIS -Puerto $Puerto
                return
            }
            Write-Host "Seleccionado: $($ServidorActual.NombreLTS) --Version $($ServidorActual.VersionLTS)"
            Instalacion -url $ServidorActual.EnlaceLTS -NomZip $ServidorActual.NombreLTS -opc $opc -Puerto $Puerto
            break
        }
        elseif ($X -eq 2)
        {
            if($($ServidorActual.NombreDEV -ne "N/A"))
            {
                Write-Host "Seleccionado: $($ServidorActual.NombreDEV) --Version $($ServidorActual.VersionDEV)"
                Instalacion -url $ServidorActual.EnlaceDEV -NomZip $ServidorActual.NombreDEV -opc $opc -Puerto $Puerto
                break
            }
            else 
            {
                Write-Host "Este servidor no cuenta con versión de Desarollo"
                Write-Host "Selecciona una versión valida...."
            }

        }
        else 
        {
            Write-Host "Seleccione una opción valida"
            Read-Host "Selecciona una opción valida...."
        }
    }
}

function ActualizarDatos {
    param (
        [Array] $Array
    )

    $opc = 0
    foreach($Elemento in $Array)
    {
        # Meter la validación de que si tiene version DEV o nel
        <#
            Aqui
        #>
        if ($opc -eq 0)
        {
            # Actualizar datos Apache
            DescargarHTML -url $($Elemento.EnlaceLTS)
            $Link = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronLTS)
            $Link = "$($Elemento.EnlaceLTS)$Link"
            $Elemento.EnlaceLTS = $Link

            $Version = ExtraerVersion -urlDescarga $($Elemento.EnlaceLTS) -Patron $($Elemento.PatronVersion)
            $Elemento.VersionLTS = $Version
        } 
        elseif ($opc -eq 1) 
        {
            # Actualizar dato Nginx
            DescargarHTML -url $($Elemento.EnlaceLTS)
            $Link = EncontrarLinkDEV -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronLTS)
            $LinkSinExtension = $($Elemento.EnlaceLTS) 
            $LinkSinExtension = $LinkSinExtension -replace "\.html", ""
            $LinkSinExtension = $LinkSinExtension -replace "\/en", ""
            $Version = ExtraerVersion -urlDescarga $Link -Patron $($Elemento.PatronVersion)
            $Elemento.VersionLTS = $Version
            $Elemento.EnlaceLTS = "$LinkSinExtension/nginx-$Version.zip"

            #Version DEV
            $Link = ""
            $LinkSinExtension = ""
            $Version = ""

            $Link = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronDEV)
            $LinkSinExtension = $($Elemento.EnlaceDEV)
            $LinkSinExtension = $LinkSinExtension -replace "\.html", ""
            $LinkSinExtension = $LinkSinExtension -replace "\/en", ""
            $Version = ExtraerVersion -urlDescarga $Link -Patron $($Elemento.PatronVersion)
            $Elemento.VersionDEV = $Version
            $Elemento.EnlaceDEV = "$LinkSinExtension/nginx-$Version.zip"
            if ($opc -eq 2)
            {
                
            } 
        }
        $opc++
    }
}

function InstalarIIS {
    param(
        [int]$Puerto
    )

    Write-Host "Iniciando la instalación de IIS..."
        try {
            # Instalar el rol de servidor web (IIS) con todas las subcaracterísticas y herramientas de gestión
            Write-Host "Instalando el rol de servidor web (IIS)..."
            # Verificar si los módulos de IIS están instalados
            Write-Host "Verificando si los módulos de IIS están instalados..."
            $iisInstalled = Get-WindowsFeature Web-Server -ErrorAction SilentlyContinue
            # Instalar el servicio de Web Server (IIS)
            Write-Host "Instalando el servicio de Web Server (IIS)..."
            if (-not $iisInstalled.Installed) {
                Write-Host "Instalando IIS" -ForegroundColor Yellow
                try {
                        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
                        Import-Module WebAdministration
                }
                catch {
                    Write-Host "Error: No se pudo instalar IIS. $($_.Exception.Message)" -ForegroundColor Red
                    exit 1
                }
            }

            # Verificar si la instalación fue exitosa
            if ((Get-WindowsFeature -Name Web-Server).Installed) {
                Write-Host "IIS instalado correctamente."
                # Iniciar el servicio W3SVC
                Write-Host "Iniciando el servicio W3SVC..."
                Start-Service -Name W3SVC -ErrorAction Stop

                # Cambiar el puerto del sitio web predeterminado
                Write-Host "Configurando el puerto $Puerto..."
                Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName Port -Value $Puerto -ErrorAction Stop

                # Reiniciar el servicio para aplicar los cambios
                Write-Host "Reiniciando el servicio W3SVC..."
                Restart-Service -Name W3SVC -ErrorAction Stop

                # Abrir el puerto en el firewall
                Write-Host "Abriendo el puerto $Puerto en el firewall..."
                New-NetFirewallRule -Name "IIS_Port_$Puerto" -DisplayName "IIS (Puerto $Puerto)" -Protocol TCP -LocalPort $Puerto -Action Allow -Direction Inbound -ErrorAction Stop

                Write-Host "Instalación y configuración de IIS completada exitosamente."
            } else {
                Write-Host "Error: No se pudo instalar IIS." -ForegroundColor Red
            }
        } catch {
            Write-Host "Error durante la instalación o configuración de IIS: $_" -ForegroundColor Red
        }
}

function DescargarHTML {
    Param([String] $url)
    if (test-path "./html.txt")
    {
        rm html.txt
    }
    $Archivo = "html.txt"

    # Configurar opciones para Invoke-WebRequest
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    

    try {
        # Descargar el contenido de la página
        $response = Invoke-WebRequest -Uri $url -UserAgent $userAgent -Headers $headers -UseBasicParsing -ErrorAction Stop
        $response.Content > $Archivo
    } catch {
        Write-Output "Error al descargar el HTML: $_"
    }
}


function EncontrarLink {
    param (
        [String] $NomArchivo,
        [String] $PatronRegex
    )

    # Nos aseguramos que la variable automatica este limpia
    $Matches = $null # Devuelve las cadenas que coincide con el patrón
    try {
        $Archivo = Get-Content ".\$NomArchivo" -ErrorAction Stop 
        foreach ($Line in $Archivo) {
            if ($Line -match $PatronRegex) {
                return $Matches[0]
            }
        }
        # Si no retorna ningún match, no se encontraron coincidencias
        Write-Output "No se encontró ninguna coincidencia."
        return $null
    } catch {
        Write-Output "Error al leer el archivo: $_"
    }    
    
}

function ProbarPuerto {
    param (
        [INT] $Puerto
    )
    $connection = Get-NetTCPConnection -LocalPort $Puerto -ErrorAction SilentlyContinue 
    
    if ($connection) {
        Return $true  # Puerto denegado
    } else {
        Return $false  # Puerto aceptado
    }    
}
function EncontrarLinkDEV {
    param (
        [String] $NomArchivo,
        [String] $PatronRegex
    )
    # En este caso tenemos multiples versiones, así que vamos a buscar la 2da
    $coincidencias = @()
    # Nos aseguramos que la variable automatica este limpia
    $Matches = $null # Devuelve las cadenas que coincide con el patrón
    try {
        $Archivo = Get-Content ".\$NomArchivo" -Raw -ErrorAction Stop  # Leer el archivo como un solo bloque
        if ($Archivo -match $PatronRegex) {
            $coincidencias = [regex]::Matches($Archivo, $PatronRegex) | ForEach-Object { $_.Value }
        }

        # Verificar si hay al menos dos coincidencias y devolver la segunda
        if ($coincidencias.Count -ge 2) {
            return $coincidencias[1]
        } else {
            Write-Output "No se encontró una segunda coincidencia."
            return $null
        }
    } catch {
        Write-Output "Error al leer el archivo: $_"
    }
    
}


function Instalacion {
    param (
        [String] $url,
        [String] $NomZip,
        [int] $opc,
        [INT] $Puerto
    )

    # La carpeta Servidor será para almacenar los .zip de los servidores
    if (!(Test-Path 'C:\Servidor' -ErrorAction SilentlyContinue)) {
        mkdir 'C:\Servidor' 
    }

    # Proceso para la instalación
    $Salida = "C:\Servidor\$NomZip.zip"
    # DEBUG Write-Host "Salida: $Salida"
    # DEBUG Write-Host "URL: $url

    # Iniciar la instalación
    # Comprobar que el .zip no este instalado
    if (!(Test-Path $Salida)) {
        $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

        try {
            # DEBUG Write-Host "Se realiza la petición"
            Invoke-WebRequest -Uri $url -UserAgent $userAgent -OutFile $Salida -ErrorAction Stop 
            Write-Output "Descarga exitosa."
            Write-Host "Extrayendo archivo"
            Expand-Archive -LiteralPath $Salida -DestinationPath "C:\" -Force
        } catch {
            Write-Output "Error: $_"
            return  # Salir de la función si hay un error en la descarga
        }
    }


    # Configurar el firewall

    # DEBUG Write-Host "Creando nueva regla firewall"
    if (!(Get-NetFirewallRule -Name $NomZip -ErrorAction SilentlyContinue *>$null ))
    {
        New-NetFirewallRule -Name $NomZip -DisplayName $NomZip -Protocol TCP -LocalPort $Puerto -Action Allow -Direction Inbound -ErrorAction SilentlyContinue *>$null
    }
    
    cd "C:\"
    # Nos dirigimos a la carpeta que contiene el ejecutable
    switch ($opc) {
        # Instalar Apache
        0 {
            Write-Host "Configurando Apache..."
            cd C:\Apache24\conf
                try {
                    (Get-Content "C:\Apache24\conf\httpd.conf") -replace "Listen \d+", "Listen 0.0.0.0:$Puerto" | Set-Content "C:\Apache24\conf\httpd.conf"
                    cd C:\Apache24\bin
                    .\httpd.exe -k install
                    Start-Service -Name Apache2.4
                    Start-Sleep -Seconds 5
                    Write-Host "Instalación completa"
                    if(Get-Service -Name Apache2.4 -ErrorAction SilentlyContinue)
                        {
                            Write-Host "Apache iniciado correctamente."
                            return
                        }
    
                } catch {
                    Write-Host "Ocurrió un error en la instalación de Apache: $_"
                }
        }

        # Instalar Nginx
        1 {
            if (Test-Path "C:\nginx-1.27.4") 
            {
                # Cambiar a la carpeta seleccionada
                cd "C:\nginx-1.27.4"
                if(!(Get-Process -Name nginx -ErrorAction SilentlyContinue))
                {
                    try {
                        (Get-Content "C:\nginx-1.27.4\conf\nginx.conf") -replace "listen\s+\d+;", "listen 0.0.0.0:$Puerto;" | Set-Content "C:\nginx-1.27.4\conf\nginx.conf"   
                        Start-Process -FilePath "C:\nginx-1.27.4\nginx.exe" -NoNewWindow
                        Start-Sleep -Seconds 5
                        if(Get-Process -Name nginx -ErrorAction SilentlyContinue)
                        {
                            Write-Host "Nginx iniciado correctamente."
                            return
                        }
                        Write-Host "Nginx no se ha inciado."
                        return

                    } catch {
                        Write-Host "Error al iniciar Nginx: $_"
                    }
                }
                else 
                {
                    Write-Host "Nginx ya esta instalado y configurado"
                    return
                }
                # Iniciar Nginx
                
            }
            # LTS Version
            elseif (Test-Path "C:\nginx-1.26.3")
            {
                # Cambiar a la carpeta seleccionada
                cd "C:\nginx-1.26.3"
                if(!(Get-Process -Name nginx -ErrorAction SilentlyContinue))
                {
                    try {
                        (Get-Content "C:\nginx-1.26.3\conf\nginx.conf") -replace "listen\s+\d+;", "listen 0.0.0.0:$Puerto;" | Set-Content "C:\nginx-1.26.3\conf\nginx.conf"   
                        Start-Process -FilePath "C:\nginx-1.26.3\nginx.exe" -NoNewWindow
                        Start-Sleep -Seconds 5
    
                        if(Get-Process -Name nginx -ErrorAction SilentlyContinue)
                        {
                            Write-Host "Nginx iniciado correctamente."
                            return
                        }
                        Write-Host "Nginx no se ha inciado."
                        return
    
                    } catch {
                        Write-Host "Error al iniciar Nginx: $_"
                    }
                } else 
                {
                    Write-Host "Nginx ya esta instalado y configurado"
                    return
                }                
            } 
        }
    }
}


function ExtraerVersion {
    param (
        [String] $urlDescarga, [String] $Patron
    )
    
    if($urlDescarga -match $Patron)
    {
        return $Matches[0]
    }
}

