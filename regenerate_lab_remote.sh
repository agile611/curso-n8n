#!/bin/bash
# Lab Environment Regeneration Script for Curso n8n
# Run on the lab server (130.117.95.60) as the 'curso' user
# Usage: bash regenerate_lab_remote.sh

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

# Configuration - runs from current directory (/home/curso/curso-n8n)
REPO_URL="https://github.com/agile611/curso-n8n.git"
REMOTE_DIR="$(pwd)"
COMPOSE_FILE="docker-compose.lab.yml"
ENV_FILE=".env.lab"

log_info "=== Starting Lab Environment Regeneration ==="
log_info "Target directory: $REMOTE_DIR"
log_info "Running as user: $(whoami)"

# Verify Docker is available (should be pre-installed on lab server)
if ! command -v docker &>/dev/null; then
    log_error "Docker not found. Please install Docker first."
    exit 1
fi
if ! docker compose version &>/dev/null; then
    log_error "Docker Compose not found. Please install Docker Compose plugin."
    exit 1
fi
log_success "Docker and Docker Compose are available"

# Verify user is in docker group
if ! groups | grep -q docker; then
    log_warn "User '$(whoami)' is not in 'docker' group. Docker commands may fail."
    log_warn "Run: sudo usermod -aG docker $(whoami) && newgrp docker"
fi

# Step 1: Clean up existing deployment
log_info "Step 1: Cleaning up existing deployment..."
cd "$REMOTE_DIR"

# Stop and remove containers, networks, volumes (based on docker-compose.lab.yml)
if [[ -f "$COMPOSE_FILE" ]]; then
    log_info "Stopping and removing all containers, networks, and volumes..."
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
    
    # Explicitly remove named volumes from docker-compose.lab.yml
    log_info "Removing named volumes: postgres_data, redis_data, n8n_data, dify_storage..."
    docker volume rm curso-n8n_postgres_data curso-n8n_redis_data curso-n8n_n8n_data curso-n8n_dify_storage 2>/dev/null || true
fi

# Remove any orphaned containers, networks, volumes
docker container prune -f 2>/dev/null || true
docker network prune -f 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

log_success "Cleanup completed"

# Step 2: Clone or update repository
log_info "Step 2: Setting up repository..."
if [[ -d "$REMOTE_DIR/.git" ]]; then
    log_info "Repository exists, updating..."
    cd "$REMOTE_DIR"
    git fetch origin
    git reset --hard origin/main
    git clean -fd || true  # Ignore permission errors on untracked dirs
else
    log_info "Cloning repository..."
    git clone "$REPO_URL" .
fi

log_success "Repository ready at $REMOTE_DIR"

# Step 3: Create .env.lab file with production values
log_info "Step 3: Creating environment file..."
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

# Step 4: Ensure init-multiple-dbs.sh is executable
log_info "Step 4: Setting up database initialization script..."
chmod +x "$REMOTE_DIR/init-multiple-dbs.sh"
log_success "Database init script ready"

# Step 5: Pull latest Docker images
log_info "Step 5: Pulling latest Docker images..."
cd "$REMOTE_DIR"
docker compose -f "$COMPOSE_FILE" pull
log_success "Images pulled"

# Step 6: Start services
log_info "Step 6: Starting all services..."
cd "$REMOTE_DIR"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# Step 7: Wait for services to be healthy
log_info "Step 7: Waiting for services to become healthy..."
sleep 10

# Check service health (services from docker-compose.lab.yml)
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

# Step 8: Verify deployment
log_info "Step 8: Verifying deployment..."
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

# Step 9: Test endpoints
log_info "Step 9: Testing endpoints..."
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