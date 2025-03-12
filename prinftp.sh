#!/usr/bin/env bash


source ./funftp.sh

clear

Instalacion_ftp

Creacion_anonimo


echo "Sistema de administracion FTP"

continuar=true
while $continuar
do

echo "Menu principal:"

echo "1- Nuevo grupo"

echo "2- Nuevo usuario"

echo "3- Vincular usuario con grupo"

echo "4- Modificar grupo de usuario"

echo "5- Salir del sistema"


read -p "Seleccione una opcion (1-5): " seleccion

case $seleccion in
 1)
    read -p "Nombre para el nuevo grupo: " equipo
    Creacion_grupo "$grupo"
 ;;
 2)
    read -p "Nombre para el nuevo usuario: " persona
    Creacion_usuario "$persona"
 ;;
 3)
    read -p "Usuario a vincular: " persona
    read -p "Grupo destino: " equipo
    Asignacion_grupo "$persona" "$grupo"
 ;;
 4)
    Cambiar_grupo
 ;;
 5) 
   echo "Saliendo del sistema..."
   continuar=false
 ;;
 *)
   echo "Opcion no valida, intente nuevamente"
 ;;
 esac

done


persona="carlos"
grupo="reprobados123"

existenciauser "$persona"
existenciagrupo "$grupo"