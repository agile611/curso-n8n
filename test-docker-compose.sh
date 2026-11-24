#!/bin/bash
# Test docker-compose on remote training machine
# Uso: ssh curso@130.117.95.60 'bash -s' < test-docker-compose.sh

set -euo pipefail

echo "=== Testing docker-compose on $(hostname) ==="

# 1. Check Docker is available
echo "[1/5] Checking Docker..."
docker --version
docker-compose --version

# 2. Clone repo if not exists
REPO_DIR="/opt/curso-n8n"
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[2/5] Cloning repository..."
    sudo mkdir -p "$REPO_DIR"
    sudo chown $USER:$USER "$REPO_DIR"
    git clone https://github.com/agile611/curso-n8n.git "$REPO_DIR"
else
    echo "[2/5] Updating repository..."
    cd "$REPO_DIR" && git pull origin main
fi

cd "$REPO_DIR"

# 3. Check docker-compose.yml syntax
echo "[3/5] Validating docker-compose.yml..."
docker-compose config > /dev/null && echo "✓ Syntax OK"

# 4. Build images
echo "[4/5] Building images..."
docker-compose build --no-cache

# 5. Start services
echo "[5/5] Starting services..."
docker-compose up -d

# Wait for healthcheck
echo "Waiting for healthcheck..."
sleep 10

# Check status
echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Health Check ==="
for i in {1..6}; do
    if curl -sf http://localhost:8000/ > /dev/null; then
        echo "✓ MkDocs responding on port 8000"
        break
    fi
    echo "  Waiting... ($i/6)"
    sleep 5
done

# Test nginx proxy
if curl -sf http://localhost/ > /dev/null; then
    echo "✓ Nginx proxy responding on port 80"
else
    echo "✗ Nginx not responding on port 80"
fi

echo ""
echo "=== Logs (last 20 lines) ==="
docker-compose logs --tail=20

echo ""
echo "=== Test Complete ==="
echo "Access: http://130.117.95.60"
