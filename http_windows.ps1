# Función para obtener el HTML de la página
function Get-HTML {
    param (
        [string]$url
    )
    return Invoke-WebRequest -UseBasicParsing -Uri $url
}

function get-version-format {
    param (
        [string]$page
    )
    $format = "\d+\.\d+\.\d+"
    $versiones = [regex]::Matches($page, $format) | ForEach-Object {$_.Value}
    # Eliminar duplicados y ordenar las versiones de mayor a menor
    return $versiones | Sort-Object { [System.Version]$_ } -Descending | Get-Unique
}

function quit-V([string]$version) {
    return $version -replace "^v", ""
}

function Test-PortInUse {
    param (
        [int]$port
    )
    $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet
    return $connection
}

function Es-PuertoValido {
    param (
        [int]$puerto
    )
    $puertosReservados = @{
        20 = "FTP"
        21 = "FTP"
        22 = "SSH"
        23 = "Telnet"
        25 = "SMTP"
        53 = "DNS"
        67 = "DHCP"
        68 = "DHCP"
        80 = "HTTP"
        110 = "POP3"
        119 = "NNTP"
        123 = "NTP"
        143 = "IMAP"
        161 = "SNMP"
        162 = "SNMP"
        389 = "LDAP"
        443 = "HTTPS"
    }

    if ($puertosReservados.ContainsKey($puerto)) {
        Write-Host "El puerto $puerto está reservado para: $($puertosReservados[$puerto])"
        return $false
    }
    return $true
}

