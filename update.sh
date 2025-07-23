#!/bin/bash

set -e

echo "🔄 Starting Docker, Portainer, Caddy & n8n Updater"
echo "This script will update Docker engine and pull latest images for containers."

# ============ Update Docker ============

echo "🐳 Checking for Docker..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please run the installer first."
    exit 1
else
    echo "✅ Docker is installed. Updating Docker packages..."

    sudo apt update -y &> /dev/null;
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &> /dev/null;
    echo "✅ Docker updated successfully."
fi

# ============ Pull Latest Images ============

echo "📥 Pulling latest images..."

docker pull portainer/portainer-ce:latest
docker pull caddy:latest

# Only pull n8n if container exists
if docker ps -a --format '{{.Names}}' | grep -q '^n8n$'; then
    docker pull n8nio/n8n:latest
    N8N_INSTALLED=true
else
    echo "ℹ️ n8n is not installed. Skipping its update."
    N8N_INSTALLED=false
fi

# ============ Recreate Containers ============

# Portainer
echo "♻️ Updating Portainer container..."
docker stop portainer &> /dev/null || true
docker rm portainer &> /dev/null || true

docker run -d --name portainer \
    -p 9000:9000 \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

# Caddy
echo "♻️ Updating Caddy container..."
docker stop caddy &> /dev/null || true
docker rm caddy &> /dev/null || true

docker run -d --name caddy \
    --network caddynet \
    -p 80:80 -p 443:443 \
    -v caddy_data:/data \
    -v caddy_config:/config \
    -v /etc/caddy/Caddyfile:/etc/caddy/Caddyfile \
    --restart=always \
    caddy:latest

# n8n (only if previously installed)
if [ "$N8N_INSTALLED" = true ]; then
    echo "♻️ Updating n8n container..."

    docker stop n8n &> /dev/null || true
    docker rm n8n &> /dev/null || true

    # Recreate with same settings
    docker run -d \
        --name n8n \
        --restart always \
        --network caddynet \
        --network n8n \
        -p 5678:5678 \
        -v n8n_data:/home/node/.n8n \
        -e WEBHOOK_URL="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' n8n 2>/dev/null | grep WEBHOOK_URL | cut -d '=' -f2-)" \
        -e N8N_HOST="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' n8n 2>/dev/null | grep N8N_HOST | cut -d '=' -f2-)" \
        -e N8N_PROTOCOL=https \
        n8nio/n8n:latest

    echo "✅ n8n updated and restarted."
fi

echo "✅ All containers updated successfully!"
