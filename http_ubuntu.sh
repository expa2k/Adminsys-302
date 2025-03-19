#!/bin/bash

# Función para verificar si un valor es un número entero
function entero() {
    local valor=$1
    if [[ "$valor" =~ ^[0-9]+$ ]]; then
        return 0
    else    
        return 1
    fi
}

# Función para verificar si un puerto es válido
function puerto() {
    local puerto=$1
    if [[ "$puerto" -ge 1 && "$puerto" -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# Función para bloquear puertos comunes
function bloquear_puertos_comunes() {
    local puerto=$1
    case $puerto in
        20|21|22|23|25|53|67|68|80|110|119|123|143|161|162|339|443|3306|3389)
            echo "El puerto $puerto está reservado para servicios comunes (FTP, SSH, HTTP, etc.)."
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Función para obtener la versión LTS o de desarrollo
function obtenerVersiones() {
    local url=$1
    local index=${2:-0}
    readarray -t versions < <(curl -s "$url" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | sort -V -r | uniq)
    echo "${versions[$index]}"
}

# Función para instalar Apache
function instalarApache() {
    local version=$1
    local puerto=$2

    echo "Instalando Apache versión $version en el puerto $puerto..."
    sudo apt update
    sudo apt install -y apache2
    sudo systemctl stop apache2
    sudo sed -i "s/Listen 80/Listen $puerto/g" /etc/apache2/ports.conf
    sudo systemctl start apache2
    echo "Apache instalado y configurado en el puerto $puerto."
}

# Función para instalar Tomcat
function instalarTomcat() {
    local version=$1
    local puerto=$2

    echo "Instalando Tomcat versión $version en el puerto $puerto..."
    sudo apt update
    sudo apt install -y default-jdk
    wget "https://downloads.apache.org/tomcat/tomcat-9/v$version/bin/apache-tomcat-$version.tar.gz"
    tar -xzf apache-tomcat-$version.tar.gz
    sudo mv apache-tomcat-$version /opt/tomcat
    sudo sed -i "s/port=\"8080\"/port=\"$puerto\"/g" /opt/tomcat/conf/server.xml
    sudo /opt/tomcat/bin/startup.sh
    echo "Tomcat instalado y configurado en el puerto $puerto."
}

# Función para instalar Nginx
function instalarNginx() {
    local version=$1
    local puerto=$2

    echo "Instalando Nginx versión $version en el puerto $puerto..."
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl stop nginx
    sudo sed -i "s/listen 80/listen $puerto/g" /etc/nginx/sites-available/default
    sudo systemctl start nginx
    echo "Nginx instalado y configurado en el puerto $puerto."
}

# Menú principal
while true; do
    echo "=============================================="
    echo "==================== MENU ===================="
    echo "=============================================="
    echo "¿Qué servicio desea instalar?"
    echo "1. Apache"
    echo "2. Tomcat"
    echo "3. Nginx"
    echo "4. Salir"
    echo "Selecciona una opción:"
    read opcion

    case "$opcion" in
        "1")
            echo "Versiones disponibles de Apache:"
            versionLTS=$(obtenerVersiones "https://httpd.apache.org/download.cgi" 0)
            versionDev=$(obtenerVersiones "https://httpd.apache.org/download.cgi" 1)
            echo "1. Última versión LTS: $versionLTS"
            echo "2. Versión de desarrollo: $versionDev"
            echo "Selecciona una versión:"
            read versionOpcion

            if [[ "$versionOpcion" == "1" ]]; then
                version=$versionLTS
            elif [[ "$versionOpcion" == "2" ]]; then
                version=$versionDev
            else
                echo "Opción inválida."
                continue
            fi

            read -p "Ingresa el puerto para Apache: " puerto
            if ! bloquear_puertos_comunes "$puerto"; then
                continue
            fi
            instalarApache "$version" "$puerto"
            ;;
        "2")
            echo "Versiones disponibles de Tomcat:"
            versionLTS=$(obtenerVersiones "https://tomcat.apache.org/download-90.cgi" 0)
            versionDev=$(obtenerVersiones "https://tomcat.apache.org/download-90.cgi" 1)
            echo "1. Última versión LTS: $versionLTS"
            echo "2. Versión de desarrollo: $versionDev"
            echo "Selecciona una versión:"
            read versionOpcion

            if [[ "$versionOpcion" == "1" ]]; then
                version=$versionLTS
            elif [[ "$versionOpcion" == "2" ]]; then
                version=$versionDev
            else
                echo "Opción inválida."
                continue
            fi

            read -p "Ingresa el puerto para Tomcat: " puerto
            if ! bloquear_puertos_comunes "$puerto"; then
                continue
            fi
            instalarTomcat "$version" "$puerto"
            ;;
        "3")
            echo "Versiones disponibles de Nginx:"
            versionLTS=$(obtenerVersiones "https://nginx.org/en/download.html" 0)
            versionDev=$(obtenerVersiones "https://nginx.org/en/download.html" 1)
            echo "1. Última versión LTS: $versionLTS"
            echo "2. Versión de desarrollo: $versionDev"
            echo "Selecciona una versión:"
            read versionOpcion

            if [[ "$versionOpcion" == "1" ]]; then
                version=$versionLTS
            elif [[ "$versionOpcion" == "2" ]]; then
                version=$versionDev
            else
                echo "Opción inválida."
                continue
            fi

            read -p "Ingresa el puerto para Nginx: " puerto
            if ! bloquear_puertos_comunes "$puerto"; then
                continue
            fi
            instalarNginx "$version" "$puerto"
            ;;
        "4")
            echo "Saliendo del programa."
            exit 0
            ;;
        *)
            echo "Opción inválida, por favor seleccione una opción correcta."
            ;;
    esac
done