#!/bin/bash

# Script para configurar Docker, Apache y PostgreSQL
# Creado: Mayo, 2025

echo "==== Iniciando configuración de Docker, Apache y PostgreSQL ===="

# Comprobar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script requiere privilegios de superusuario."
  echo "Por favor ejecuta: sudo bash $0"
  exit 1
fi

# Variables de configuración
USUARIO_ACTUAL=$(logname || echo $SUDO_USER || echo $USER)
APACHE_PUERTO=8080
APACHE_PERSONALIZADO_PUERTO=8081
POSTGRES1_PUERTO=5432
POSTGRES2_PUERTO=5433
POSTGRES_PASSWORD="secreto"
POSTGRES_USER="usuario"
POSTGRES_DB="midb"

echo "==== 1. Instalando Docker en Ubuntu ===="
# Actualizar repositorios
apt-get update

# Instalar dependencias necesarias
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Añadir la clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Añadir el repositorio de Docker
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Actualizar la base de datos de paquetes
apt-get update

# Instalar Docker CE (Community Edition)
apt-get install -y docker-ce docker-ce-cli containerd.io

# Verificar que Docker está instalado correctamente
echo "Verificando la instalación de Docker..."
docker run --rm hello-world

# Agregar usuario al grupo docker para ejecutar comandos sin sudo
usermod -aG docker $USUARIO_ACTUAL
echo "Usuario $USUARIO_ACTUAL añadido al grupo docker."

echo "==== 2. Buscando e instalando una imagen de Apache ===="
# Buscar imágenes de Apache disponibles
docker search httpd

# Descargar la imagen oficial de Apache
docker pull httpd:latest

# Verificar que la imagen se descargó correctamente
docker images | grep httpd

# Limpiar contenedores existentes con el mismo nombre si existen
docker rm -f mi-apache 2>/dev/null || true
docker rm -f mi-apache-mod 2>/dev/null || true
docker rm -f apache-custom 2>/dev/null || true

# Ejecutar un contenedor con la imagen de Apache
docker run -d --name mi-apache -p $APACHE_PUERTO:80 httpd:latest
echo "Apache desplegado en http://localhost:$APACHE_PUERTO"

echo "==== 3. Modificando la imagen para cambiar el contenido de la página inicial ===="
# Crear un directorio local para nuestro contenido personalizado
mkdir -p /home/$USUARIO_ACTUAL/contenido-apache
echo "<html><body><h1>Mi Página Apache Personalizada</h1><p>Esta es mi configuración personalizada de Apache en Docker.</p></body></html>" > /home/$USUARIO_ACTUAL/contenido-apache/index.html

# Detener y eliminar el contenedor anterior
docker stop mi-apache
docker rm mi-apache

# Ejecutar un nuevo contenedor montando nuestro contenido personalizado
docker run -d --name mi-apache-mod -p $APACHE_PUERTO:80 -v /home/$USUARIO_ACTUAL/contenido-apache:/usr/local/apache2/htdocs/ httpd:latest
echo "Apache con contenido modificado desplegado en http://localhost:$APACHE_PUERTO"

echo "==== 4. Creando una imagen personalizada con el archivo index modificado ===="
# Crear un directorio para nuestro Dockerfile
mkdir -p /home/$USUARIO_ACTUAL/apache-personalizado
cd /home/$USUARIO_ACTUAL/apache-personalizado

# Crear el archivo index.html personalizado
echo "<html><body><h1>Imagen Apache Personalizada</h1><p>Esta es una imagen personalizada de Apache construida con Docker.</p></body></html>" > index.html

# Crear el Dockerfile
cat > Dockerfile << 'EOF'
FROM httpd:latest
COPY index.html /usr/local/apache2/htdocs/
EXPOSE 80
EOF

# Construir la imagen personalizada
docker build -t mi-apache-personalizado:v1 .

