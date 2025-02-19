#!/bin/bash

# Instalar el servidor DHCP
sudo apt-get install -y isc-dhcp-server
echo "ISC DHCP se instaló correctamente"

# Función para validar la dirección IP
validate_ip() {
    local ip=$1
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    if [[ $ip =~ $regex ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                echo "IP inválida: fuera de rango"
                exit 1
            fi
        done
    else
        echo "Formato de IP inválido"
        exit 1
    fi
}

# Solicitar la IP del servidor DHCP
read -p "Ingrese la IP del servidor DHCP: " SERVER_IP
validate_ip "$SERVER_IP"

# Extraer la base de la IP (los tres primeros octetos)
IFS='.' read -r o1 o2 o3 o4 <<< "$SERVER_IP"
SUBNET_IP="$o1.$o2.$o3.0"
GATEWAY_IP="$o1.$o2.$o3.1"

echo "Subred detectada: $SUBNET_IP"
echo "Puerta de enlace configurada en: $GATEWAY_IP"

# Fijar la IP en Netplan
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses: [$SERVER_IP/24]
      gateway4: $GATEWAY_IP
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]" | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null

echo "Fijando la IP $SERVER_IP con puerta de enlace $GATEWAY_IP"
sudo netplan apply
echo "Aplicando cambios"

# Configurar DHCP en interfaces
echo "INTERFACESv4=\"enp0s8\"" | sudo tee /etc/default/isc-dhcp-server > /dev/null

# Solicitar rango de IPs para DHCP
read -p "Ingrese la IP inicial del rango DHCP: " RANGE_START
validate_ip "$RANGE_START"
read -p "Ingrese la IP final del rango DHCP: " RANGE_END
validate_ip "$RANGE_END"

# Configurar DHCP
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf > /dev/null
default-lease-time 600;
max-lease-time 7200;
subnet $SUBNET_IP netmask 255.255.255.0 {
    range ${RANGE_START} ${RANGE_END};
    option routers $GATEWAY_IP;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

# Recargar y reiniciar el servicio DHCP
sudo systemctl daemon-reload
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "Servidor DHCP configurado y ejecutándose en enp0s8 con rango $RANGE_START - $RANGE_END en la subred $SUBNET_IP."