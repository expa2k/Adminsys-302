#!/bin/bash

# Instalar el servidor DHCP
sudo apt update
sudo apt install -y isc-dhcp-server

# Solicitar la interfaz de red
read -p "Ingrese la interfaz de red (por defecto: eth0): " INTERFACE
INTERFACE=${INTERFACE:-eth0}

# Configurar la interfaz de red para el servidor DHCP
echo "INTERFACESv4=\"$INTERFACE\"" | sudo tee /etc/default/isc-dhcp-server > /dev/null

# Solicitar los parámetros de la red
read -p "Ingrese la subred (ejemplo: 192.168.1.0): " SUBNET
read -p "Ingrese la máscara de subred (ejemplo: 255.255.255.0): " NETMASK
read -p "Ingrese la IP de la puerta de enlace (ejemplo: 192.168.1.1): " GATEWAY
read -p "Ingrese el rango de IP inicial (ejemplo: 192.168.1.100): " RANGE_START
read -p "Ingrese el rango de IP final (ejemplo: 192.168.1.200): " RANGE_END

# Configurar el archivo dhcpd.conf
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf > /dev/null
default-lease-time 600;
max-lease-time 7200;
option subnet-mask $NETMASK;
option broadcast-address ${SUBNET%.*}.255;
option routers $GATEWAY;
option domain-name-servers 8.8.8.8, 8.8.4.4;
subnet $SUBNET netmask $NETMASK {
    range $RANGE_START $RANGE_END;
}
EOF

# Reiniciar el servicio DHCP
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "Servidor DHCP configurado y en ejecución en la interfaz $INTERFACE."