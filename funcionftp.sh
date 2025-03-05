#!/bin/bash

# Función para instalar y configurar FTP
instalar_ftp() {
    echo "Instalando servidor FTP..."
    sudo apt update
    sudo apt install -y vsftpd
    sudo systemctl enable vsftpd
    sudo systemctl start vsftpd
    echo "Configuración básica aplicada."
}

# Función para crear grupos
crear_grupos() {
    echo "Creando grupos reprobados y recursadores..."
    sudo groupadd reprobados 2>/dev/null
    sudo groupadd recursadores 2>/dev/null
}

# Función para agregar usuario y asignarlo a un grupo
agregar_usuario() {
    read -p "Ingrese el nombre del usuario: " username
    read -p "Seleccione grupo (1: reprobados, 2: recursadores): " group_choice
    
    if [ "$group_choice" == "1" ]; then
        group="reprobados"
    elif [ "$group_choice" == "2" ]; then
        group="recursadores"
    else
        echo "Opción inválida."; return 1
    fi

    sudo useradd -m -g "$group" -s /bin/bash "$username"
    sudo passwd "$username"
    
    # Crear carpetas personales del usuario
    sudo mkdir -p /srv/ftp/usuarios/$username
    sudo chown "$username":"$group" /srv/ftp/usuarios/$username
    sudo chmod 770 /srv/ftp/usuarios/$username
    
    echo "Usuario $username agregado al grupo $group."
}

# Función para configurar los directorios y montajes
configurar_directorios() {
    echo "Configurando directorios para usuarios FTP..."
    sudo mkdir -p /srv/ftp/general /srv/ftp/grupos/reprobados /srv/ftp/grupos/recursadores /srv/ftp/usuarios
    sudo chmod 777 /srv/ftp/general
    sudo chmod 770 /srv/ftp/grupos/reprobados
    sudo chmod 770 /srv/ftp/grupos/recursadores
    
    for user in $(ls /srv/ftp/usuarios); do
        group=$(id -gn $user)
        sudo mkdir -p /home/$user/ftp/{mi_carpeta,mi_grupo,publica}
        sudo mount --bind /srv/ftp/usuarios/$user /home/$user/ftp/mi_carpeta
        sudo mount --bind /srv/ftp/grupos/$group /home/$user/ftp/mi_grupo
        sudo mount --bind /srv/ftp/general /home/$user/ftp/publica
    done
}

# Función para hacer montajes persistentes
persistir_montajes() {
    echo "Persistiendo montajes en /etc/fstab..."
    for user in $(ls /srv/ftp/usuarios); do
        group=$(id -gn $user)
        echo "/srv/ftp/general /home/$user/ftp/publica none bind 0 0" | sudo tee -a /etc/fstab
        echo "/srv/ftp/grupos/$group /home/$user/ftp/mi_grupo none bind 0 0" | sudo tee -a /etc/fstab
        echo "/srv/ftp/usuarios/$user /home/$user/ftp/mi_carpeta none bind 0 0" | sudo tee -a /etc/fstab
    done
}