# 🚀 Docker Setup Script: Portainer + Caddy (Ubuntu 22/24)

This repository contains a **one-line installation script** for Ubuntu 22.04 and 24.04 that:

- 🐳 Installs **Docker**
- 📊 Deploys **Portainer** (via Docker)
- 🌍 Deploys **Caddy Web Server** (via Docker)
- 🗂️ Creates a default `Caddyfile` at `/etc/caddy/Caddyfile`
- 🛠️ Includes an optional **n8n** installer that prompts the user for installation during the setup process.

---

## 📥 Quick Install (One Line)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/saifullahshams2/Auto-Install-Docker/main/install.sh)
```

## Documentation for N8N Installation Process

- The installation process will prompt the user to confirm whether they want to install N8N.

## User Inputs

During the installation, the following information will be requested from the user:

1. **Domain**: The domain to be used with N8N, The URL for the N8N webhook.
2. **Email for TLS Certificate**: The email address to be used for obtaining a TLS certificate.

## Important Note

Please ensure your IP address points to the desired domain to avoid any disruptions.

## Description

This project offers a streamlined setup script for Ubuntu servers, enabling quick installation of Docker, deployment of Portainer for container management, and setup of Caddy web server—all within Docker containers. Perfect for creating a lightweight, web-ready environment in just minutes.
