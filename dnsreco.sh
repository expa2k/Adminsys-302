# dns.sh
install_dns() {
    sudo apt update && sudo apt install -y bind9 bind9-utils bind9-dnsutils
}

restart_dns() {
    sudo systemctl restart bind9
}

configure_dns() {
    local DOMINIO="reprobados.com"
    local IP_SERVIDOR="192.168.0.155"
    local NAMED_CONF="/etc/bind/named.conf.local"
    local ZONE_FILE="/etc/bind/db.reprobados"
    
    echo "zone \"$DOMINIO\" { type master; file \"$ZONE_FILE\"; };" | sudo tee $NAMED_CONF > /dev/null
    
    sudo tee $ZONE_FILE > /dev/null <<EOL
\$TTL 604800
@   IN  SOA ns.$DOMINIO. admin.$DOMINIO. (
        2        ; Serial
        604800   ; Refresh
        86400    ; Retry
        2419200  ; Expire
        604800 ) ; Negative Cache TTL
;
@   IN  NS  ns.$DOMINIO.
@   IN  A   $IP_SERVIDOR
www IN  A   $IP_SERVIDOR
ns  IN  A   $IP_SERVIDOR
EOL
    
    restart_dns
    echo "Configuración DNS completada."
}

install_dns
configure_dns
