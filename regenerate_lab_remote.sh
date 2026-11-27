#!/bin/bash
# Lab Environment Regeneration Script for Curso n8n
# Run this script DIRECTLY on the remote server (130.117.95.60) as root
# Usage: sudo bash regenerate_lab_remote.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Configuration
REPO_URL="https://github.com/agile611/curso-n8n.git"
REMOTE_DIR="/opt/curso-n8n"
COMPOSE_FILE="docker-compose.lab.yml"
ENV_FILE=".env.lab"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (sudo)"
    exit 1
fi

log_info "=== Starting Lab Environment Regeneration ==="
log_info "Target directory: $REMOTE_DIR"

# Step 1: Clean up existing deployment
log_info "Step 1: Cleaning up existing deployment..."
cd "$REMOTE_DIR" 2>/dev/null || true

# Stop and remove containers, networks, volumes
if [[ -f "$COMPOSE_FILE" ]]; then
    log_info "Stopping existing containers..."
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
fi

# Remove any orphaned containers
docker container prune -f 2>/dev/null || true
docker network prune -f 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

log_success "Cleanup completed"

# Step 2: Install Docker and Docker Compose if not present
log_info "Step 2: Ensuring Docker and Docker Compose are installed..."
if ! command -v docker &>/dev/null; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    log_success "Docker installed"
else
    log_info "Docker already installed"
fi

if ! command -v docker compose &>/dev/null && ! docker compose version &>/dev/null; then
    log_info "Installing Docker Compose plugin..."
    apt-get update && apt-get install -y docker-compose-plugin
    log_success "Docker Compose plugin installed"
else
    log_info "Docker Compose already available"
fi

# Step 3: Install git if not present
log_info "Step 3: Ensuring git is installed..."
if ! command -v git &>/dev/null; then
    apt-get update && apt-get install -y git
    log_success "Git installed"
else
    log_info "Git already installed"
fi

# Step 4: Clone or update repository
log_info "Step 4: Setting up repository..."
if [[ -d "$REMOTE_DIR/.git" ]]; then
    log_info "Repository exists, updating..."
    cd "$REMOTE_DIR"
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    log_info "Cloning repository..."
    mkdir -p "$REMOTE_DIR"
    cd "$REMOTE_DIR"
    git clone "$REPO_URL" .
fi

log_success "Repository ready at $REMOTE_DIR"

# Step 5: Create .env.lab file with production values
log_info "Step 5: Creating environment file..."
cat > "$REMOTE_DIR/$ENV_FILE" << 'ENV_EOF'
LAB_HOST=130.117.95.60
POSTGRES_PASSWORD=n8n_lab_2026
REDIS_PASSWORD=redis_lab_2026
N8N_BASIC_AUTH_PASSWORD=n8n_lab_2026
N8N_ENCRYPTION_KEY=clave_secreta_32_chars_minimo!!
DIFY_SECRET_KEY=dify_secret_key_32_chars_minimo!!
ENV_EOF

chmod 600 "$REMOTE_DIR/$ENV_FILE"
log_success "Environment file created"

# Step 6: Ensure init-multiple-dbs.sh is executable
log_info "Step 6: Setting up database initialization script..."
chmod +x "$REMOTE_DIR/init-multiple-dbs.sh"
log_success "Database init script ready"

# Step 7: Pull latest Docker images
log_info "Step 7: Pulling latest Docker images..."
cd "$REMOTE_DIR"
docker compose -f "$COMPOSE_FILE" pull
log_success "Images pulled"

# Step 8: Start services
log_info "Step 8: Starting all services..."
cd "$REMOTE_DIR"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# Step 9: Wait for services to be healthy
log_info "Step 9: Waiting for services to become healthy..."
sleep 10

# Check service health
SERVICES=("postgres" "redis" "n8n" "dify-api" "dify-web" "dify-worker" "docs" "nginx")
for service in "${SERVICES[@]}"; do
    log_info "Checking $service..."
    for i in {1..30}; do
        if docker compose -f "$COMPOSE_FILE" ps "$service" | grep -q "healthy\|Up"; then
            log_success "$service is running"
            break
        fi
        if [[ $i -eq 30 ]]; then
            log_warn "$service may not be fully healthy yet"
        fi
        sleep 2
    done
done

# Step 10: Verify deployment
log_info "Step 10: Verifying deployment..."
cd "$REMOTE_DIR"

echo ""
log_info "=== Service Status ==="
docker compose -f "$COMPOSE_FILE" ps

echo ""
log_info "=== Service Logs (last 20 lines each) ==="
for service in "${SERVICES[@]}"; do
    echo "--- $service ---"
    docker compose -f "$COMPOSE_FILE" logs --tail=20 "$service" 2>/dev/null || true
done

# Step 11: Test endpoints
log_info "Step 11: Testing endpoints..."
sleep 5

ENDPOINTS=(
    "http://130.117.95.60/health:Nginx Health"
    "http://130.117.95.60/n8n/healthz:n8n Health"
    "http://130.117.95.60/dify:Dify Web"
    "http://130.117.95.60/docs/:Documentation"
)

for endpoint in "${ENDPOINTS[@]}"; do
    url="${endpoint%%:*}"
    name="${endpoint##*:}"
    if curl -sf -o /dev/null --max-time 10 "$url" 2>/dev/null; then
        log_success "$name: OK ($url)"
    else
        log_warn "$name: Not responding yet ($url)"
    fi
done

echo ""
log_success "=== Lab Environment Regeneration Complete ==="
log_info "Access points:"
log_info "  - n8n:       http://130.117.95.60/n8n/ (admin / n8n_lab_2026)"
log_info "  - Dify:      http://130.117.95.60/dify/"
log_info "  - Docs:      http://130.117.95.60/docs/"
log_info "  - Nginx:     http://130.117.95.60/health"
echo ""
log_info "To view logs: cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE logs -f [service]"
log_info "To stop:      cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE down"