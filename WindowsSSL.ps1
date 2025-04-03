function installFTP {
    param (
        [bool]$installSSL
    )
    
    Install-WindowsFeature Web-Server -IncludeAllSubFeature 
    Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature

    $ftpUser = "FTPUser"
    $ftpPassword = "Window97"
    $ftpGroupName = "FTPGroup"
    $ftpPath = "C:\FTP"
    
    net localgroup $ftpGroupName /Add
    net user $ftpUser $ftpPassword /add
    net localgroup $ftpGroupName $ftpUser /add

    $acl = Get-Acl $ftpPath
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($ftpUser, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl -Path $ftpPath -AclObject $acl

    if ($installSSL) {
        New-WebFtpSite -Name "FTP" -Port 990 -PhysicalPath $ftpPath 
    } else {
        New-WebFtpSite -Name "FTP" -Port 21 -PhysicalPath $ftpPath
    }

    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users=$ftpUser;permissions="Read,Write"} -PSPath IIS:\ -Location "FTP"

    if ($installSSL) {
        Write-Host "Configurando SSL para el servidor FTP..."

        $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My"
        $thumbprint = $cert.Thumbprint

        Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.serverCertHash -Value $thumbprint
        Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 1
        Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 1
        New-NetFirewallRule -DisplayName "FTPS" -Direction Inbound -Protocol TCP -LocalPort 990 -Action Allow
    } else {
        Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
        Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
        New-NetFirewallRule -DisplayName "FTP" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
    }

    Restart-WebItem "IIS:\Sites\FTP"
}

function downloadFTPFile {
    param (
        [string]$ftpFilePath,
        [string]$destinationPath
    )

    $ftpUser = "FTPUSer"
    $ftpPassword = "Window97"

    $ftpServer = "localhost"
    $uri = "ftp://$ftpServer/$ftpFilePath"

    $webClient = New-Object System.Net.WebClient
    $webClient.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPassword)

    $webClient.DownloadFile($uri, $destinationPath)
    $webClient.Dispose()
}

function downloadFTPSFile {
    param (
        [string]$ftpFilePath,
        [string]$destinationPath
    )

    $ftpUser = "FTPUser"
    $ftpPassword = "Window97"
    $ftpServer = "localhost"
    $ftpPort = 990

    curl.exe --ssl-reqd -k -u "${ftpUser}:${ftpPassword}" -o "$destinationPath" "ftps://${ftpServer}:${ftpPort}/${ftpFilePath}"

    if ($?) {
        Write-Host "Descarga completada: $destinationPath"
    } else {
        Write-Host "Error: No se pudo descargar el archivo."
    }
}

function installIIS {
    param (
        [int]$port
    )

    do {
        $res = Read-Host "¿Desea implementar un certificado SSL en el servidor HTTP? (s/n)"
    } while ($res -ne "s" -and $res -ne "n" -and $res -ne "S" -and $res -ne "N")

    if ($res -eq "s" -or $res -eq "S") {
        $isHTTPS = $true
    } else {
        $isHTTPS = $false
    }

    Write-Host "Instalando IIS..."
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools

    Write-Host "Configurando IIS para usar el puerto $port..."

    $site = Get-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
    if (-Not $site) {
        Write-Host "El sitio web 'Default Web Site' no existe. Creándolo..."
        New-Website -Name 'Default Web Site' -Port 80 -PhysicalPath "C:\inetpub\wwwroot" -Force
    }

    Stop-WebSite -Name 'Default Web Site' -ErrorAction SilentlyContinue

    Get-WebBinding -Name 'Default Web Site' | ForEach-Object {
        Remove-WebBinding -Name 'Default Web Site' -BindingInformation $_.BindingInformation
    }

    if ($isHTTPS) {
        Write-Host "Configurando HTTPS en el puerto $port..."

        $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My"
        $thumbprint = $cert.Thumbprint

        New-WebBinding -Name 'Default Web Site' -Protocol "https" -Port $port -IPAddress "*" -HostHeader ""
        $binding = Get-WebBinding -Name 'Default Web Site' -Protocol "https" -Port $port
        $binding.AddSslCertificate($thumbprint, "my")

        Export-Certificate -Cert $cert -FilePath "C:\localhost.cer"
        Import-Certificate -FilePath "C:\localhost.cer" -CertStoreLocation Cert:\LocalMachine\Root
    } else {
        Write-Host "Configurando HTTP en el puerto $port..."
        New-WebBinding -Name 'Default Web Site' -Protocol "http" -Port $port -IPAddress "*" -HostHeader ""
    }

    Start-Sleep -Seconds 3
    Start-WebSite -Name 'Default Web Site'

    Write-Host "Configurando el firewall..."
    New-NetFirewallRule -DisplayName "Allow IIS Port $port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow *> $null

    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
    if ($isHTTPS) {
        Write-Host "Puede acceder a su servidor en https://localhost:$port (servidor local) o https://${ipAddress}:${port} (cualquier dispositivo en la red local)"
    } else {
        Write-Host "Puede acceder a su servidor en http://localhost:$port (servidor local) o http://${ipAddress}:${port} (cualquier dispositivo en la red local)"
    }
}

