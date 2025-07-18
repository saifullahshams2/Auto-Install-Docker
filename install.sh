#!/bin/bash

set -e

echo "Welcome to the Docker, Portainer, Caddy and n8n Installer!"
echo "This script will install Docker, Portainer, Caddy, and optionally n8n in Docker. It will also set up a Caddy reverse proxy for n8n with HTTPS support."
echo "Please ensure you have sudo privileges to run this script."

read -p "Do you want to install n8n in Docker? (yes/no): " answern8n
answern8n=$(echo "$answern8n" | tr '[:upper:]' '[:lower:]')

if [[ "$answern8n" == "yes" || "$answern8n" == "y" ]]; then
    
    read -p "Enter your N8N basic auth username: " N8N_USER
    read -p "Enter your N8N basic auth password: " N8N_PASSWORD
    read -p "Enter your domain for n8N (e.g., n8n.example.com): " DOMAIN_N8N
    read -p "Enter your email for SSL certificate registration: " EMAIL
    echo "You have chosen to install n8n in Docker."

elif [[ "$answern8n" == "no" || "$answern8n" == "n" ]]; then
    echo "You have chosen not to install n8n in Docker."
else
    echo "Invalid answer. Please enter yes or no."
fi

echo "🛠️ Updating package list..."
sudo apt update &> /dev/null;

echo "🐳 Checking if Docker is installed..."
{
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
} &> /dev/null;

echo "🔐 Adding current user to docker group..."
sudo usermod -aG docker $USER &> /dev/null;

echo "✅ Enabling and starting Docker..."
{
sudo systemctl enable docker
sudo systemctl start docker
} &> /dev/null;

echo "🌐 Creating Docker network: caddynet..."
{
if ! sudo docker network ls | grep -q caddynet; then
    sudo docker network create caddynet
else
    echo "✅ Docker network 'caddynet' already exists."
fi
} &> /dev/null;

echo "📦 Creating volume for Portainer..."
sudo docker volume create portainer_data &> /dev/null;

echo "🚀 Running Portainer (default bridge network)..."
{
sudo docker run -d --name portainer \
    -p 9000:9000 \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
} &> /dev/null;
echo "🔗 Connecting Portainer to 'caddynet'..."
sudo docker network connect caddynet portainer &> /dev/null;

echo "📁 Creating Caddy folder and default Caddyfile..."
sudo mkdir -p /etc/caddy &> /dev/null;

sudo touch /etc/caddy/Caddyfile &> /dev/null;

# Create a secure Caddyfile with HTTPS (Linux EOL)
CADDYFILE_PATH="/etc/caddy/Caddyfile"
if [ ! -s "$CADDYFILE_PATH" ]; then
  sudo tee "$CADDYFILE_PATH" > /dev/null <<EOF
$DOMAIN_N8N {
    reverse_proxy n8n:5678
    tls $EMAIL
}

:80 {
    root * /usr/share/caddy
    file_server
}
EOF
else
  echo "Caddyfile already exists. Skipping creation. Please edit it manually if needed."
fi

# Start Installing Caddy
echo "🌍 Running Caddy container on 'caddynet'..."
{
sudo docker run -d --name caddy \
    --network caddynet \
    -p 80:80 -p 443:443 \
    -v caddy_data:/data \
    -v caddy_config:/config \
    -v /etc/caddy/default:/usr/share/caddy \
    -v /etc/caddy/Caddyfile:/etc/caddy/Caddyfile \
    --restart=always \
    caddy:latest

} &> /dev/null;



# Start Installing N8N from here
if [[ "$answern8n" == "yes" || "$answern8n" == "y" ]]; then  
    echo "Start installing n8n in Docker..."
    sudo docker volume create n8n_data
    
    sudo docker run -d \
    --name n8n \
    --restart always \
    --network caddynet \
    --network n8n \
    -p 5678:5678 \
    -v n8n_data:/home/node/.n8n \
    -e N8N_BASIC_AUTH_ACTIVE=true \
    -e N8N_BASIC_AUTH_USER="$N8N_USER" \
    -e N8N_BASIC_AUTH_PASSWORD="$N8N_PASSWORD" \
    -e WEBHOOK_URL="https://$DOMAIN_N8N" \
    -e N8N_HOST="$DOMAIN_N8N" \
    n8nio/n8n
    
elif [[ "$answern8n" == "no" || "$answern8n" == "n" ]]; then
    echo "Skipping n8n install."
else
    echo "Invalid answer. Please enter yes or no."
fi


echo "✅ DONE!"
echo "🔗 Portainer: http://localhost:9000 or https://your-ip-address:9000"
echo "🌍 Caddy: http://localhost or http://your-ip-address"
echo "🌐 n8n: https://$DOMAIN_N8N (if installed)"
echo "📂 Edit Caddyfile at /etc/caddy/Caddyfile"
echo "⚠️ You may need to logout and login again for Docker group changes to apply."
