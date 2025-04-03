InstalarTomcat() {
    local version=$1
    local port=$2
    local Https=false

    while true; do
        read -p "Quiere usar http con certificado SSL (s/n): " response
        if [[ "$response" == "s" ]]; then
            Https=true
            break
        elif [[ "$response" == "n" ]]; then
            Https=false
            break
        fi
    done

    echo "----------------------------------------------"
    echo "-----------Instalacion de TOMCAT--------------"
    echo "----------------------------------------------"

    echo "Instalando dependencias necesarias para Tomcat..."
    sudo apt update -qq > /dev/null 2>&1
    sudo apt install -y -qq openjdk-17-jdk > /dev/null 2>&1

    echo "Se esta extrayendo el archivo..."
    tar -xvzf "tomcat-${version}.tar.gz" > /dev/null

    echo "Configurando Tomcat..."
    sudo mv "apache-tomcat-${version}" /opt/tomcat
    sudo chown -R $USER:$USER /opt/tomcat
    sudo chmod +x /opt/tomcat/bin/*.sh

    echo "Configurando Tomcat en el puerto $port..."
    if [[ "$Https" == true ]]; then
        echo "Configurando SSL en Tomcat..."
        sudo mkdir -p /opt/tomcat/conf/ssl
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /opt/tomcat/conf/ssl/privkey.pem \
            -out /opt/tomcat/conf/ssl/cert.pem \
            -subj "/CN=localhost"

        sudo sed -i '/<Service name="Catalina">/a \
        <Connector port="'"$port"'" protocol="org.apache.coyote.http11.Http11NioProtocol" \
           maxThreads="150" SSLEnabled="true"> \
    <SSLHostConfig> \
        <Certificate certificateFile="/opt/tomcat/conf/ssl/cert.pem" \
                     certificateKeyFile="/opt/tomcat/conf/ssl/privkey.pem" \
                     type="RSA" /> \
    </SSLHostConfig> \
</Connector>' /opt/tomcat/conf/server.xml

    else
        sudo sed -i "s/<Connector port=\"8080\"/<Connector port=\"$port\"/g" /opt/tomcat/conf/server.xml
    fi

    echo "Inicializando Tomcat..."
    /opt/tomcat/bin/startup.sh > /dev/null

    echo "Configurando el firewall(ufw)..."
    sudo ufw allow "$port/tcp" > /dev/null 2>&1
    sudo ufw --force enable > /dev/null 2>&1

    echo "----------------------------------------------"
    echo "-----Instalacion de TOMCAT Finalizada---------"
    echo "----------------------------------------------"

    echo "Tomcat $version instalado y configurado en el puerto $port."

    if [[ "$Https" == true ]]; then
    echo "Servidor seguro listo en:"
        echo "https://localhost:$port (local)" 
        echo "o"
        echo "https://$(hostname -I | cut -d ' ' -f 1):$port (puede acceder con cualquier dispositivo que se encuentre en la red local)"
    else
    echo "Servidor normal listo en:"
    echo "http://localhost:$port" 
    echo "o" 
    echo "http://$(hostname -I | cut -d ' ' -f 1):$port (puede acceder con cualquier dispositivo que se encuentre en la red local)"
    fi
}

InstalarNginx() {
    local version=$1
    local port=$2
    local Https=false

    echo "----------------------------------------------"
    echo "-----------Instalacion de NGINX---------------"
    echo "----------------------------------------------"

    while true; do
        read -p "Quiere usar http con certificado SSL (s/n): " res
        if [[ "$response" == "s" ]]; then
            Https=true
            break
        elif [[ "$response" == "n" ]]; then
            Https=false
            break
        fi
    done

    echo "Instalando dependencias necesarias para Nginx..."
    sudo apt update -qq > /dev/null 2>&1
    sudo apt install -y -qq build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev > /dev/null 2>&1

    echo "Se esta extrayendo el archivo..."
    tar -xvzf "nginx-${version}.tar.gz" > /dev/null  
    cd "nginx-${version}"

    echo "Configurando Nginx..."
    if [[ "$Https" == true ]]; then
        ./configure --prefix=/usr/local/nginx --with-http_ssl_module > /dev/null
    else
        ./configure --prefix=/usr/local/nginx > /dev/null
    fi 
    make > /dev/null  
    sudo make install > /dev/null  

    echo "Configurando Nginx en el puerto $port..."
    if [[ "$Https" == true ]]; then
        echo "Configurando NGINX para usar SSL..."
        sudo mkdir -p /usr/local/nginx/conf/ssl
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /usr/local/nginx/conf/ssl/privkey.pem \
            -out /usr/local/nginx/conf/ssl/cert.pem \
            -subj "/CN=localhost"

        sudo bash -c 'cat > /usr/local/nginx/conf/nginx.conf <<EOF
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    server {
        listen       '"$port"' ssl;
        ssl_certificate      /usr/local/nginx/conf/ssl/cert.pem;
        ssl_certificate_key  /usr/local/nginx/conf/ssl/privkey.pem;

        root         /usr/local/nginx/html;
        index        index.html;
    }
}
EOF'
    else
        sudo sed -i "s/listen\s*80;/listen $port;/g" /usr/local/nginx/conf/nginx.conf
    fi

    echo "Inicializando Nginx..."
    sudo /usr/local/nginx/sbin/nginx > /dev/null  

    echo "Configurando el firewall(ufw)..."
    sudo ufw allow "$port/tcp" > /dev/null 2>&1
    sudo ufw --force enable > /dev/null 2>&1

    echo "----------------------------------------------"
    echo "-------Instalacion de NGINX Finalizado--------"
    echo "----------------------------------------------"

    echo "Nginx $version instalado y configurado en el puerto $port."
    if [[ "$Https" == true ]]; then
        echo "Servidor seguro listo en:"
        echo "https://localhost:$port" 
        echo "o" 
        echo "https://$(hostname -I | cut -d ' ' -f 1):$port (puede acceder con cualquier dispositivo que se encuentre en la red local)"
    else
        echo "Servidor normal listo en:"
        echo "http://localhost:$port (local)" 
        echo "o" 
        echo "http://$(hostname -I | cut -d ' ' -f 1):$port (puede acceder con cualquier dispositivo que se encuentre en la red local)"
    fi
}

InstalarApache() {
    local version=$1
    local port=$2
    local Https=false

    echo "--------------------------------------------------"
    echo "-------------Instalacion de APACHE----------------"
    echo "--------------------------------------------------"

    while true; do
        read -p "Quiere usar http con certificado SSL (s/n): " response
        if [[ "$response" == "s" ]]; then
            Https=true
            break
        elif [[ "$response" == "n" ]]; then
            Https=false
            break
        fi
    done

    echo "Instalando dependencias necesarias para Apache..."
    sudo apt update -qq > /dev/null 2>&1
    sudo apt install -y -qq build-essential libpcre3 libpcre3-dev libssl-dev libapr1-dev libaprutil1-dev > /dev/null 2>&1

    echo "Se esta extrayendo el archivo..."
    tar -xvzf "apache-${version}.tar.gz" > /dev/null 2>&1
    cd "httpd-${version}" > /dev/null 2>&1

    echo "Configurando Apache..."
    if [[ "$ssl" == true ]]; then
        sudo ./configure --prefix=/usr/local/apache --enable-so --enable-ssl --with-ssl > /dev/null
    else
        sudo ./configure --prefix=/usr/local/apache --enable-so > /dev/null
    fi
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1

    echo "Configurando Apache en el puerto $port..."
    if [[ "$Https" == true ]]; then
        sudo mkdir -p /usr/local/apache/conf/ssl
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /usr/local/apache/conf/ssl/privkey.pem \
            -out /usr/local/apache/conf/ssl/cert.pem \
            -subj "/CN=localhost"

        sudo bash -c 'cat >> /usr/local/apache/conf/httpd.conf <<EOF
LoadModule ssl_module modules/mod_ssl.so
Listen '"$port"' ssl
<VirtualHost *:'"$port"'>
    SSLEngine on
    SSLCertificateFile /usr/local/apache/conf/ssl/cert.pem
    SSLCertificateKeyFile /usr/local/apache/conf/ssl/privkey.pem
    DocumentRoot "/usr/local/apache/htdocs"
    <Directory "/usr/local/apache/htdocs">
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF'
    else
        sudo sed -i "s/Listen 80/Listen $port/" /usr/local/apache/conf/httpd.conf
    fi

    echo "Inicializando Apache..."
    sudo /usr/local/apache/bin/apachectl start > /dev/null 2>&1

    echo "Configurando el firewall(ufw)..."
    sudo ufw allow "$port/tcp" > /dev/null 2>&1
    sudo ufw --force enable > /dev/null 2>&1

    echo "--------------------------------------------------"
    echo "----------Instalacion de APACHE Finalizada--------"
    echo "--------------------------------------------------"

    echo "Apache HTTP Server $version instalado y configurado en el puerto $port."
    if [[ "$Https" == true ]]; then
        echo "Servidor seguro listo en:"
        echo "https://localhost:$port (Local)" 
        echo "o" 
        echo "https://$(hostname -I | cut -d ' ' -f 1):$port (puede acceder con cualquier dispositivo que se encuentre en la red local)"
    else
        echo "Servidor normal lsito en:"
        echo "http://localhost:$port (Local)" 
        echo "o" 
        echo "http://$(hostname -I | cut -d ' ' -f 1):$port (puede acceder con cualquier dispositivo que se encuentre en la red local)"
    fi
}

isPortInUse() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

isPortValid() {
    local port=$1

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "El puerto no es valido. Debe ser un numero entero entre 1 y 65535 (Sin punto decimal)"
        return 1
    fi

    if ((port < 1 || port > 65535)); then
        echo "El puerto no es valido. Debe ser un numero entero entre 1 y 65535 (Sin punto decimal)"
        return 1
    fi

    local reservedPorts=(
        20 21 22 23 25 53 67 68 69 88 110 123 137 138 139 143 161 162 179 194 389 445 465 500 587 636 853 989 990 993 995
        1194 1723 1812 1813 3306 3389 5432
    )

    for reserved in "${reservedPorts[@]}"; do
        if [[ "$port" -eq "$reserved" ]]; then
            echo "El puerto $port esta reservado para otro servicio y no se puede usar"
            return 1
        fi
    done

    if isPortInUse "$port"; then
        echo "El puerto $port ya esta en uso"
        return 1
    fi

    return 0
}

getPort() {
    while true; do
        read -p "Ingrese el puerto para la configuracion dentro del rango(1-65535): " port

        if isPortValid $port; then
            echo "El puerto $port es valido"
            break
        fi
    done 
}

downloadService() {
    local service=$1
    local version=$2
    local url=$3

    wget -q --show-progress "$url" -O "$service-$version.tar.gz"

    if [[ -f "$service-$version.tar.gz" ]]; then
        echo "Descarga realizada con exito"
        getPort
    else
        echo "Error en la descarga (Trono...)"
    fi
}

downloadVersion() {
    version=$1

    if [[ "$service" == "1" ]]; then
        url="https://dlcdn.apache.org/httpd/httpd-$version.tar.gz"
    elif [[ "$service" == "2" ]]; then
        urlDEV="https://dlcdn.apache.org/tomcat/tomcat-11/v$version/bin/apache-tomcat-$version.tar.gz"
        urlLTS="https://dlcdn.apache.org/tomcat/tomcat-10/v$version/bin/apache-tomcat-$version.tar.gz"

        if wget --spider "$urlDEV" 2>/dev/null; then
            url="$urlDEV"
        elif wget --spider "$urlLTS" 2>/dev/null; then
            url="$urlLTS"
        fi

    elif [[ "$service" == "3" ]]; then
        url="https://nginx.org/download/nginx-$version.tar.gz"
    fi

    echo "Se descargara la version $version desde $url, Desea continuar? (s/n)"
    read -p "Elija su respuesta: " res

    if [[ "$res" == "s" ]]; then
        if [[ "$service" == "1" ]]; then
            downloadService "apache" "$version" "$url"
        elif [[ "$service" == "2" ]]; then
            downloadService "tomcat" "$version" "$url"
        elif [[ "$service" == "3" ]]; then
            downloadService "nginx" "$version" "$url"
        fi
        return 0
    else 
        echo "La descarga ha sido cancelada"
        return 1
    fi
}

showVersionsMenu() {
    local lts=$1
    local dev=$2

    while true; do
        clear
        echo "-----------------------------------------------"
        echo "---------------Menu de Versiones---------------"
        echo "-----------------------------------------------"
        echo "---[1] Ultima version LTS: $1------------"
        echo "---[2] Ultima version de desarrollo: $2---"
        echo "---[3] Regresar--------------------------------"
        read -p "Seleccione una opcion : " opt

        if [[ "$opt" == "1" ]]; then 
            downloadVersion $lts
            if [[ $? -eq 1 ]]; then
                continue
            fi
            return 0
        elif [[ "$opt" == "2" ]]; then
            downloadVersion $dev
            if [[ $? -eq 1 ]]; then
                continue
            fi
            return 0
        elif [[ "$opt" == "3" ]]; then
            return 1
        else 
            echo "La opcion seleccionada no es valida, por favor seleccione de nuevo otra opcion"
        fi
    done 
}

DescargarTomcat() {
    wget -q -O tomcatDEV.html https://tomcat.apache.org/download-11.cgi
    wget -q -O tomcatLTS.html https://tomcat.apache.org/download-10.cgi

    local dev=$(grep -oP '<h3[^>]*>\K[\d.]+(?=</h3>)' tomcatDEV.html)
    local lts=$(grep -oP '<h3[^>]*>\K[\d.]+(?=</h3>)' tomcatLTS.html)

    showVersionsMenu $lts $dev

    if [[ $? -eq 1 ]]; then
        return 1
    fi
}

DescargarApache() {
    wget -q -O apache.html https://httpd.apache.org/download.cgi

    local lts=$(grep -oP '<h1 id="apache24">Apache HTTP Server \K[\d.]+' apache.html)

    showVersionsMenu $lts $lts

    if [[ $? -eq 1 ]]; then
        return 1
    fi
}

DescargarNginx() {
    wget -q -O nginx.html https://nginx.org/en/download.html

    local versions=($(grep -oP 'nginx-\d+\.\d+\.\d+' nginx.html | sort -Vr | uniq))

    local dev=${versions[0]}
    local lts=${versions[1]}

    local dev=$(echo "$dev" | cut -d '-' -f 2)
    local lts=$(echo "$lts" | cut -d '-' -f 2)

    showVersionsMenu $lts $dev

    if [[ $? -eq 1 ]]; then
        return 1
    fi
}

isTomcatInstalled() {
    if [[ -d "/opt/tomcat" ]]; then
        return 0
    else
        return 1
    fi
}

isApacheInstalled() {
    if [[ -d "/usr/local/apache" ]]; then
        return 0
    else
        return 1
    fi
}

isNginxInstalled() {
    if [[ -d "/usr/local/nginx" ]]; then
        return 0
    else
        return 1
    fi
}

installFTP() {
    local FTPS=$1
    local ftpUser="FTPUser"
    local ftpPassword="Linux97"
    local ftpDir="/srv/ftp/instaladores"

    echo "Creando usuario 'FTPUser'..."
    sudo mkdir -p $ftpDir
    sudo useradd -m -d $ftpDir -s /bin/bash FTPUser
    echo "$ftpUser:$ftpPassword" | sudo chpasswd

    echo "Asignando permisos al directorio $ftpDir..."
    sudo chown -R FTPUser:FTPUser $ftpDir
    sudo chmod -R 750 $ftpDir

    sudo mkdir -p "/srv/ftp/instaladores/apache"
    sudo mkdir -p "/srv/ftp/instaladores/tomcat"
    sudo mkdir -p "/srv/ftp/instaladores/nginx"

    sudo chown -R FTPUser:FTPUser "/srv/ftp/instaladores/apache"
    sudo chmod -R 750 "/srv/ftp/instaladores/apache"
    sudo chown -R FTPUser:FTPUser "/srv/ftp/instaladores/tomcat"
    sudo chmod -R 750 "/srv/ftp/instaladores/tomcat"
    sudo chown -R FTPUser:FTPUser "/srv/ftp/instaladores/nginx"
    sudo chmod -R 750 "/srv/ftp/instaladores/nginx"

    echo "Configurando el servidor FTP..."

    sudo apt update
    sudo apt install -y vsftpd openssl

    if [[ "$FTPS" == "YES" ]]; then
        echo "Generando certificado SSL..."
        sudo mkdir -p /etc/vsftpd/ssl
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/vsftpd/ssl/vsftpd.key \
            -out /etc/vsftpd/ssl/vsftpd.crt \
            -subj "/C=US/ST=State/L=City/O=Company/OU=IT/CN=localhost"
    fi

    sudo bash -c 'cat > /etc/vsftpd.conf' <<EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
file_open_mode=0644

dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
user_sub_token=\$USER

chroot_local_user=YES
allow_writeable_chroot=YES
local_root=$ftpDir

pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
EOF

    if [[ "$FTPS" == "YES" ]]; then
        sudo bash -c 'cat >> /etc/vsftpd.conf' <<EOF
listen_port=990
implicit_ssl=YES
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/vsftpd/ssl/vsftpd.crt
rsa_private_key_file=/etc/vsftpd/ssl/vsftpd.key
EOF
    fi
    
    sudo systemctl restart vsftpd
    sudo systemctl enable vsftpd

    sudo ufw allow 20/tcp
    sudo ufw allow 21/tcp
    sudo ufw allow 40000:50000/tcp
    if [[ "$FTPS" == "YES" ]]; then
        sudo ufw allow 990/tcp
    fi
    sudo ufw reload

    if [[ "$FTPS" == "YES" ]]; then
        echo Servidor FTPS configurado correctamente
    else
        echo Servidor FTP configurado correctamente
    fi
}

showVersionsFTPMenu() {
    local service=$1

    while true; do
        echo "-----Menu de versiones-----"

        if [[ "$service" == "apache" ]]; then
            echo "-----[1] 2.4.63------------"
        elif [[ "$service" == "tomcat" ]]; then
            echo "-----[1] 11.0.5------------"
            echo "-----[2] 10.1.39-----------"
        elif [[ "$service" == "nginx" ]]; then
            echo "-----[1] 1.27.4------------"
            echo "-----[2] 1.26.3------------"
        fi

        read -p "Seleccione una opcion de la version a instalar: " opt

        if [[ "$service" == "apache" ]]; then
            if [[ "$opt" == "1" ]]; then
                if sudo ufw status | grep -q '990/tcp'; then
                    local archivo="apache-2.4.63.tar.gz"
                    curl --insecure -u "FTPUser:L0k0l0k1_" "ftps://localhost/apache/httpd-2.4.63.tar.gz" -o "$archivo"
                    getPort
                    installApache "2.4.63" "$port"
                else
                    local archivo="apache-2.4.63.tar.gz"
                    curl -u "FTPUser:Linux97" "ftp://localhost/apache/httpd-2.4.63.tar.gz" -o "$archivo"
                    getPort
                    installApache "2.4.63" "$port"
                fi
                break
            else 
                echo "La opcion seleccionada no es valida"
            fi
        elif [[ "$service" == "tomcat" ]]; then
            if [[ "$opt" == "1" ]]; then 
                if sudo ufw status | grep -q '990/tcp'; then
                    local archivo="tomcat-11.0.5.tar.gz"
                    curl --insecure -u "FTPUser:Linux97" "ftps://localhost/tomcat/apache-tomcat-11.0.5.tar.gz" -o "$archivo"
                    getPort
                    installTomcat "11.0.5" "$port"
                else
                    local archivo="tomcat-11.0.5.tar.gz"
                    curl -u "FTPUser:Linux97" "ftp://localhost/tomcat/apache-tomcat-11.0.5.tar.gz" -o "$archivo"
                    getPort
                    installTomcat "11.0.5" "$port"
                fi
                break
            elif [[ "$opt" == "2" ]]; then
                if sudo ufw status | grep -q '990/tcp'; then
                    local archivo="tomcat-10.1.39.tar.gz"
                    curl --insecure -u "FTPUser:Linux97" "ftps://localhost/tomcat/apache-tomcat-10.1.39.tar.gz" -o "$archivo"
                    getPort
                    installTomcat "10.1.39" "$port"
                else
                    local archivo="tomcat-10.1.39.tar.gz"
                    curl -u "FTPUser:Linux97" "ftp://localhost/tomcat/apache-tomcat-10.1.39.tar.gz" -o "$archivo"
                    getPort
                    installTomcat "10.1.39" "$port"
                fi
                break
            else 
                echo "La opcion seleccionada no es valida"
            fi
        elif [[ "$service" == "nginx" ]]; then
            if [[ "$opt" == "1" ]]; then 
                if sudo ufw status | grep -q '990/tcp'; then
                    local archivo="nginx-1.27.4.tar.gz"
                    curl --insecure -u "FTPUser:Linux97" "ftps://localhost/nginx/nginx-1.27.4.tar.gz" -o "$archivo"
                    getPort
                    installNginx "1.27.4" "$port"
                else
                    local archivo="nginx-1.27.4.tar.gz"
                    curl -u "FTPUser:Linux97" "ftp://localhost/nginx/nginx-1.27.4.tar.gz" -o "$archivo"
                    getPort
                    installNginx "1.27.4" "$port"
                fi
                break
            elif [[ "$opt" == "2" ]]; then
                if sudo ufw status | grep -q '990/tcp'; then
                    local archivo="nginx-1.26.3.tar.gz"
                    curl --insecure -u "FTPUser:Linux97" "ftps://localhost/nginx/nginx-1.26.3.tar.gz" -o "$archivo"
                    getPort
                    installNginx "1.26.3" "$port"
                else
                    local archivo="nginx-1.26.3.tar.gz"
                    curl -u "FTPUser:Linux97" "ftp://localhost/nginx/nginx-1.26.3.tar.gz" -o "$archivo"
                    getPort
                    installNginx "1.26.3" "$port"
                fi
                break
            else 
                echo "La opcion selecciona no es valida"
            fi
        fi
    done 
}

showServicesMenu() {
    while true; do
        echo "-----------------------------"
        echo "------Menu de Servicios------"
        echo "-----------------------------"
        echo "-------[1] Tomcat------------"
        echo "-------[2] Apache------------"
        echo "-------[3] Nginx-------------"
        echo "-------[4] Salir-------------"
        read -p "Seleccione una opcion: " service

        if [[ "$service" == "1" ]]; then
            if isTomcatInstalled; then
                echo "Tomcat ya esta instalado y configurado." 
                echo "Seleccione otro servicio por favor"
            else
                if DescargarTomcat; then
                    InstalarTomcat "$version" "$port"
                fi
            fi
            break
        elif [[ "$service" == "2" ]]; then
            if isApacheInstalled; then
                echo "Apache ya esta instalado y configurado." 
                echo "Seleccione otro servicio por favor"
            else
                if DescargarApache; then
                    InstalarApache "$version" "$port"
                fi
            fi
            break
        elif [[ "$service" == "3" ]]; then
            if isNginxInstalled; then
                echo "Nginx ya esta instalado y configurado. Seleccione otro servicio"
            else
                if DescargarNginx; then
                    InstalarNginx "$version" "$port"
                fi
            fi
            break
        elif [[ "$service" == "4" ]]; then
            echo "Saliendo de del menu de servicios..."
            exit 0
        else
            echo "La opcion seleccionada no es valida, por favor intentelo de nuevo"
        fi
    done
}

showFTPMenu() {
    while true; do
        read -p "Quiere usar FTP con certificado SSL (s/n): " response

        if [[ "$response" == "s" ]]; then
            installFTP "YES"
            break
        elif [[ "$response" == "n" ]]; then
            installFTP "NO"
            break
        fi
    done
}

showMethodsMenu() {
    while true; do
        echo "----------------Menu de descarga---------------"
        echo "---De que manera desea realizar la descarga:---"
        echo "---[1] Descargar en la Web---------------------"
        echo "---[2] Descargar mediante FTP/FTPS-------------"
        echo "---[3] Salir-----------------------------------"
        read -p "Seleccione una opcion valida para continuar: " method

        if [[ "$method" == "1" ]]; then
            showServicesMenu
        elif [[ "$method" == "2" ]]; then
            if id "FTPUser" &>/dev/null; then
                echo "El usuario FTP ya existe"
                showServicesMenu
            else
            showFTPMenu
            showServicesMenu
            fi
        elif [[ "$method" == "3" ]]; then
            echo "Saliendo del menu de seleccion de descarga..."
            exit 0
        else
            echo "La opcion seleccionada es invalida"
        fi
    done
}

while true; do
    showMethodsMenu
done