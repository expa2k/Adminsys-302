#!/bin/bash

# Importar las funciones
source Funciones.sh

while true; do
    echo "========================="
    echo "       MENU FTP        "
    echo "========================="
    echo "1) Instalar y configurar FTP"
    echo "2) Crear grupos"
    echo "3) Agregar usuario"
    echo "4) Configurar directorios y montajes"
    echo "5) Hacer montajes persistentes"
    echo "6) Salir"
    read -p "Seleccione una opción: " opcion

    case $opcion in
        1) instalar_ftp ;;
        2) crear_grupos ;;
        3) agregar_usuario ;;
        4) configurar_directorios ;;
        5) persistir_montajes ;;
        6) exit 0 ;;
        *) echo "Opción no válida, intente de nuevo." ;;
    esac
done
