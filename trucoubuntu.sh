#!/bin/bash
# Script para crear una "ilusión" de un usuario con nombre especial
# ADVERTENCIA: Este enfoque tiene limitaciones significativas y puede causar problemas

if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

# Definir variables
SPECIAL_USERNAME="5demayo/ignacio"  # El nombre deseado con caracteres especiales
ACTUAL_USERNAME="5demayo_ignacio"   # El nombre real y válido que usará el sistema
HOME_DIR="/home/$ACTUAL_USERNAME"   # Directorio home del usuario

# 1. Crear el usuario real con un nombre válido
echo "Creando usuario base '$ACTUAL_USERNAME'..."
adduser --quiet $ACTUAL_USERNAME

# 2. Crear un enlace simbólico para simular el nombre de directorio con "/"
ln -s $HOME_DIR "/home/5demayo" 2>/dev/null

# 3. Modificar archivos de configuración para mostrar el nombre especial donde sea posible
echo "Configurando apariencia de nombre especial '$SPECIAL_USERNAME'..."

# Modificar GECOS (información del usuario) para mostrar el nombre especial
usermod -c "$SPECIAL_USERNAME" $ACTUAL_USERNAME

# 4. Crear un alias para el usuario
echo "alias $SPECIAL_USERNAME='su - $ACTUAL_USERNAME'" >> /etc/bash.bashrc

# 5. Crear un mensaje personalizado de login
echo "Creando mensaje de bienvenida personalizado..."
cat > $HOME_DIR/.bash_login << EOF
echo "Bienvenido $SPECIAL_USERNAME"
EOF
chown $ACTUAL_USERNAME:$ACTUAL_USERNAME $HOME_DIR/.bash_login

# 6. Crear un archivo de información en el home
cat > $HOME_DIR/INFO.txt << EOF
Este usuario fue creado con el nombre técnico "$ACTUAL_USERNAME"
pero está configurado para aparecer como "$SPECIAL_USERNAME" donde sea posible.

Limitaciones:
- El nombre de inicio de sesión sigue siendo $ACTUAL_USERNAME
- Algunos programas del sistema mostrarán $ACTUAL_USERNAME
- El directorio home real es $HOME_DIR
EOF
chown $ACTUAL_USERNAME:$ACTUAL_USERNAME $HOME_DIR/INFO.txt

echo ""
echo "==================================================================="
echo "LIMITACIONES IMPORTANTES:"
echo "- El nombre real de inicio de sesión sigue siendo: $ACTUAL_USERNAME"
echo "- El nombre con '/' es sólo cosmético y no funcionará en comandos"
echo "- Muchos programas del sistema mostrarán el nombre real" 
echo "- Esta configuración puede causar confusión y problemas de mantenimiento"
echo "==================================================================="
echo ""
echo "Usuario creado con simulación cosmética del nombre especial."
echo "Para iniciar sesión, use: $ACTUAL_USERNAME"