function installApache {
    param (
        [string]$version,
        [int]$port
    )

    do {
        $res = Read-Host "¿Desea implementar un certificado SSL en el servidor HTTP? (s/n)"
    } while ($res -ne "s" -and $res -ne "n" -and $res -ne "S" -and $res -ne "N")

    if ($res -eq "s" -or $res -eq "S") {
        $isHTTPS = $true
    } else {
        $isHTTPS = $false
    }

    Write-Host "Extrayendo el archivo descargado..."
    Expand-Archive -Path "C:\apache-${version}.zip" -DestinationPath "C:\" -Force
    .\vc.ps1

    Write-Host "Configurando Apache..."
    Set-Location "C:\Apache24\bin"
    .\httpd.exe -k install -n "Apache2.4"

    Write-Host "Configurando Apache para usar el puerto $port..."
    $filePath = 'C:\Apache24\conf\httpd.conf'
    $fileContent = Get-Content -Path $filePath
    $fileContent = $fileContent -replace 'Listen 80', "Listen $port"
    $fileContent = $fileContent -replace 'ServerName www.example.com:80', "ServerName 127.0.0.1:${port}"
    
    
    if ($isHTTPS) {
        .\openssl.exe req -x509 -nodes -newkey rsa:2048 -keyout C:\Apache24\bin\localhost.key -out C:\Apache24\bin\localhost.crt -days 365 -subj "/CN=localhost"

        $fileContent = $fileContent -replace '#LoadModule include_module modules/mod_include.so', "LoadModule include_module modules/mod_include.so"
        $fileContent = $fileContent -replace '#LoadModule ssl_module modules/mod_ssl.so', "LoadModule ssl_module modules/mod_ssl.so"
        $fileContent = $fileContent -replace '#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so', "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so"
        $fileContent = $fileContent -replace '#Include conf/extra/httpd-default.conf', "Include conf/extra/httpd-default.conf"
        $fileContent = $fileContent -replace '#Include conf/extra/httpd-ssl.conf', "Include conf/extra/httpd-ssl.conf" 

        $filePathSSL = 'C:\Apache24\conf\extra\httpd-ssl.conf'
        $fileContentSSL = Get-Content -Path $filePathSSL
        #$fileContentSSL = $fileContentSSL -replace 'Listen 443', "Listen $port https"
        $fileContentSSL = $fileContentSSL -replace '<VirtualHost _default_:443>', "<VirtualHost _default_:$port>"
        $fileContentSSL = $fileContentSSL.Replace('${SRVROOT}/conf/server.crt', 'C:\Apache24\bin\localhost.crt')
        $fileContentSSL = $fileContentSSL.Replace('${SRVROOT}/conf/server.key', 'C:\Apache24\bin\localhost.key')
        $fileContentSSL | Set-Content -Path $filePathSSL
    }

    $fileContent | Set-Content -Path $filePath

    Write-Host "Iniciando Apache..."
    net start "Apache2.4"

    Write-Host "Configurando el firewall..."
    New-NetFirewallRule -DisplayName "Allow Apache Port $port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow

    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
    if ($isHTTPS) {
        Write-Host "Puede acceder a su servidor en https://localhost:$port (servidor local) o https://${ipAddress}:${port} (cualquier dispositivo en la red local)"
    } else {
        Write-Host "Puede acceder a su servidor en http://localhost:$port (servidor local) o http://${ipAddress}:${port} (cualquier dispositivo en la red local)"
    }

    Set-Location "C:\"
}

