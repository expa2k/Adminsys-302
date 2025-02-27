#!/bin/bash
echo "actualizando el sistema"
sudo apt update && sudo apt update -y
echo "instalando openssh"
sudo apt install -y openssh-server
echo "iniciar y habilitar ssh"
sudo systemctl start ssh
sudo systemctl enable ssh
echo "configurando el firewall para el ssh"
sudo ufw allow ssh
sudo ufw reload
echo 'verificar el estado del servicio ssh"
sudo systemctl status ssh --no-pager
echo "ssh $(whoami)@$hostname -I | awk '{print $1}')"