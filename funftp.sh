#!/usr/bin/env bash

Instalacion_ftp(){
echo "Comenzando instalacion del servidor"
sudo apt-get install vsftpd
echo "Servidor listo"

Creacion_carpetas
}


Creacion_carpetas(){
if [ -d "/home/ftp" ]; then

echo "carpeta base existe"

else

sudo mkdir /home/ftp

fi

if [ -d "/home/ftp/grupos" ]; then

echo "teams ya creados"

else

sudo mkdir /home/ftp/grupos
fi

if [ -d "/home/ftp/usuarios" ]; then

echo "people ya creados"

else

sudo mkdir /home/ftp/usuarios
fi

if [ -d "/home/ftp/publica" ]; then

echo "shared ya existe"

else

sudo mkdir /home/ftp/publica
fi

}



Creacion_anonimo(){

if [ -d "/anonimo" ]; then

echo "guest ya existe"

else

sudo mkdir /anonimo
fi

if [ -d "/anonimo/publica" ]; then

echo "guest shared existe"

else

sudo mkdir /anonimo/publica
fi



if sudo grep -q "^anonymous_enable=YES" /etc/vsftpd.conf; then
echo "ya configurado"
else

sudo sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/g' /etc/vsftpd.conf

sudo service vsftpd restart

fi


if sudo grep -q "^write_enable=.*" /etc/vsftpd.conf; then
echo "Escritura habilitada"
else
sudo mount --bind /home/ftp/publica /anonimo/publica

echo "write_enable=YES" | sudo tee -a /etc/vsftpd.conf
echo "anon_root=/anonimo" | sudo tee -a /etc/vsftpd.conf

sudo service vsftpd restart
fi

}

Validacion_nombre_grupo(){
local grupo="$1"
local maximo=20

if [ -n "$grupo" ] && [ ${#grupo} -le $maximo ]; then

return 1

else 

return 0

fi

}


Validacion_nombreusuario(){

local persona="$1"
local maximo=20

if [ -n "$persona" ] && [ ${#persona} -le $maximo ]; then

return 1

else 

return 0

fi

}


Creacion_grupo(){
local grupo="$1"

if validarnombre_grupo "$grupo"; then

echo "Nombre no valido"

NombreInvalido=true

while $NombreInvalido ; do

 read -p "Ingresa otro nombre" equipo
 
if validarnombre_grupo "$grupo"; then
echo "nombre no valido"

NombreInvalido=true
else 
NombreInvalido=false

 
fi
done

fi



if existenciagrupo "$grupo"; then
echo "ya existe"

GrupoDuplicado=true

while $GrupoDuplicado ; do

 read -p "Ingresa otro nombre" equipo
 
if existenciagrupo "$grupo"; then
echo "ya existe"

GrupoDuplicado=true
else 
GrupoDuplicado=false

 
fi

done

fi

sudo groupadd $grupo

echo "equipo creado"

sudo mkdir /home/ftp/grupos/$equipo

sudo chgrp $equipo /home/ftp/grupos/$equipo
}

Creacion_usuario(){
local persona="$1"


if validarnombre_user "$persona"; then

echo "nombre no valido"

NombreInvalido=true

while $NombreInvalido; do

 read -p "ingresa otro nombre" persona
 
if validarnombre_user "$persona"; then
echo "nombre no valido"

NombreInvalido=true
else 
NombreInvalido=false

 
fi
done

fi



if existenciauser "$persona"; then
echo "ya existe"

UsuarioDuplicado=true

while $UsuarioDuplicado; do

 read -p "ingresa otro nombre" persona
 
if existenciauser "$persona"; then
echo "ya existe"

UsuarioDuplicado=true
else 
UsuarioDuplicado=false

 
fi

done

fi




sudo adduser $persona
echo "persona creada"
sudo mkdir /home/$persona/$persona
sudo mkdir /home/ftp/usuarios/$persona


sudo chmod 700 /home/$persona/$persona
sudo chmod 700 /home/ftp/usuarios/$persona

sudo chmod 777 /home/ftp/publica

sudo mkdir /home/$persona/publica

sudo chown $persona /home/ftp/usuarios/$persona

sudo chown $persona /home/$persona/$persona

sudo mount --bind /home/ftp/usuarios/$persona /home/$persona/$persona

sudo mount --bind /home/ftp/publica /home/$persona/publica

}

Asignacion_grupo(){
local persona="$1"
local grupo="$2"

sudo adduser $persona $grupo

echo "asignado"

sudo chmod 774 /home/ftp/grupos/$grupo

sudo mkdir /home/$persona/$grupo

sudo mount --bind /home/ftp/grupos/$equipo /home/$persona/$grupo




}

Cambiar_grupo(){

read -p "persona a cambiar" persona
read -p "nuevo equipo" equipo

grupoactual=$(groups "$persona" | awk '{print $5}')

{
sudo umount /home/$persona/$grupoactual
} || {

echo "error"
exit 1

}

sudo deluser $persona $grupoactual
sudo adduser $persona $grupo

sudo mv /home/$persona/$equipoactual /home/$persona/$grupo

sudo mount --bind /home/ftp/grupos/$grupo /home/$persona/$grupo

sudo chgrp $grupo /home/$persona/$grupo

}

existenciauser(){
local persona="$1"

existe=false

if id $persona &> /dev/null; then

    existe=0
else
  existe=1

fi

return "$existe"

}


existenciagrupo(){
local grupo="$1"

existe=false

if getent group "$grupo" > /dev/null 2>&1; then

   existe=0
else

  existe=1
fi

return "$existe"

}