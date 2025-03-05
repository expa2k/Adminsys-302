#!/bin/bash

# Función para instalar y configurar FTP
instalar_ftp() {
    echo "Instalando servidor FTP..."
    sudo apt update && sudo apt install -y vsftpd

    # Habilitar y arrancar el servicio
    sudo systemctl enable vsftpd
    sudo systemctl start vsftpd

    # Configurar acceso anónimo solo a /srv/ftp/general
    sudo bash -c 'cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_root=/srv/ftp/general
anon_upload_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
user_sub_token=$USER
local_root=/srv/ftp/usuarios/\$USER
EOF'

    sudo systemctl restart vsftpd
    echo "FTP instalado y configurado correctamente."
}

# Función para crear grupos
crear_grupos() {
    echo "Creando grupos reprobados y recursadores..."
    sudo groupadd reprobados 2>/dev/null || echo "El grupo 'reprobados' ya existe."
    sudo groupadd recursadores 2>/dev/null || echo "El grupo 'recursadores' ya existe."
}

# Función para agregar usuario y asignarlo a un grupo
agregar_usuario() {
    read -p "Ingrese el nombre del usuario: " username
    read -p "Seleccione grupo (1: reprobados, 2: recursadores): " group_choice

    case "$group_choice" in
        1) group="reprobados" ;;
        2) group="recursadores" ;;
        *) echo "Opción inválida."; return 1 ;;
    esac

    if id "$username" &>/dev/null; then
        echo "El usuario '$username' ya existe."
        return 1
    fi

    sudo useradd -m -g "$group" -s /bin/bash "$username"
    sudo passwd "$username"
    
    # Crear carpetas y asignar permisos
    sudo mkdir -p /srv/ftp/usuarios/$username
    sudo chown "$username":"$group" /srv/ftp/usuarios/$username
    sudo chmod 770 /srv/ftp/usuarios/$username

    echo "Usuario '$username' agregado al grupo '$group'."
}

# Función para configurar directorios
configurar_directorios() {
    echo "Configurando directorios FTP..."
    sudo mkdir -p /srv/ftp/general /srv/ftp/grupos/reprobados /srv/ftp/grupos/recursadores /srv/ftp/usuarios
    
    sudo chmod 777 /srv/ftp/general
    sudo chmod 770 /srv/ftp/grupos/reprobados
    sudo chmod 770 /srv/ftp/grupos/recursadores
    sudo chmod 755 /srv/ftp/usuarios

    for user in $(ls /srv/ftp/usuarios); do
        group=$(id -gn $user)
        sudo mkdir -p /home/$user/ftp/{mi_carpeta,mi_grupo,publica}
        
        # Montar carpetas correctamente
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
    sudo mount -a
    echo "Montajes configurados correctamente."
}

