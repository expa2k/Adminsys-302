#!/bin/bash

instalar_servidor_dhcp() {
    sudo apt-get install -y isc-dhcp-server
    echo "ISC DHCP se instaló correctamente"
}

validar_ip() {
    local ip=$1
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    if [[ $ip =~ $regex ]]; then
        IFS='.' read -r -a octetos <<< "$ip"
        for octeto in "${octetos[@]}"; do
            if (( octeto < 0 || octeto > 255 )); then
                echo "IP inválida: fuera de rango"
                exit 1
            fi
        done
    else
        echo "Formato de IP inválido"
        exit 1
    fi
}

obtener_ip() {
    local mensaje=$1
    local ip
    read -p "$mensaje" ip
    validar_ip "$ip"
    echo "$ip"
}

configurar_red() {
    local ip_servidor=$1
    IFS='.' read -r o1 o2 o3 o4 <<< "$ip_servidor"
    local ip_subred="$o1.$o2.$o3.0"
    local ip_puerta_enlace="$o1.$o2.$o3.1"
    
    echo "Subred detectada: $ip_subred"
    echo "Puerta de enlace configurada en: $ip_puerta_enlace"
    
    echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s1:
      addresses: [$ip_servidor/8]
      gateway4: $ip_puerta_enlace
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]" | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null
    
    sudo netplan apply
    echo "INTERFACESv4=\"enp0s1\"" | sudo tee /etc/default/isc-dhcp-server > /dev/null
}

configurar_dhcp() {
    local ip_subred=$1
    local ip_puerta_enlace=$2
    local rango_inicio=$3
    local rango_fin=$4
    
    cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf > /dev/null
default-lease-time 600;
max-lease-time 7200;

subnet $ip_subred netmask 255.255.255.0 {
  range $rango_inicio $rango_fin;
  option routers $ip_puerta_enlace;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF
}

reiniciar_servicio_dhcp() {
    sudo systemctl daemon-reload
    sudo systemctl restart isc-dhcp-server
    sudo systemctl enable isc-dhcp-server
}