function installNginx {
    param (
        [string]$version,
        [int]$port
    )

    do {
        $res = Read-Host "¿Desea implementar un certificado SSL en el servidor HTTP? (s/n)"
    } while ($res -ne "s" -and $res -ne "n" -and $res -ne "S" -and $res -ne "N")

    if ($res -eq "s" -or $res -eq "S") {
        $isHTTPS = $true
    } else {
        $isHTTPS = $false
    }

    Write-Host "Extrayendo el archivo descargado..."
    Expand-Archive -Path "C:\nginx-${version}.zip" -DestinationPath "C:\" -Force

    Write-Host "Configurando Nginx para usar el puerto $port..."
    
    if ($isHTTPS) {
        if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "Instalando Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }

        Write-Host "Instalando OpenSSL usando Chocolatey..."
        choco install openssl -y

        $opensslPath = "C:\Program Files\OpenSSL-Win64\bin"
        if (-Not ($env:Path -split ';' -contains $opensslPath)) {
            $env:Path += ";$opensslPath"
        }

        Write-Host "Generando certificado autofirmado..."
        openssl req -x509 -nodes -newkey rsa:2048 -keyout C:\localhost.key -out C:\localhost.crt -days 365 -subj "/CN=localhost"

        $contentNginxConfig = @"
worker_processes  1;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;

    keepalive_timeout  65;

    server {
		listen $port ssl;
        server_name  localhost;

        ssl_certificate      C:\localhost.crt;
        ssl_certificate_key  C:\localhost.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
"@

        Set-Content -Path "C:\nginx-${version}\conf\nginx.conf" -Value $contentNginxConfig -Force 
    } else {
        $filePath = "C:\nginx-${version}\conf\nginx.conf"
        $fileContent = Get-Content -Path $filePath
        $fileContent = $fileContent -replace 'listen       80', "listen       $port"
        $fileContent = $fileContent -replace 'server_name  localhost:80', "server_name  localhost:$port"
        $fileContent | Set-Content -Path $filePath
    }
    
    Write-Host "Iniciando Nginx..."
    Set-Location "C:\nginx-${version}"
    start .\nginx.exe

    Write-Host "Configurando el firewall..."
    New-NetFirewallRule -DisplayName "Allow Apache Port $port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow *> $null

    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
    if ($isHTTPS) {
        Write-Host "Puede acceder a su servidor en https://localhost:$port (servidor local) o https://${ipAddress}:${port} (cualquier dispositivo en la red local)"
    } else {
        Write-Host "Puede acceder a su servidor en http://localhost:$port (servidor local) o http://${ipAddress}:${port} (cualquier dispositivo en la red local)"
    }

    Set-Location "C:\"
}

function isValidPort {
    param (
        [string]$port
    )

    $portValid = [int]::TryParse($port, [ref]$null)

    if (-not $portValid) {
        Write-Host "El puerto no es valido. Debe ser un numero entero entre 1 y 65535"
        return $false
    }

    if (([int]$port -lt 1) -or ([int]$port -gt 65535)) {
        Write-Host "El puerto no es valido. Debe ser un numero entero entre 1 y 65535"
        return $false
    }

    $reservedPorts = @(1,7,9,11,13,15,17,19,20,21,22,23,25,37,42,43,53,69,77,79,87,95,101,102,103,104,109,110,111,113,115,117,118,119,123,135,137,139,143,161,177,179,389,427,445,465,512,513,514,515,526,530,531,532,540,548,554,556,563,587,601,636,989,990,993,995,1723,2049,6667)

    if ($reservedPorts -contains [int]$port) {
        Write-Host "El puerto $port está reservado para otro servicio y no se puede usar"
        return $false
    }

    $port = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($port) {
        Write-Host "El puerto ya esta en uso"
        return $false
    }

    return $true
}

function getPort {
    do {
        $port = Read-Host "Ingrese el puerto en el que se hara la configuracion (1-65535)"

        if (isValidPort $port) {
            return [int]$Port
        }
    } while ($true)
}

function downloadService {
    param (
        [string]$service,
        [string]$version,
        [string]$url
    )

    (New-Object System.Net.WebClient).DownloadFile($url, "C:\${service}-${version}.zip")

    if ($?) {
        Write-Host "Descarga completada"
        $port = getPort

        if ($service -eq "apache") {
            installApache $version $port
        } elseif ($service -eq "nginx") {
            installNginx $version $port
        }
    } else {
        Write-Host "Ocurrio un error en la descarga"
    }
}

function downloadVersion {
    param (
        [string]$version
    )

    if ($service -eq "1") {
        $url = "https://www.apachelounge.com/download/VS17/binaries/httpd-${version}-250207-win64-VS17.zip"
    } elseif ($service -eq "3") {
        $url = "https://nginx.org/download/nginx-${version}.zip"
    }

    Write-Host "Se descargara la version $version desde $url, ¿Desea continuar? (s/n)"
    $res = Read-Host "Ingrese su respuesta"

    if ($res -eq "s") {
        if ($service -eq "1") {
            downloadService "apache" $version $url
        } elseif ($service -eq "3") {
            downloadService "nginx" $version $url
        }
    } else {
        Write-Host "Descarga cancelada"
    }
}

function showVersionsFTPMenu {
    param (
        [string]$service,
        [bool]$isSSL
    )

    do {
        Write-Host "¿Que version desea instalar?"

        if ($service -eq "Apache") {
            Write-Host "1. 2.4.63"
            Write-Host "2. Salir"
        } elseif ($service -eq "Nginx") {
            Write-Host "1. 1.26.3"
            Write-Host "2. 1.27.4"
            Write-Host "3. Salir"
        }

        $opt = Read-Host "Ingrese el numero de la version a instalar"

        if ($opt -eq "1") {
            if ($service -eq "Apache") {
                if ($isSSL) {
                    downloadFTPSFile -ftpFilePath "/Instaladores/Apache/httpd-2.4.63-250207-win64-VS17.zip" -destinationPath "C:\apache-2.4.63.zip"
                } else {
                    downloadFTPFile -ftpFilePath "/Instaladores/Apache/httpd-2.4.63-250207-win64-VS17.zip" -destinationPath "C:\apache-2.4.63.zip"
                }
                $port = getPort
                installApache "2.4.63" $port
            } elseif ($service -eq "Nginx") {
                if ($isSSL) {
                    downloadFTPSFile -ftpFilePath "/Instaladores/Nginx/nginx-1.26.3.zip" -destinationPath "C:\nginx-1.26.3.zip"
                } else {
                    downloadFTPFile -ftpFilePath "/Instaladores/Nginx/nginx-1.26.3.zip" -destinationPath "C:\nginx-1.26.3.zip"
                }
                $port = getPort
                installNginx "1.26.3" $port
            }

            return
        } elseif ($opt -eq "2") {
            if ($service -eq "Apache") {
                return
            } elseif ($service -eq "Nginx") {
                if ($isSSL) {
                    downloadFTPSFile -ftpFilePath "/Instaladores/Nginx/nginx-1.27.4.zip" -destinationPath "C:\nginx-1.27.4.zip"
                } else {
                    downloadFTPFile -ftpFilePath "/Instaladores/Nginx/nginx-1.27.4.zip" -destinationPath "C:\nginx-1.27.4.zip"
                }
                $port = getPort
                installNginx "1.27.4" $port
            }

            return
        } elseif ($opt -eq "3") {
            if ($service -eq "Nginx") {
                return
            } else {
                Write-Host "Opción no válida"
            }
        } else {
            Write-Host "Opción no válida"
        }

    } while ($true)
}

function showServicesFTPMenu {
    param (
        [string]$service
    )

    do {
        Write-Host "¿Que servicio desea instalar?"
        Write-Host "1. Apache"
        Write-Host "2. Nginx"
        Write-Host "3. Salir"
        $service = Read-Host "Ingrese el numero del servicio a instalar"

        if ($service -eq "1") {
            if (-not (isApacheInstalled)) {
                return $service
            } else {
                Write-Host "Apache ya esta instalado y configurado. Seleccione otro servicio"
            }
        } elseif ($service -eq "2") {
            if (-not (isNginxInstalled)) {
                return $service
            } else {
                Write-Host "Nginx ya esta instalado y configurado. Seleccione otro servicio"
            }
        } elseif ($service -eq "3") {
            Write-Host "Automatas System agradece su preferencia"
            exit
        } else {
            Write-Host "Opción no válida"
        }
    } while ($true)
}

function showVersionsMenu {
    param (
        [string]$lts,
        [string]$dev
    )

    do {
        Write-Host "¿Que version desea instalar?"
        Write-Host "1. Ultima version LTS: $lts"
        Write-Host "2. Ultima version de desarrollo: $dev"
        Write-Host "3. Regresar"
        $opt = Read-Host "Ingrese el numero de la version a instalar"

        if ($opt -eq "1") {
            downloadVersion $lts
            return
        } elseif ($opt -eq "2") {
            downloadVersion $dev
            return
        } elseif ($opt -eq "3") {
            return
        } else {
            Write-Host "Opción no válida"
        }
    } while ($true)
}

function downloadApache {
    Invoke-WebRequest -Uri "https://httpd.apache.org/download.cgi" -OutFile "apache.html"

    $apachePageContent = Get-Content -Path "apache.html" -Raw
    $lts = [regex]::Match($apachePageContent, '<h1 id="apache24">Apache HTTP Server ([\d.]+)').Groups[1].Value

    showVersionsMenu $lts $lts
}

function downloadNginx {
    Invoke-WebRequest -Uri "https://nginx.org/en/download.html" -OutFile "nginx.html"

    $nginxPageContent = Get-Content -Path "nginx.html" -Raw
    $downloadLinks = [regex]::Matches($nginxPageContent, '<a href="(/download/nginx-\d+\.\d+\.\d+\.zip)">nginx/Windows-\d+\.\d+\.\d+</a>') | ForEach-Object {
        [PSCustomObject]@{
            Url = "https://nginx.org" + $_.Groups[1].Value
            Version = ($_.Groups[1].Value -replace '/download/nginx-', '') -replace '\.zip', ''
        }
    }

    $sortedVersions = $downloadLinks | Sort-Object { [version]$_.Version } -Descending

    $dev = $sortedVersions[0].Version
    $lts = $sortedVersions[1].version

    showVersionsMenu $lts $dev
}

function isApacheInstalled {
    if (Test-Path "C:\Apache24") {
        return $true
    } else {
        return $false
    }
}

function isIISInstalled {
    if (Get-WindowsFeature -Name Web-Server | Where-Object { $_.Installed -eq $true }) {
        return $false
    } else {
        return $false
    }
}

function isNginxInstalled {
    if (Test-Path "C:\nginx-*") {
        return $true
    } else {
        return $false
    }
}

function showServicesWebMenu {
    param (
        [string]$service
    )

    do {
        Write-Host "¿Que servicio desea instalar?"
        Write-Host "1. Apache"
        Write-Host "2. IIS"
        Write-Host "3. Nginx"
        Write-Host "4. Salir"
        $service = Read-Host "Ingrese el numero del servicio a instalar"

        if ($service -eq "1") {
            if (-not (isApacheInstalled)) {
                return $service
            } else {
                Write-Host "Apache ya esta instalado y configurado. Seleccione otro servicio"
            }
        } elseif ($service -eq "2") {
            if (-not (isIISInstalled)) {
                $port = getPort
                installIIS $port
            } else {
                Write-Host "IIS ya esta instalado y configurado. Seleccione otro servicio"
            }
        } elseif ($service -eq "3") {
            if (-not (isNginxInstalled)) {
                return $service
            } else {
                Write-Host "Nginx ya esta instalado y configurado. Seleccione otro servicio"
            }
        } elseif ($service -eq "4") {
            Write-Host "Automatas System agradece su preferencia"
            exit
        } else {
            Write-Host "Opción no válida"
        }
    } while ($true)
}

function showFTPMenu {
    do {
        $res = Read-Host "¿Desea implementar un certificado SSL en el servidor FTP? (s/n)"
    } while ($res -ne "s" -and $res -ne "n" -and $res -ne "S" -and $res -ne "N")

    if ($res -eq "s" -or $res -eq "S") {
        installFTP -installSSL $true
    } else {
        installFTP -installSSL $false
    }
}

function showMethodsMenu {
    Write-Host "¿Que metodo desea utilizar?"
    Write-Host "1. Descarga por la web"
    Write-Host "2. Descarga por FTP/FTPS"
    Write-Host "3. Salir"
    $method = Read-Host "Ingrese el numero del metodo que desea utilizar"

    switch ($method) {
        1 {
            $service = showServicesWebMenu
            if ($service -eq "1") {
                downloadApache
            } elseif ($service -eq "3") {
                downloadNginx
            }
        }
        2 {
            if ((Get-NetFirewallRule -DisplayName "FTP" -ErrorAction SilentlyContinue) -or (Get-NetFirewallRule -DisplayName "FTPS" -ErrorAction SilentlyContinue)) {
                $service = showServicesFTPMenu

                if (Get-NetFirewallRule -DisplayName "FTP" -ErrorAction SilentlyContinue) {
                    if ($service -eq "1") {
                        showVersionsFTPMenu "Apache" $false
                    } elseif ($service -eq "2") {
                        showVersionsFTPMenu "Nginx" $false
                    }
                } elseif (Get-NetFirewallRule -DisplayName "FTPS" -ErrorAction SilentlyContinue) {
                    if ($service -eq "1") {
                        showVersionsFTPMenu "Apache" $true
                    } elseif ($service -eq "2") {
                        showVersionsFTPMenu "Nginx" $true
                    }
                }
            } else {
                showFTPMenu

                if (Get-NetFirewallRule -DisplayName "FTP" -ErrorAction SilentlyContinue) {
                    if ($service -eq "1") {
                        showVersionsFTPMenu "Apache" $false
                    } elseif ($service -eq "2") {
                        showVersionsFTPMenu "Nginx" $false
                    }
                } elseif (Get-NetFirewallRule -DisplayName "FTPS" -ErrorAction SilentlyContinue) {
                    if ($service -eq "1") {
                        showVersionsFTPMenu "Apache" $true
                    } elseif ($service -eq "2") {
                        showVersionsFTPMenu "Nginx" $true
                    }
                }
            }
        }
        3 {
            Write-Host "Automatas System agradece su preferencia"
            exit
        }
        default {
            Write-Host "Opcion no valida"
        }
    }
}

do {
    showMethodsMenu
} while ($true)