#!/usr/bin/env bash

Instalacion_ftp(){
echo "Empezando a instalar el ftp"
sudo apt-get install vsftpd
echo "ftp instalado"

Creacion_carpetas
}


Creacion_carpetas(){
if [ -d "/home/ftp" ]; then

echo "folder ya existen"

else

sudo mkdir /home/ftp

fi

if [ -d "/home/ftp/grupos" ]; then

echo "los grupos ya existen"

else

sudo mkdir /home/ftp/grupos
fi

if [ -d "/home/ftp/usuarios" ]; then

echo "Los usuarios ya existen"

else

sudo mkdir /home/ftp/usuarios
fi

if [ -d "/home/ftp/publica" ]; then

echo "la carpeta publica ya existe"

else

sudo mkdir /home/ftp/publica
fi

}



Creacion_anonimo(){

if [ -d "/anonimo" ]; then

echo "la carpeta para anonimo ya existe"

else

sudo mkdir /anonimo
fi

if [ -d "/anonimo/publica" ]; then

echo "El anonimo publico ya existe"

else

sudo mkdir /anonimo/publica
fi



if sudo grep -q "^anonymous_enable=YES" /etc/vsftpd.conf; then
echo "ya funciona"
else

sudo sed -i 's/^anonymous_enable=.*/anonymous_enable=YES/g' /etc/vsftpd.conf

sudo service vsftpd restart

fi


if sudo grep -q "^write_enable=.*" /etc/vsftpd.conf; then
echo "Ya esta habilitada la escritura"
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

local user="$1"
local maximo=20

if [ -n "$user" ] && [ ${#user} -le $maximo ]; then

return 1

else 

return 0

fi

}


Creacion_grupo(){
local grupo="$1"

if validarnombre_grupo "$grupo"; then

echo "Nombre del grupo invalido "

InvalidGroupName=true

while $InvalidGroupName ; do

 read -p "ingrese de nuevo el nombre del grupo" grupo
 
if validarnombre_grupo "$grupo"; then
echo "nombre de grupo invalido"

InvalidGroupName=true
else 
InvalidGroupName=false

 
fi
done

fi



if existenciagrupo "$grupo"; then
echo "el grupo ya existe "

InvalidGroup=true

while $InvalidGroup ; do

 read -p "ingrese de nuevo el nombre del grupo" grupo
 
if existenciagrupo "$grupo"; then
echo "el grupo ya existe"

InvalidGroup=true
else 
InvalidGroup=false

 
fi

done

fi

sudo groupadd $grupo

echo "grupo creado"

sudo mkdir /home/ftp/grupos/$grupo

sudo chgrp $grupo /home/ftp/grupos/$grupo
}

Creacion_usuario(){
local user="$1"


if validarnombre_user "$user"; then

echo "nombre de usuario invalido "

InvalidUserName=true

while $InvalidUserName; do

 read -p "ingrese de nuevo el nombre del usuario" user
 
if validarnombre_user "$user"; then
echo "nombre de usuario invalido"

InvalidUserName=true
else 
InvalidUserName=false

 
fi
done

fi



if existenciauser "$user"; then
echo "el usuario ya existe "

InvalidUserName=true

while $InvalidUserName; do

 read -p "ingrese de nuevo el nombre del usuario" user
 
if existenciauser "$user"; then
echo "el usuario ya existe"

InvalidUserName=true
else 
InvalidUserName=false

 
fi

done

fi




sudo adduser $user
echo "usuario creado exitosamente"
sudo mkdir /home/$user/$user
sudo mkdir /home/ftp/usuarios/$user


sudo chmod 700 /home/$user/$user
sudo chmod 700 /home/ftp/usuarios/$user

sudo chmod 777 /home/ftp/publica

sudo mkdir /home/$user/publica

sudo chown $user /home/ftp/usuarios/$user

sudo chown $user /home/$user/$user

sudo mount --bind /home/ftp/usuarios/$user /home/$user/$user

sudo mount --bind /home/ftp/publica /home/$user/publica

}

Asignacion_grupo(){
local user="$1"
local grupo="$2"

sudo adduser $user $grupo

echo "grupo asignado"

sudo chmod 774 /home/ftp/grupos/$grupo

sudo mkdir /home/$user/$grupo

sudo mount --bind /home/ftp/grupos/$grupo /home/$user/$grupo




}

Cambiar_grupo(){

read -p "escriba al usuario a quien desea cambiar de grupo " user
read -p "escriba el nuevo grupo de ese usuario " group

grupoactual=$(groups "$user" | awk '{print $5}')

{
sudo umount /home/$user/$grupoactual
} || {

echo "hubo un problema"
exit 1

}

sudo deluser $user $grupoactual
sudo adduser $user $group

sudo mv /home/$user/$grupoactual /home/$user/$group

sudo mount --bind /home/ftp/grupos/$group /home/$user/$group

sudo chgrp $group /home/$user/$group

}

existenciauser(){
local user="$1"

existencia=false

if id $user &> /dev/null; then

    existencia=0
else
  existencia=1

fi

return "$existencia"

}


existenciagrupo(){
local grupo="$1"

existencia=false

if getent group "$grupo" > /dev/null 2 >&1; then

   existencia=0
else

  existencia=1
fi

return "$existencia"

}
