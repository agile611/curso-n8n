#!/usr/bin/env python3
"""
Script to regenerate the entire lab environment from scratch on remote server 130.117.95.60
This script generates a bash script and executes it via SSH to avoid heredoc escaping issues.
"""

import os
import sys
import subprocess
import tempfile
import stat

# Remote server configuration
REMOTE_HOST = "130.117.95.60"
REMOTE_USER = "root"  # Adjust if needed
REPO_URL = "https://github.com/agile611/curso-n8n.git"
REMOTE_DIR = "/opt/curso-n8n"

# Bash script content - written as a Python string to avoid heredoc issues
BASH_SCRIPT = r"""#!/bin/bash
# Lab Environment Regeneration Script for Curso n8n
# Run on remote server 130.117.95.60

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

# Step 1: Clean up existing deployment (based on docker-compose.lab.yml)
log_info "Step 1: Cleaning up existing deployment..."
cd "$REMOTE_DIR" 2>/dev/null || true

# Stop and remove containers, networks, and volumes defined in docker-compose.lab.yml
if [[ -f "$COMPOSE_FILE" ]]; then
    log_info "Running: docker compose -f $COMPOSE_FILE down -v --remove-orphans"
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
fi

# Clean up any remaining project volumes (in case project name differs)
log_info "Removing any remaining project volumes..."
docker volume ls -q --filter "label=com.docker.compose.project=curso-n8n" | xargs -r docker volume rm 2>/dev/null || true

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
    git clean -fd || true  # Ignore permission errors on untracked dirs
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

# Step 9: Run Dify database migrations
log_info "Step 9: Running Dify database migrations..."
sleep 15  # Wait for PostgreSQL to be fully ready

# Try different migration commands (Dify uses Flask-Migrate/Alembic)
log_info "Attempting Dify migrations..."
docker compose -f "$COMPOSE_FILE" run --rm dify-api python -m flask db upgrade 2>/dev/null || \
docker compose -f "$COMPOSE_FILE" run --rm dify-api flask db upgrade 2>/dev/null || \
docker compose -f "$COMPOSE_FILE" run --rm dify-api python manage.py db upgrade 2>/dev/null || \
docker compose -f "$COMPOSE_FILE" run --rm dify-api alembic upgrade head 2>/dev/null || \
log_warn "Migration command not found or already applied - continuing..."

# Step 10: Wait for services to be healthy
log_info "Step 10: Waiting for services to become healthy..."
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

# Step 11: Verify deployment
log_info "Step 11: Verifying deployment..."
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

# Detect the lab server IP (130.117.95.0/24 range)
LOCAL_IP=$(ip -4 addr show scope global | awk '/130\.117\.95\./ {print $2}' | cut -d/ -f1 | head -1)
if [[ -z "$LOCAL_IP" ]]; then
    # Fallback to any global IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
fi
if [[ -z "$LOCAL_IP" ]]; then
    LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
fi

# Step 13: Test endpoints
log_info "Step 11: Testing endpoints..."
sleep 5

ENDPOINTS=(
    "http://$LOCAL_IP/health:Nginx Health"
    "http://$LOCAL_IP/n8n/healthz:n8n Health"
    "http://$LOCAL_IP/dify:Dify Web"
    "http://$LOCAL_IP/docs/:Documentation"
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
log_info "Access points (detected IP: $LOCAL_IP):"
log_info "  - n8n:       http://$LOCAL_IP/n8n/ (admin / n8n_lab_2026)"
log_info "  - Dify:      http://$LOCAL_IP/dify/"
log_info "  - Docs:      http://$LOCAL_IP/docs/"
log_info "  - Nginx:     http://$LOCAL_IP/health"
echo ""
log_info "To view logs: cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE logs -f [service]"
log_info "To stop:      cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE down"
"""

def write_bash_script(script_path: str) -> None:
    """Write the bash script to a file."""
    with open(script_path, 'w') as f:
        f.write(BASH_SCRIPT)
    os.chmod(script_path, stat.S_IRWXU | stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
    print(f"Bash script written to {script_path}")

def execute_remote_script(script_path: str) -> int:
    """Execute the script on the remote server via SSH."""
    # Copy script to remote server
    remote_script = "/tmp/regenerate_lab.sh"
    
    print(f"Copying script to {REMOTE_USER}@{REMOTE_HOST}:{remote_script}...")
    result = subprocess.run(
        ["scp", script_path, f"{REMOTE_USER}@{REMOTE_HOST}:{remote_script}"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"SCP failed: {result.stderr}")
        return result.returncode
    
    # Execute script on remote server
    print(f"Executing script on {REMOTE_HOST}...")
    result = subprocess.run(
        ["ssh", "-t", f"{REMOTE_USER}@{REMOTE_HOST}", f"bash {remote_script}"],
        capture_output=False  # Stream output directly
    )
    return result.returncode

def main():
    # Create temporary script file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
        script_path = f.name
    
    try:
        write_bash_script(script_path)
        
        # Execute on remote server
        exit_code = execute_remote_script(script_path)
        
        if exit_code == 0:
            print("\n✅ Lab environment regeneration completed successfully!")
        else:
            print(f"\n❌ Script exited with code {exit_code}")
            sys.exit(exit_code)
            
    finally:
        # Clean up local temp file
        try:
            os.unlink(script_path)
        except OSError:
            pass

if __name__ == "__main__":
    main()