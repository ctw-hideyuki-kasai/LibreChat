#!/bin/bash
# LibreChat EC2 Setup Script
# Run this script on the EC2 instance

echo "=== LibreChat EC2 Setup Script ==="
echo "Running on: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"

echo
echo "=== Step 1: System Update ==="
sudo apt update -y
sudo apt upgrade -y

echo
echo "=== Step 2: Docker Installation ==="
# Docker installation
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker ubuntu
echo "✓ Docker installed successfully"

echo
echo "=== Step 3: Docker Compose Installation ==="
# Docker Compose installation
DOCKER_COMPOSE_VERSION="2.21.0"
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "✓ Docker Compose installed successfully"

echo
echo "=== Step 4: Additional Tools Installation ==="
sudo apt install -y git curl wget htop nano vim unzip

echo
echo "=== Step 5: Node.js Installation (for development) ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
echo "✓ Node.js $(node --version) installed"
echo "✓ npm $(npm --version) installed"

echo
echo "=== Step 6: LibreChat Repository Clone ==="
cd /home/ubuntu
git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat
echo "✓ LibreChat repository cloned"
echo "Current directory: $(pwd)"
echo "LibreChat version: $(git describe --tags --always)"

echo
echo "=== Step 7: Directory Structure ==="
ls -la
echo

echo "=== Step 8: Firewall Configuration ==="
# UFW (Uncomplicated Firewall) setup
sudo ufw --force enable
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 3080/tcp   # LibreChat
sudo ufw status
echo "✓ Firewall configured"

echo
echo "=== Setup Complete ==="
echo "✓ System updated"
echo "✓ Docker installed and configured"
echo "✓ Docker Compose installed"
echo "✓ Additional tools installed"
echo "✓ Node.js installed"
echo "✓ LibreChat repository cloned"
echo "✓ Firewall configured"
echo
echo "Next steps:"
echo "1. Upload .env and librechat.yaml configuration files"
echo "2. Run 'docker-compose -f deploy-compose.yml up -d'"
echo "3. Configure SSL certificate"
echo
echo "To verify Docker installation:"
echo "docker --version"
echo "docker-compose --version"
echo
echo "To check running status:"
echo "sudo systemctl status docker"
echo
echo "IMPORTANT: You may need to logout and login again for docker group changes to take effect"
