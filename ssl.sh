# Crear el directorio principal para FTP
sudo mkdir -p /srv/ftp/instaladores

# Crear el usuario FTPUser
#sudo useradd -m -d /srv/ftp/instaladores -s /bin/bash FTPUser

# Establecer la contraseña para FTPUser
#echo "FTPUser:Linux97" | sudo chpasswd

# Crear directorios para cada tipo de servidor
sudo mkdir -p /srv/ftp/instaladores/apache
sudo mkdir -p /srv/ftp/instaladores/tomcat
sudo mkdir -p /srv/ftp/instaladores/nginx

# Asignar propiedad de todos los directorios a FTPUser
#sudo chown -R FTPUser:FTPUser /srv/ftp/instaladores
#sudo chown -R FTPUser:FTPUser /srv/ftp/instaladores/apache
#sudo chown -R FTPUser:FTPUser /srv/ftp/instaladores/tomcat
#sudo chown -R FTPUser:FTPUser /srv/ftp/instaladores/nginx

# Establecer permisos adecuados (lectura, escritura para el propietario, lectura para el grupo)
#sudo chmod -R 750 /srv/ftp/instaladores
#sudo chmod -R 750 /srv/ftp/instaladores/apache
#sudo chmod -R 750 /srv/ftp/instaladores/tomcat
#sudo chmod -R 750 /srv/ftp/instaladores/nginx

# Cambiar al directorio de Apache
cd /srv/ftp/instaladores/apache

# Descargar Apache
#sudo -u FTPUser wget https://dlcdn.apache.org/httpd/httpd-2.4.63.tar.gz
sudo wget https://dlcdn.apache.org/httpd/httpd-2.4.63.tar.gz

# Cambiar al directorio de Tomcat
cd /srv/ftp/instaladores/tomcat

# Descargar Tomcat
#sudo -u FTPUser wget https://dlcdn.apache.org/tomcat/tomcat-11/v11.0.5/bin/apache-tomcat-11.0.5.tar.gz
#sudo -u FTPUser wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.39/bin/apache-tomcat-10.1.39.tar.gz
sudo wget https://dlcdn.apache.org/tomcat/tomcat-11/v11.0.5/bin/apache-tomcat-11.0.5.tar.gz
sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.39/bin/apache-tomcat-10.1.39.tar.gz


# Cambiar al directorio de Nginx
cd /srv/ftp/instaladores/nginx

# Descargar Nginx
#sudo -u FTPUser wget https://nginx.org/download/nginx-1.27.4.tar.gz
#sudo -u FTPUser wget https://nginx.org/download/nginx-1.26.3.tar.gz
sudo wget https://nginx.org/download/nginx-1.27.4.tar.gz
sudo wget https://nginx.org/download/nginx-1.26.3.tar.gz