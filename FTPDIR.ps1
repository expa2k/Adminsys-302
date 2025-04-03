# Crear el directorio principal para FTP
New-Item -Path "C:\FTP" -ItemType Directory -Force

# Crear subdirectorios para cada tipo de servidor
New-Item -Path "C:\FTP\Instaladores" -ItemType Directory -Force
New-Item -Path "C:\FTP\Instaladores\Apache" -ItemType Directory -Force
New-Item -Path "C:\FTP\Instaladores\Nginx" -ItemType Directory -Force

# Verificar que los directorios se hayan creado correctamente
Get-ChildItem -Path "C:\FTP" -Recurse

# Descargar Apache
$apacheUrl = "https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250207-win64-VS17.zip"
$apacheOutput = "C:\FTP\Instaladores\Apache\httpd-2.4.63-250207-win64-VS17.zip"
Invoke-WebRequest -Uri $apacheUrl -OutFile $apacheOutput

# Descargar Nginx (versión estable)
$nginxStableUrl = "https://nginx.org/download/nginx-1.26.3.zip"
$nginxStableOutput = "C:\FTP\Instaladores\Nginx\nginx-1.26.3.zip"
Invoke-WebRequest -Uri $nginxStableUrl -OutFile $nginxStableOutput

# Descargar Nginx (versión de desarrollo)
$nginxDevUrl = "https://nginx.org/download/nginx-1.27.4.zip"
$nginxDevOutput = "C:\FTP\Instaladores\Nginx\nginx-1.27.4.zip"
Invoke-WebRequest -Uri $nginxDevUrl -OutFile $nginxDevOutput

# Verificar que los archivos se hayan descargado correctamente
Get-ChildItem -Path "C:\FTP\Instaladores" -Recurse