# Ejecutar un contenedor con nuestra imagen personalizada
docker run -d --name apache-custom -p $APACHE_PERSONALIZADO_PUERTO:80 mi-apache-personalizado:v1
echo "Apache personalizado desplegado en http://localhost:$APACHE_PERSONALIZADO_PUERTO"

echo "==== 5. Configurando comunicación entre contenedores con PostgreSQL ===="
# Limpiar contenedores existentes con el mismo nombre si existen
docker rm -f postgres1 2>/dev/null || true
docker rm -f postgres2 2>/dev/null || true

# Eliminar la red si ya existe
docker network rm mi-red-postgres 2>/dev/null || true

# Crear una red Docker
docker network create mi-red-postgres
echo "Red Docker 'mi-red-postgres' creada."

# Ejecutar el primer contenedor PostgreSQL
docker run -d --name postgres1 \
    --network mi-red-postgres \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_DB=$POSTGRES_DB \
    -p $POSTGRES1_PUERTO:5432 \
    postgres:latest
echo "Primer contenedor PostgreSQL (postgres1) desplegado en el puerto $POSTGRES1_PUERTO."

# Ejecutar el segundo contenedor PostgreSQL
docker run -d --name postgres2 \
    --network mi-red-postgres \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_DB=$POSTGRES_DB \
    -p $POSTGRES2_PUERTO:5432 \
    postgres:latest
echo "Segundo contenedor PostgreSQL (postgres2) desplegado en el puerto $POSTGRES2_PUERTO."

# Esperar a que los contenedores PostgreSQL estén listos
echo "Esperando a que los contenedores PostgreSQL estén completamente iniciados..."
sleep 15

# Crear tabla de prueba en postgres1
echo "Creando tabla de prueba en postgres1..."
docker exec -it postgres1 bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'CREATE TABLE prueba (id serial PRIMARY KEY, nombre VARCHAR(50));'"
docker exec -it postgres1 bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"INSERT INTO prueba (nombre) VALUES ('Datos de prueba desde postgres1');\""

# Verificar que la tabla se creó correctamente
echo "Verificando que la tabla se creó correctamente en postgres1:"
docker exec -it postgres1 bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT * FROM prueba;'"

# Instalar cliente PostgreSQL en postgres2 para conectarse a postgres1
echo "Configurando postgres2 para conectarse a postgres1..."
docker exec -it postgres2 bash -c "apt-get update && apt-get install -y postgresql-client"

# Conectar desde postgres2 al postgres1
echo "Verificando conexión desde postgres2 a postgres1:"
docker exec -it postgres2 bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -h postgres1 -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT * FROM prueba;'"

# Insertar datos desde postgres2 a postgres1
echo "Insertando datos desde postgres2 a la tabla en postgres1:"
docker exec -it postgres2 bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -h postgres1 -U $POSTGRES_USER -d $POSTGRES_DB -c \"INSERT INTO prueba (nombre) VALUES ('Datos de prueba desde postgres2');\""

# Verificar los datos insertados
echo "Verificando todos los datos en la tabla:"
docker exec -it postgres1 bash -c "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT * FROM prueba;'"

echo ""
echo "====== CONFIGURACIÓN COMPLETADA ======"
echo "Apache estándar: http://localhost:$APACHE_PUERTO"
echo "Apache personalizado: http://localhost:$APACHE_PERSONALIZADO_PUERTO"
echo "PostgreSQL 1: localhost:$POSTGRES1_PUERTO (usuario: $POSTGRES_USER, contraseña: $POSTGRES_PASSWORD, BD: $POSTGRES_DB)"
echo "PostgreSQL 2: localhost:$POSTGRES2_PUERTO (usuario: $POSTGRES_USER, contraseña: $POSTGRES_PASSWORD, BD: $POSTGRES_DB)"
echo ""
echo "Nota: Para utilizar Docker sin privilegios de superusuario, cierra sesión y vuelve a iniciar sesión"
echo "o ejecuta 'newgrp docker' en tu terminal actual."
