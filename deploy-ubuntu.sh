#!/bin/bash
# Script de despliegue para Curso n8n en Ubuntu 24.04
# Uso: sudo ./deploy-ubuntu.sh [--docker|--native]

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
COURSE_DIR="/opt/curso-n8n"
SERVICE_NAME="curso-n8n"
PORT=8000
DOMAIN=""  # Configurar si se usa con reverse proxy

# Funciones de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Verificar si es root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

# Instalar dependencias del sistema
install_system_deps() {
    log_info "Instalando dependencias del sistema..."
    apt-get update
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        git \
        curl \
        ca-certificates \
        nginx \
        ufw
    log_success "Dependencias del sistema instaladas"
}

# Crear usuario de servicio
create_service_user() {
    log_info "Creando usuario de servicio..."
    if ! id "mkdocs" &>/dev/null; then
        useradd -r -m -d /home/mkdocs -s /bin/bash mkdocs
        log_success "Usuario mkdocs creado"
    else
        log_info "Usuario mkdocs ya existe"
    fi
}

# Despliegue nativo (sin Docker)
deploy_native() {
    log_info "Iniciando despliegue nativo..."

    # Crear directorio del curso
    mkdir -p "$COURSE_DIR"
    cd "$COURSE_DIR"

    # Clonar o actualizar repositorio
    if [[ -d ".git" ]]; then
        log_info "Actualizando repositorio existente..."
        git pull origin main
    else
        log_info "Clonando repositorio..."
        # Cambiar por la URL real del repo
        git clone https://github.com/agile611/curso-n8n.git .
    fi

    # Crear entorno virtual
    log_info "Creando entorno virtual Python..."
    python3 -m venv venv
    source venv/bin/activate

    # Instalar dependencias
    log_info "Instalando dependencias Python..."
    pip install --upgrade pip
    pip install -r requirements.txt

    # Construir sitio
    log_info "Construyendo sitio MkDocs..."
    mkdocs build --strict

    # Configurar systemd service
    log_info "Configurando servicio systemd..."
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" << SVC_EOF
[Unit]
Description=Curso n8n - MkDocs Server
After=network.target

[Service]
Type=simple
User=mkdocs
Group=mkdocs
WorkingDirectory=${COURSE_DIR}
Environment=PATH=${COURSE_DIR}/venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=${COURSE_DIR}/venv/bin/mkdocs serve --dev-addr=0.0.0.0:${PORT}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC_EOF

    # Configurar nginx como reverse proxy
    log_info "Configurando Nginx..."
    cat > "/etc/nginx/sites-available/${SERVICE_NAME}" << NGINX_EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};

    location / {
        proxy_pass http://127.0.0.1:$\{PORT\}\;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Cache para assets estáticos
    location /assets/ {
        proxy_pass http://127.0.0.1:$\{PORT\}\;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_EOF

    ln -sf "/etc/nginx/sites-available/${SERVICE_NAME}" "/etc/nginx/sites-enabled/"
    rm -f /etc/nginx/sites-enabled/default

    # Configurar firewall
    log_info "Configurando firewall..."
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable

    # Recargar y habilitar servicios
    systemctl daemon-reload
    systemctl enable --now "${SERVICE_NAME}"
    systemctl enable --now nginx
    systemctl reload nginx

    log_success "Despliegue nativo completado"
    log_info "Sitio disponible en: http://$(hostname -I | awk '{print $1}')"
}

# Despliegue con Docker
deploy_docker() {
    log_info "Iniciando despliegue con Docker..."

    # Instalar Docker si no está presente
    if ! command -v docker &>/dev/null; then
        log_info "Instalando Docker..."
        curl -fsSL https://get.docker.com | sh
        usermod -aG docker mkdocs
    fi

    cd "$COURSE_DIR"

    # Clonar o actualizar
    if [[ -d ".git" ]]; then
        git pull origin main
    else
        git clone https://github.com/agile611/curso-n8n.git .
    fi

    # Construir imagen
    log_info "Construyendo imagen Docker..."
    docker build -t "${SERVICE_NAME}:latest" .

    # Detener contenedor anterior si existe
    docker stop "${SERVICE_NAME}" 2>/dev/null || true
    docker rm "${SERVICE_NAME}" 2>/dev/null || true

    # Ejecutar contenedor
    log_info "Iniciando contenedor..."
    docker run -d \
        --name "${SERVICE_NAME}" \
        --restart unless-stopped \
        -p "${PORT}:8000" \
        "${SERVICE_NAME}:latest"

    # Configurar nginx reverse proxy
    log_info "Configurando Nginx..."
    cat > "/etc/nginx/sites-available/${SERVICE_NAME}" << NGINX_EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};

    location / {
        proxy_pass http://127.0.0.1:$\{PORT\}\;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_EOF

    ln -sf "/etc/nginx/sites-available/${SERVICE_NAME}" "/etc/nginx/sites-enabled/"
    rm -f /etc/nginx/sites-enabled/default
    systemctl reload nginx

    log_success "Despliegue Docker completado"
    log_info "Sitio disponible en: http://$(hostname -I | awk '{print $1}')"
}

# Función principal
main() {
    local mode="native"

    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --docker)
                mode="docker"
                shift
                ;;
            --native)
                mode="native"
                shift
                ;;
            *)
                log_error "Opción desconocida: $1"
                echo "Uso: $0 [--docker|--native]"
                exit 1
                ;;
        esac
    done

    log_info "=== Despliegue Curso n8n en Ubuntu 24.04 ==="
    log_info "Modo: $mode"

    check_root
    install_system_deps
    create_service_user

    if [[ "$mode" == "docker" ]]; then
        deploy_docker
    else
        deploy_native
    fi

    log_success "=== Despliegue completado ==="
}

main "$@"
