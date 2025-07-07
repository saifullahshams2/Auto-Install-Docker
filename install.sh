#!/bin/bash

set -e

echo "🛠️ Updating package list..."
sudo apt update

echo "🐳 Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    sudo apt install -y ca-certificates curl gnupg lsb-release

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "✅ Docker is already installed."
fi

echo "🔐 Adding current user to docker group..."
sudo usermod -aG docker $USER

echo "✅ Enabling and starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "🌐 Creating Docker network: caddynet..."
if ! sudo docker network ls | grep -q caddynet; then
    sudo docker network create caddynet
else
    echo "✅ Docker network 'caddynet' already exists."
fi

echo "📦 Creating volume for Portainer..."
sudo docker volume create portainer_data

echo "🚀 Running Portainer (default bridge network)..."
sudo docker run -d --name portainer \
    -p 9000:9000 \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

echo "🔗 Connecting Portainer to 'caddynet'..."
sudo docker network connect caddynet portainer

echo "📁 Creating Caddy folder and default Caddyfile..."
sudo mkdir -p /etc/caddy

sudo touch /etc/caddy/Caddyfile

echo "🌍 Running Caddy container on 'caddynet'..."
sudo docker run -d --name caddy \
    --network caddynet \
    -p 80:80 -p 443:443 \
    -v caddy_data:/data \
    -v caddy_config:/config \
    -v /etc/caddy/Caddyfile:/etc/caddy/Caddyfile \
    --restart=always \
    caddy:latest

echo "✅ DONE!"
echo "🔗 Portainer: http://localhost:9000"
echo "🌍 Caddy: http://localhost"
echo "📂 Edit Caddyfile at /etc/caddy/Caddyfile"
echo "⚠️ You may need to logout and login again for Docker group changes to apply."
