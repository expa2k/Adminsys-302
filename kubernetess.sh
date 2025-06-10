#!/bin/bash

# Colores para mejorar la visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con formato
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar si minikube está instalado
check_minikube() {
    if ! command_exists minikube; then
        print_error "Minikube no está instalado. Por favor, instálelo primero (Opción 1.1)"
        return 1
    fi
    return 0
}

# Función para verificar si kubectl está instalado
check_kubectl() {
    if ! command_exists kubectl; then
        print_error "kubectl no está instalado. Se instalará automáticamente con minikube"
        return 1
    fi
    return 0
}

# Función para verificar si minikube está en ejecución
check_minikube_running() {
    if ! minikube status | grep -q "host: Running"; then
        print_error "Minikube no está en ejecución. Iniciando minikube..."
        minikube start
        if [ $? -ne 0 ]; then
            print_error "No se pudo iniciar minikube. Por favor, verifique la instalación."
            return 1
        fi
    fi
    return 0
}

# Función mejorada para instalar Minikube con soporte para conntrack
install_minikube() {
    clear
    print_message "Instalando Minikube..."
    
    # Verificar si se está ejecutando como root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Detectado que estás ejecutando como root."
        echo "Minikube no recomienda ejecutarse como root con el driver Docker."
        echo ""
        echo "Opciones disponibles:"
        echo "1. Cambiar a un usuario normal (RECOMENDADO)"
        echo "2. Usar driver 'none' (AVANZADO - puede ser peligroso)"
        echo "3. Cancelar instalación"
        echo ""
        read -p "Selecciona una opción (1-3): " root_option
        
        case $root_option in
            1)
                print_message "Para usar Minikube de forma segura:"
                echo "1. Sal del usuario root: exit"
                echo "2. Crea un usuario normal: sudo adduser minikubeuser"
                echo "3. Añádelo al grupo docker: sudo usermod -aG docker minikubeuser"
                echo "4. Cambia a ese usuario: su - minikubeuser"
                echo "5. Ejecuta este script nuevamente"
                read -p "Presione Enter para continuar..."
                return
                ;;
            2)
                print_warning "Usando driver 'none' - ESTO PUEDE SER PELIGROSO"
                MINIKUBE_DRIVER="--driver=none --force"
                
                # Instalar conntrack (requerido para el driver 'none')
                print_message "Instalando conntrack (requerido para el driver 'none')..."
                apt-get update
                apt-get install -y conntrack
                print_success "conntrack instalado correctamente"
                
                print_message "Instalando crictl (requerido por Kubernetes)..."
                CRICTL_VERSION="v1.28.0"
                curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
                sudo tar -C /usr/local/bin -xzf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
                rm crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
                print_success "crictl instalado correctamente"
                 # Instalar cri-dockerd
    print_message "Instalando cri-dockerd..."
    sudo apt-get install -y git golang-go make
    git clone https://github.com/Mirantis/cri-dockerd.git
    cd cri-dockerd
    make
    sudo make install

    sudo cp -a packaging/systemd/* /etc/systemd/system
    sudo sed -i 's:/usr/bin/cri-dockerd:/usr/local/bin/cri-dockerd:' /etc/systemd/system/cri-docker.service
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service
    sudo systemctl enable --now cri-docker.socket
    cd ..
    rm -rf cri-dockerd
    print_success "cri-dockerd instalado correctamente"

                ;;
            3)
                print_message "Instalación cancelada"
                return
                ;;
            *)
                print_error "Opción inválida"
                return
                ;;
        esac
    else
        MINIKUBE_DRIVER=""
    fi
    
    # Verificar si Docker está instalado
    if ! command_exists docker; then
        print_message "Instalando Docker..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        sudo usermod -aG docker $USER
        print_success "Docker instalado correctamente"
        print_warning "Es posible que necesite cerrar sesión y volver a iniciarla para usar Docker sin sudo"
    else
        print_success "Docker ya está instalado"
    fi
    
    # Instalar kubectl si no está instalado
    if ! command_exists kubectl; then
        print_message "Instalando kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        print_success "kubectl instalado correctamente"
    else
        print_success "kubectl ya está instalado"
    fi
    
    # Instalar Minikube si no está instalado
    if ! command_exists minikube; then
        print_message "Instalando Minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        chmod +x minikube-linux-amd64
        sudo mv minikube-linux-amd64 /usr/local/bin/minikube
        print_success "Minikube instalado correctamente"
    else
        print_success "Minikube ya está instalado"
    fi
    
    # Iniciar Minikube con el driver apropiado
    print_message "Iniciando Minikube..."
    if [ -n "$MINIKUBE_DRIVER" ]; then
        minikube start $MINIKUBE_DRIVER
    else
        minikube start
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Minikube iniciado correctamente"
        minikube status
    else
        print_error "Error al iniciar Minikube"
    fi
    
    read -p "Presione Enter para continuar..."
}

# Función para crear y gestionar Pods
manage_pods() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    while true; do
        clear
        echo "===== GESTIÓN DE PODS ====="
        echo "1. Crear un Pod desde un archivo YAML"
        echo "2. Crear un Pod simple de nginx"
        echo "3. Listar todos los Pods"
        echo "4. Describir un Pod específico"
        echo "5. Eliminar un Pod"
        echo "6. Ejecutar un comando en un Pod"
        echo "7. Volver al menú principal"
        echo "=========================="
        
        read -p "Seleccione una opción: " pod_option
        
        case $pod_option in
            1)
                clear
                read -p "Ingrese la ruta al archivo YAML: " yaml_path
                if [ -f "$yaml_path" ]; then
                    kubectl apply -f "$yaml_path"
                    print_success "Pod creado desde archivo YAML"
                else
                    print_error "El archivo no existe"
                fi
                ;;
            2)
                clear
                read -p "Ingrese un nombre para el Pod de nginx: " pod_name
                kubectl run "$pod_name" --image=nginx
                print_success "Pod de nginx '$pod_name' creado"
                ;;
            3)
                clear
                echo "Listando todos los Pods..."
                kubectl get pods -o wide
                ;;
            4)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod a describir: " pod_name
                kubectl describe pod "$pod_name"
                ;;
            5)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod a eliminar: " pod_name
                kubectl delete pod "$pod_name"
                print_success "Pod '$pod_name' eliminado"
                ;;
            6)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod: " pod_name
                read -p "Ingrese el comando a ejecutar: " command
                kubectl exec -it "$pod_name" -- $command
                ;;
            7)
                return
                ;;
            *)
                print_error "Opción inválida"
                ;;
        esac
        
        read -p "Presione Enter para continuar..."
    done
}

# Función para configurar Services
configure_services() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    while true; do
        clear
        echo "===== CONFIGURACIÓN DE SERVICES ====="
        echo "1. Crear un Service desde un archivo YAML"
        echo "2. Crear un Service para exponer un Pod"
        echo "3. Listar todos los Services"
        echo "4. Describir un Service específico"
        echo "5. Eliminar un Service"
        echo "6. Volver al menú principal"
        echo "====================================="
        
        read -p "Seleccione una opción: " service_option
        
        case $service_option in
            1)
                clear
                read -p "Ingrese la ruta al archivo YAML: " yaml_path
                if [ -f "$yaml_path" ]; then
                    kubectl apply -f "$yaml_path"
                    print_success "Service creado desde archivo YAML"
                else
                    print_error "El archivo no existe"
                fi
                ;;
            2)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod a exponer: " pod_name
                read -p "Ingrese el nombre para el Service: " service_name
                read -p "Ingrese el puerto del contenedor: " container_port
                read -p "Ingrese el puerto del Service (o presione Enter para usar el mismo): " service_port
                
                if [ -z "$service_port" ]; then
                    service_port=$container_port
                fi
                
                kubectl expose pod "$pod_name" --name="$service_name" --port="$service_port" --target-port="$container_port"
                print_success "Service '$service_name' creado para el Pod '$pod_name'"
                ;;
            3)
                clear
                echo "Listando todos los Services..."
                kubectl get services -o wide
                ;;
            4)
                clear
                kubectl get services
                read -p "Ingrese el nombre del Service a describir: " service_name
                kubectl describe service "$service_name"
                ;;
            5)
                clear
                kubectl get services
                read -p "Ingrese el nombre del Service a eliminar: " service_name
                kubectl delete service "$service_name"
                print_success "Service '$service_name' eliminado"
                ;;
            6)
                return
                ;;
            *)
                print_error "Opción inválida"
                ;;
        esac
        
        read -p "Presione Enter para continuar..."
    done
}

# Función para desplegar una aplicación Flask
deploy_flask_app() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    clear
    print_message "Desplegando una aplicación Flask en Kubernetes..."
    
    # Crear directorio temporal para la aplicación
    mkdir -p ~/flask-k8s-demo
    cd ~/flask-k8s-demo
    
    # Crear archivo app.py
    cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        "message": "¡Hola desde Kubernetes!",
        "environment": os.environ.get("APP_ENV", "development"),
        "secret_message": os.environ.get("SECRET_MESSAGE", "No hay mensaje secreto configurado")
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
    
    # Crear Dockerfile
    cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
EOF
    
    # Crear requirements.txt
    cat > requirements.txt << 'EOF'
flask==2.0.1
EOF
    
    # Crear deployment.yaml
    cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-app
        image: flask-app:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: flask-app-config
              key: APP_ENV
        - name: SECRET_MESSAGE
          valueFrom:
            secretKeyRef:
              name: flask-app-secrets
              key: SECRET_MESSAGE
EOF
    
    # Crear service.yaml
    cat > service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service
spec:
  selector:
    app: flask-app
  ports:
  - port: 80
    targetPort: 5000
  type: NodePort
EOF
    
    print_message "Construyendo la imagen Docker..."
    eval $(minikube docker-env)
    docker build -t flask-app:latest .
    
    print_success "Imagen Docker construida correctamente"
    
    print_message "Archivos creados en ~/flask-k8s-demo"
    ls -la
    
    read -p "Presione Enter para continuar con el despliegue..."
    
    # Desplegar la aplicación
    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
    
    print_success "Aplicación Flask desplegada correctamente"
    print_message "Puede acceder a la aplicación usando: minikube service flask-app-service --url"
    
    read -p "Presione Enter para continuar..."
}

# Función para gestionar ConfigMaps
manage_configmaps() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    clear
    print_message "Creando ConfigMap para la aplicación Flask..."
    
    # Crear ConfigMap
    cat > ~/flask-k8s-demo/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: flask-app-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  API_URL: "https://api.example.com"
EOF
    
    kubectl apply -f ~/flask-k8s-demo/configmap.yaml
    print_success "ConfigMap creado correctamente"
    
    # Mostrar el ConfigMap
    kubectl get configmap flask-app-config -o yaml
    
    read -p "Presione Enter para continuar..."
}

# Función para gestionar Secrets
manage_secrets() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    clear
    print_message "Creando Secret para la aplicación Flask..."
    
    # Crear Secret
    kubectl create secret generic flask-app-secrets \
        --from-literal=SECRET_MESSAGE="Este es un mensaje secreto" \
        --from-literal=API_KEY="k8s-demo-api-key-12345"
    
    print_success "Secret creado correctamente"
    
    # Mostrar el Secret (codificado)
    kubectl get secret flask-app-secrets -o yaml
    
    read -p "Presione Enter para continuar..."
}

# Función para usar kubectl logs
use_kubectl_logs() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    while true; do
        clear
        echo "===== USO DE KUBECTL LOGS ====="
        echo "1. Ver logs de un Pod"
        echo "2. Ver logs de un Pod con seguimiento (tail)"
        echo "3. Ver logs de un contenedor específico en un Pod"
        echo "4. Ver logs desde hace un tiempo específico"
        echo "5. Volver al menú principal"
        echo "==============================="
        
        read -p "Seleccione una opción: " logs_option
        
        case $logs_option in
            1)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod: " pod_name
                kubectl logs "$pod_name"
                ;;
            2)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod: " pod_name
                kubectl logs -f "$pod_name"
                ;;
            3)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod: " pod_name
                read -p "Ingrese el nombre del contenedor: " container_name
                kubectl logs "$pod_name" -c "$container_name"
                ;;
            4)
                clear
                kubectl get pods
                read -p "Ingrese el nombre del Pod: " pod_name
                read -p "Ingrese el tiempo (ej: 1h, 10m, 30s): " time
                kubectl logs "$pod_name" --since="$time"
                ;;
            5)
                return
                ;;
            *)
                print_error "Opción inválida"
                ;;
        esac
        
        read -p "Presione Enter para continuar..."
    done
}

# Función para implementar balanceo de carga
implement_load_balancing() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    clear
    print_message "Implementando sistema de balanceo de carga..."
    
    # Crear archivo para el balanceador de carga
    cat > ~/flask-k8s-demo/load-balancer.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: flask-app-loadbalancer
spec:
  selector:
    app: flask-app
  ports:
  - port: 80
    targetPort: 5000
  type: LoadBalancer
EOF
    
    kubectl apply -f ~/flask-k8s-demo/load-balancer.yaml
    print_success "Balanceador de carga creado correctamente"
    
    # Mostrar información del servicio
    kubectl get service flask-app-loadbalancer
    
    print_message "En Minikube, puede acceder al servicio usando: minikube service flask-app-loadbalancer"
    minikube service flask-app-loadbalancer --url
    
    read -p "Presione Enter para continuar..."
}

# Función para simular Rolling Updates
simulate_rolling_updates() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    clear
    print_message "Simulando actualización sin tiempo de inactividad (Rolling Update)..."
    
    # Verificar si existe el deployment
    if ! kubectl get deployment flask-app &> /dev/null; then
        print_error "El deployment 'flask-app' no existe. Por favor, despliegue la aplicación primero."
        read -p "Presione Enter para continuar..."
        return
    fi
    
    # Mostrar el estado actual
    print_message "Estado actual del deployment:"
    kubectl get deployment flask-app
    kubectl get pods -l app=flask-app
    
    read -p "Presione Enter para continuar con la actualización..."
    
    # Actualizar la imagen o configuración
    print_message "Actualizando la versión de la aplicación..."
    
    # Crear una nueva versión de la aplicación
    cd ~/flask-k8s-demo
    
    # Modificar app.py para la versión 2
    cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        "message": "¡Hola desde Kubernetes! (Versión 2)",
        "environment": os.environ.get("APP_ENV", "development"),
        "secret_message": os.environ.get("SECRET_MESSAGE", "No hay mensaje secreto configurado"),
        "version": "2.0"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
    
    # Construir la nueva imagen
    print_message "Construyendo la nueva versión de la imagen..."
    eval $(minikube docker-env)
    docker build -t flask-app:v2 .
    
    # Actualizar el deployment para usar la nueva imagen
    kubectl set image deployment/flask-app flask-app=flask-app:v2
    
    # Observar el proceso de actualización
    print_message "Observando el proceso de actualización..."
    kubectl rollout status deployment/flask-app
    
    # Mostrar el nuevo estado
    print_message "Estado después de la actualización:"
    kubectl get deployment flask-app
    kubectl get pods -l app=flask-app
    
    print_success "Rolling Update completado correctamente"
    
    # Opción para revertir si es necesario
    read -p "¿Desea revertir la actualización? (s/n): " revert
    if [[ "$revert" == "s" || "$revert" == "S" ]]; then
        kubectl rollout undo deployment/flask-app
        print_message "Revirtiendo a la versión anterior..."
        kubectl rollout status deployment/flask-app
        print_success "Reversión completada"
    fi
    
    read -p "Presione Enter para continuar..."
}

# Función para gestionar volúmenes persistentes
manage_persistent_volumes() {
    if ! check_minikube || ! check_minikube_running; then
        read -p "Presione Enter para continuar..."
        return
    fi
    
    clear
    print_message "Gestionando volúmenes persistentes..."
    
    # Crear PV y PVC
    cat > ~/flask-k8s-demo/persistent-volume.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: flask-app-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/flask-app
EOF
    
    cat > ~/flask-k8s-demo/persistent-volume-claim.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: flask-app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
    
    # Crear directorio en el host
    minikube ssh "sudo mkdir -p /data/flask-app && sudo chmod 777 /data/flask-app"
    
    # Aplicar los archivos
    kubectl apply -f ~/flask-k8s-demo/persistent-volume.yaml
    kubectl apply -f ~/flask-k8s-demo/persistent-volume-claim.yaml
    
    print_success "PV y PVC creados correctamente"
    
    # Mostrar información
    kubectl get pv
    kubectl get pvc
    
    # Actualizar el deployment para usar el volumen
    cat > ~/flask-k8s-demo/deployment-with-volume.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app-with-volume
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-app-with-volume
  template:
    metadata:
      labels:
        app: flask-app-with-volume
    spec:
      containers:
      - name: flask-app
        image: flask-app:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: flask-app-config
              key: APP_ENV
        - name: SECRET_MESSAGE
          valueFrom:
            secretKeyRef:
              name: flask-app-secrets
              key: SECRET_MESSAGE
        volumeMounts:
        - name: data-volume
          mountPath: /app/data
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: flask-app-pvc
EOF
    
    kubectl apply -f ~/flask-k8s-demo/deployment-with-volume.yaml
    
    print_success "Deployment con volumen persistente creado correctamente"
    
    # Mostrar información
    kubectl get pods -l app=flask-app-with-volume
    
    read -p "Presione Enter para continuar..."
}

# Menú principal
main_menu() {

# 1. Forzar IPv4 para apt
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4

# 2. Cambiar a un mirror que funcione mejor
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo sed -i 's/archive.ubuntu.com/mirror.ubuntu.com/g' /etc/apt/sources.list

# 3. Actualizar la lista de paquetes
sudo apt-get update

    while true; do
        clear
        echo "=========================================="
        echo "    MENÚ DE GESTIÓN DE KUBERNETES"
        echo "=========================================="
        echo "1. Configuración del Entorno"
        echo "   1.1 Instalación de Minikube"
        echo "   1.2 Creación y gestión de Pods"
        echo "   1.3 Configuración de Services"
        echo ""
        echo "2. Desplegar una aplicación básica"
        echo "   2.1 Usar ConfigMap para configuraciones"
        echo "   2.2 Aplicar Secrets para datos sensibles"
        echo ""
        echo "3. Monitoreo y Mantenimiento"
        echo "   3.1 Uso de kubectl logs para depuración"
        echo ""
        echo "4. Evaluación Final"
        echo "   4.1 Implementar sistema de balanceo de carga"
        echo "   4.2 Simular actualización sin tiempo de inactividad"
        echo "   4.3 Gestionar volúmenes persistentes"
        echo ""
        echo "5. Salir"
        echo "=========================================="
        
        read -p "Seleccione una opción: " option
        
        case $option in
            1.1)
                install_minikube
                ;;
            1.2)
                manage_pods
                ;;
            1.3)
                configure_services
                ;;
            2)
                deploy_flask_app
                ;;
            2.1)
                manage_configmaps
                ;;
            2.2)
                manage_secrets
                ;;
            3.1)
                use_kubectl_logs
                ;;
            4.1)
                implement_load_balancing
                ;;
            4.2)
                simulate_rolling_updates
                ;;
            4.3)
                manage_persistent_volumes
                ;;
            5)
                clear
                print_message "Gracias por usar el script de gestión de Kubernetes"
                exit 0
                ;;
            *)
                print_error "Opción inválida"
                read -p "Presione Enter para continuar..."
                ;;
        esac
    done
}

# Iniciar el menú principal
main_menu