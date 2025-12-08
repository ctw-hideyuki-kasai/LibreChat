# EC2 Instance Setup for LibreChat
# Connect and configure the EC2 instance

Write-Host "=== EC2 Instance Setup for LibreChat ===" -ForegroundColor Green

$EC2_IP = "57.180.19.194"
$KEY_PAIR_FILE = "librechat-key-pair.pem"

Write-Host "`n=== インスタンス情報 ===" -ForegroundColor Yellow
Write-Host "EC2 Public IP: $EC2_IP" -ForegroundColor Cyan
Write-Host "SSH Key: $KEY_PAIR_FILE" -ForegroundColor Cyan

Write-Host "`n=== Step 1: Route53 Aレコード更新手順 ===" -ForegroundColor Yellow
Write-Host "以下の手順でドメインのAレコードを更新してください:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. AWS Management Console -> Route53 を開く"
Write-Host "2. Hosted zones -> あなたのドメインを選択"
Write-Host "3. Aレコード(またはCNAME)を編集"
Write-Host "4. Value/Target を以下に変更:"
Write-Host "   $EC2_IP" -ForegroundColor Green
Write-Host "5. Save を実行"
Write-Host ""
Write-Host "または、AWS CLIで実行:"
Write-Host "aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch file://dns-record.json" -ForegroundColor White

# DNS更新用JSONファイル作成
$dnsRecordJson = @{
    Changes = @(
        @{
            Action = "UPSERT"
            ResourceRecordSet = @{
                Name = "your-domain.com"
                Type = "A"
                TTL = 300
                ResourceRecords = @(
                    @{ Value = $EC2_IP }
                )
            }
        }
    )
} | ConvertTo-Json -Depth 4

$dnsRecordJson | Out-File -FilePath "$PWD\dns-record.json" -Encoding UTF8
Write-Host "✓ DNS更新用ファイル作成: dns-record.json" -ForegroundColor Green

Write-Host "`n=== Step 2: SSH接続テスト ===" -ForegroundColor Yellow
Write-Host "SSH接続をテストしますか？ (PowerShellから実行)" -ForegroundColor Cyan
Write-Host ""
Write-Host "接続コマンド:" -ForegroundColor White
Write-Host "ssh -i $KEY_PAIR_FILE ubuntu@${EC2_IP}" -ForegroundColor Green
Write-Host ""
Write-Host "⚠ 初回接続時は 'yes' を入力してホストキーを受け入れてください" -ForegroundColor Yellow

$testSSH = Read-Host "SSH接続をテストしますか？ (y/n)"
if ($testSSH -eq "y" -or $testSSH -eq "Y") {
    if (Test-Path $KEY_PAIR_FILE) {
        Write-Host "SSH接続を開始します..." -ForegroundColor Cyan
        & ssh -i $KEY_PAIR_FILE ubuntu@${EC2_IP} -o "StrictHostKeyChecking=no"
    } else {
        Write-Host "✗ キーファイル '$KEY_PAIR_FILE' が見つかりません" -ForegroundColor Red
        Write-Host "キーファイルのパスを確認してください" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Step 3: EC2セットアップスクリプト作成 ===" -ForegroundColor Yellow
Write-Host "EC2インスタンス内で実行するセットアップスクリプトを作成します..." -ForegroundColor Cyan

# EC2内で実行するセットアップスクリプト
$ec2SetupScript = @'
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
'@

# スクリプトをファイルに保存
$ec2SetupScript | Out-File -FilePath "$PWD\ec2-setup.sh" -Encoding UTF8
Write-Host "✓ EC2セットアップスクリプト作成: ec2-setup.sh" -ForegroundColor Green

Write-Host "`n=== Step 4: ファイル転送準備 ===" -ForegroundColor Yellow
Write-Host "以下のファイルをEC2に転送する必要があります:" -ForegroundColor Cyan
Write-Host "- ec2-setup.sh (セットアップスクリプト)" -ForegroundColor White
Write-Host "- .env (環境変数設定)" -ForegroundColor White  
Write-Host "- librechat.yaml (アプリケーション設定)" -ForegroundColor White

Write-Host "`nファイル転送コマンド例:" -ForegroundColor Cyan
Write-Host "scp -i $KEY_PAIR_FILE ec2-setup.sh ubuntu@${EC2_IP}:/home/ubuntu/" -ForegroundColor Green
Write-Host "scp -i $KEY_PAIR_FILE .env ubuntu@${EC2_IP}:/home/ubuntu/LibreChat/" -ForegroundColor Green
Write-Host "scp -i $KEY_PAIR_FILE librechat.yaml ubuntu@${EC2_IP}:/home/ubuntu/LibreChat/" -ForegroundColor Green

Write-Host "`n=== 次のステップ ===" -ForegroundColor Yellow
Write-Host "1. Route53でドメインのAレコードを ${EC2_IP} に更新"
Write-Host "2. SSH接続してec2-setup.shを実行"
Write-Host "3. 設定ファイル(.env, librechat.yaml)を転送"
Write-Host "4. LibreChatコンテナを起動"

Read-Host "`nEnterキーを押して終了"