while($true){
    Write-Output "¿Que servicio desea instalar?"
    Write-Output "1. IIS"
    Write-Output "2. Caddy"
    Write-Output "3. Nginx"
    Write-Output "0. Salir"
    $opc = Read-Host "Selecciona una opcion"

    if($opc -eq "0"){
        Write-Output "Saliendo..."
        break
    } elseif ($opc -notmatch "^\d+$"){
        Write-Output "Debes ingresar un numero."
    } else {
        switch($opc){
            "1"{
                if(-not(Get-WindowsFeature -Name Web-Server).Installed){
                    Write-Output "Instalando el servicio IIS..."
                    Install-WindowsFeature -Name Web-Server
                }
                else{
                    Write-Output "IIS ya se encuentra instalado"
                }
            
                # Solicitar el puerto para IIS
                $PORT = Read-Host "Ingresa el puerto donde se configurará IIS"
            
                # Validar el puerto
                if ($PORT -notmatch "^\d+$") {
                    Write-Output "Debes ingresar un número."
                } elseif ($PORT -lt 1 -or $PORT -gt 65535) {
                    Write-Output "Puerto no válido, debe estar entre 1 y 65535."
                } elseif (-not (Es-PuertoValido -puerto $PORT)) {
                    Write-Host "El puerto $PORT está reservado para otro servicio."
                } elseif (Test-PortInUse -port $PORT)) {
                    Write-Host "El puerto $PORT ya está en uso."
                } else {
                    # Detener IIS para realizar cambios
                    Stop-Service -Name W3SVC -Force
            
                    # Modificar el archivo de configuración para cambiar el puerto
                    New-WebBinding -Name "Default Web Site" -Protocol http -IPAddress "*" -Port $PORT
            
                    # Reiniciar IIS
                    Start-Service -Name W3SVC
            
                    Write-Output "IIS ha sido configurado para escuchar en el puerto $PORT."
            
                    # Agregar regla de firewall para el puerto
                    netsh advfirewall firewall add rule name="IIS" dir=in action=allow protocol=TCP localport=$PORT
                }
            }
        
            "2"{
                Write-Output "Instalar Caddy..."
                $page_Caddy = Invoke-RestMethod "https://api.github.com/repos/caddyserver/caddy/releases"
                $versionsCaddy = $page_Caddy
                $ltsVersion = $versionsCaddy[6].tag_name
                $devVersion = $versionsCaddy[0].tag_name
                Write-Output "¿Que version de Caddy desea instalar?"
                Write-Output "1. Ultima versión LTS $ltsVersion"
                Write-Output "2. Versión de desarrollo $devVersion"
                Write-Output "0. Salir"
                $OPCION_CADDY = Read-Host "Eliga una opción"

                if ($OPCION_CADDY -notmatch "^\d+$") {
                    Write-Output "Debes ingresar un número."
                } else {
                    switch($OPCION_CADDY){
                        "1"{
                            $PORT = Read-Host "Ingresa el puerto donde se realizara la instalacion"

                            if ($PORT -notmatch "^\d+$") {
                                Write-Output "Debes ingresar un número."
                            } elseif ($PORT -lt 1 -or $PORT -gt 65536) {
                                Write-Output "Puerto no valido, debe estar entre 1 y 65535."
                            } elseif (-not (Es-PuertoValido -port $PORT)) {
                                Write-Host "El puerto $PORT está reservado para un servicio."
                            } else {
                                Stop-Process -Name caddy -ErrorAction SilentlyContinue
                                $ltsVersionClean = (quit-V -version "$ltsVersion")
                                Invoke-WebRequest -UseBasicParsing "https://github.com/caddyserver/caddy/releases/download/$ltsVersion/caddy_${ltsVersionClean}_windows_amd64.zip" -Outfile "C:\Descargas\caddy-$ltsVersion.zip"
                                Expand-Archive C:\Descargas\caddy-$ltsVersion.zip C:\Descargas -Force
                                cd C:\Descargas
                                New-Item c:\Descargas\Caddyfile -type file -Force
                                Add-Content -Path "C:\Descargas\Caddyfile" -Value ":$PORT"
                                Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                Select-String -Path "C:\Descargas\Caddyfile" -Pattern ":$PORT"
                                netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$PORT
                            }
                        }
                        "2"{
                            $PORT = Read-Host "Ingresa el puerto donde se realizara la instalacion"

                            if ($PORT -notmatch "^\d+$") {
                                Write-Output "Debes ingresar un número."
                            } elseif ($PORT -lt 1 -or $PORT -gt 65536) {
                                Write-Output "Puerto no valido, debe estar entre 1 y 65535."
                            } elseif (-not (Es-PuertoValido -port $PORT)) {
                                Write-Host "El puerto $PORT está reservado para un servicio."
                            } else {
                                Stop-Process -Name caddy -ErrorAction SilentlyContinue
                                $devVersionClean = (quit-V -version "$devVersion")
                                Invoke-WebRequest -UseBasicParsing "https://github.com/caddyserver/caddy/releases/download/$devVersion/caddy_${devVersionClean}_windows_amd64.zip" -Outfile "C:\Descargas\caddy-$devVersion.zip"
                                Expand-Archive C:\Descargas\caddy-$devVersion.zip C:\Descargas -Force
                                cd C:\Descargas
                                New-Item c:\Descargas\Caddyfile -type file -Force
                                Add-Content -Path "C:\Descargas\Caddyfile" -Value ":$PORT"
                                Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                Select-String -Path "C:\Descargas\Caddyfile" -Pattern ":$PORT"
                                netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$PORT
                            }
                        }
                    }
                }
            }
            "3"{
                Write-Output "Instalar Nginx..."
                $downloadsNginx = "https://nginx.org/en/download.html"
                $page_Nginx = (Get-HTML -url $downloadsNginx)
                $versionsNginx = (get-version-format -page $page_Nginx)
                $ltsVersion = $versionsNginx[1]
                $devVersion = $versionsNginx[0]

                Write-Output "¿Que version de Nginx desea instalar?"
                Write-Output "1. Ultima versión LTS $ltsVersion"
                Write-Output "2. Versión de desarrollo $devVersion"
                Write-Output "0. Salir"
                $OPCION_NGINX = Read-Host "Eliga una opción"

                if ($OPCION_NGINX -notmatch "^\d+$") {
                    Write-Output "Debes ingresar un número."
                } else {

                    switch($OPCION_NGINX){
                        "1"{
                            $PORT = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                            if ($PORT -notmatch "^\d+$") {
                                Write-Output "Debes ingresar un numero."
                            } elseif ($PORT -lt 1 -or $PORT -gt 65536) {
                                Write-Output "Puerto no valido, debe estar entre 1 y 65535."
                            } elseif (-not (Es-PuertoValido -port $PORT)) {
                                Write-Host "El puerto $PORT está reservado para un servicio."
                            } else {
                                Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$ltsVersion.zip" -Outfile "C:\Descargas\nginx-$ltsVersion.zip"
                                Expand-Archive C:\Descargas\nginx-$ltsVersion.zip C:\Descargas -Force
                                cd C:\Descargas\nginx-$ltsVersion
                                Start-Process nginx.exe
                                Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                cd ..
                                (Get-Content C:\Descargas\nginx-$ltsVersion\conf\nginx.conf) -replace "listen       [0-9]{1,5}", "listen       $PORT" | Set-Content C:\Descargas\nginx-$ltsVersion\conf\nginx.conf
                                Select-String -Path "C:\descargas\nginx-$ltsVersion\conf\nginx.conf" -Pattern "listen       [0-9]{1,5}"
                            }
                        }
                        "2"{
                            $PORT = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                            if ($PORT -notmatch "^\d+$") {
                                Write-Output "Debes ingresar un numero."
                            } elseif ($PORT -lt 1 -or $PORT -gt 65536) {
                                Write-Output "Puerto no valido, debe estar entre 1 y 65535."
                            } elseif (-not (Es-PuertoValido -port $PORT)) {
                                Write-Host "El puerto $PORT está reservado para un servicio."
                            } else {
                                Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$devVersion.zip" -Outfile "C:\Descargas\nginx-$devVersion.zip"
                                Expand-Archive C:\Descargas\nginx-$devVersion.zip C:\Descargas -Force
                                cd C:\Descargas\nginx-$devVersion
                                Start-Process nginx.exe
                                Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                cd ..
                                (Get-Content C:\Descargas\nginx-$devVersion\conf\nginx.conf) -replace "listen       [0-9]{1,5}", "listen       $PORT" | Set-Content C:\Descargas\nginx-$devVersion\conf\nginx.conf
                                Select-String -Path "C:\descargas\nginx-$devVersion\conf\nginx.conf" -Pattern "listen       [0-9]{1,5}"
                            }
                        }
                    }
                }
            }
            default{
                Write-Output "Opción no válida."
            }
        }
    }
}