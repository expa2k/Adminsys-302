#!/bin/bash

# Instalar el servidor DHCP
sudo apt update
sudo apt install -y isc-dhcp-server

# Detectar la interfaz de red con dirección en 192.168.x.x
INTERFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\./ {print $2; exit}')
echo "Usando la interfaz de red: $INTERFACE"
echo "INTERFACESv4=\"$INTERFACE\"" | sudo tee -a /etc/default/isc-dhcp-server > /dev/null

# Solicitar rango de IPs
read -p "Ingrese la IP inicial del rango DHCP: " RANGE_START
read -p "Ingrese la IP final del rango DHCP: " RANGE_END

# Configurar DHCP con valores predefinidos
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf > /dev/null
default-lease-time 600;
max-lease-time 7200;
subnet 192.168.1.0 netmask 255.255.255.0 {
    range ${RANGE_START} ${RANGE_END};
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

# Recargar y reiniciar el servicio DHCP
sudo systemctl daemon-reload
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "Servidor DHCP configurado y ejecutándose en $INTERFACE con rango $RANGE_START - $RANGE_END."
