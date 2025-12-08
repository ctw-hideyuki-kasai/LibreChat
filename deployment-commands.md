# LibreChat デプロイコマンド集

## 現在の状況
- **EC2 Public IP**: `57.180.19.194`
- **SSH Key**: `librechat-key-pair.pem`
- **インスタンス**: Ubuntu 20.04 LTS (t3.medium)

## Step 1: Route53 ドメイン設定

### 手動設定（AWS Console）
1. AWS Management Console → Route53
2. Hosted zones → あなたのドメインを選択
3. Aレコードを編集
4. Value を `57.180.19.194` に変更
5. TTL を 300 に設定
6. Save

### CLI設定（オプション）
```bash
# dns-record.json を編集してから実行
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch file://dns-record.json
```

## Step 2: SSH接続

### Windows (PowerShell)
```powershell
# キーファイルの権限設定（初回のみ）
icacls librechat-key-pair.pem /inheritance:r
icacls librechat-key-pair.pem /grant:r "%username%:R"

# SSH接続
ssh -i librechat-key-pair.pem ubuntu@57.180.19.194
```

### Linux/macOS
```bash
# キーファイルの権限設定（初回のみ）
chmod 400 librechat-key-pair.pem

# SSH接続
ssh -i librechat-key-pair.pem ubuntu@57.180.19.194
```

## Step 3: EC2インスタンス初期設定

### 1. セットアップスクリプト転送
```bash
# PowerShell/Bash共通
scp -i librechat-key-pair.pem ec2-setup.sh ubuntu@57.180.19.194:/home/ubuntu/
```

### 2. EC2内でスクリプト実行
```bash
# SSH接続後、EC2内で実行
chmod +x ec2-setup.sh
./ec2-setup.sh

# 実行後、dockerグループ反映のため一度ログアウト・再ログイン
exit
# 再度SSH接続
ssh -i librechat-key-pair.pem ubuntu@57.180.19.194
```

### 3. Docker動作確認
```bash
# EC2内で実行
docker --version
docker-compose --version
sudo systemctl status docker
```

## Step 4: 設定ファイル準備

### 1. .env ファイル作成（ローカル）
```bash
# SECRETS-TEMPLATE.md を参考に .env ファイルを作成
# 最低限必要な設定:

HOST=0.0.0.0
PORT=3080
DOMAIN_CLIENT=https://your-domain.com
DOMAIN_SERVER=https://your-domain.com

# データベース
MONGO_URI=mongodb://mongodb:27017/LibreChat
DATABASE_URL=postgresql://postgres:YOUR_POSTGRES_PASSWORD@postgres:5432/librechat
POSTGRES_DB=librechat
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_GENERATED_PASSWORD

# セキュリティ
JWT_SECRET=YOUR_GENERATED_JWT_SECRET
JWT_REFRESH_SECRET=YOUR_GENERATED_JWT_REFRESH_SECRET
CREDS_KEY=YOUR_GENERATED_CREDS_KEY
CREDS_IV=YOUR_GENERATED_CREDS_IV

# 検索
MEILISEARCH_HOST=http://meilisearch:7700
MEILI_MASTER_KEY=YOUR_GENERATED_MEILI_KEY

# AWS Bedrock
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
AWS_REGION=us-east-1
```

### 2. librechat.yaml ファイル作成（ローカル）
```yaml
version: 1.2.1
cache: true
fileStrategy: "local"

endpoints:
  custom:
    - name: 'bedrock'
      apiKey: 'user_provided'
      baseURL: 'bedrock://us-east-1'
      models:
        default:
          - 'anthropic.claude-3-5-sonnet-20241022-v2:0'
          - 'anthropic.claude-3-haiku-20240307-v1:0'
          - 'anthropic.claude-3-opus-20240229-v1:0'
        fetch: false
      titleConvo: true
      titleModel: 'anthropic.claude-3-haiku-20240307-v1:0'
      modelDisplayLabel: 'AWS Bedrock'
```

## Step 5: ファイル転送

```bash
# 設定ファイルをEC2に転送
scp -i librechat-key-pair.pem .env ubuntu@57.180.19.194:/home/ubuntu/LibreChat/
scp -i librechat-key-pair.pem librechat.yaml ubuntu@57.180.19.194:/home/ubuntu/LibreChat/
```

## Step 6: LibreChat起動

### EC2内で実行
```bash
cd /home/ubuntu/LibreChat

# 設定ファイル確認
ls -la .env librechat.yaml

# Docker Compose起動（プロダクション用）
docker-compose -f deploy-compose.yml up -d

# ログ確認
docker-compose logs

# 動作確認
curl -I http://localhost:3080
```

## Step 7: 動作確認

### 1. HTTP接続テスト
```bash
# EC2内から
curl -I http://localhost:3080

# 外部から
curl -I http://57.180.19.194:3080
```

### 2. ブラウザアクセス
- HTTP: `http://57.180.19.194:3080`
- ドメイン設定後: `http://your-domain.com:3080`

## トラブルシューティング

### コンテナ状況確認
```bash
docker ps -a
docker-compose logs librechat
docker-compose logs mongodb
```

### ポート確認
```bash
sudo netstat -tlnp | grep :3080
sudo ufw status
```

### リソース確認
```bash
htop
df -h
free -h
```

### 再起動
```bash
# LibreChat再起動
docker-compose -f deploy-compose.yml restart

# 全コンテナ停止・再起動
docker-compose -f deploy-compose.yml down
docker-compose -f deploy-compose.yml up -d
```

## SSL設定（後で実施）

### Let's Encrypt証明書取得
```bash
sudo apt install certbot
sudo certbot certonly --standalone -d your-domain.com
```

### Nginx設定（オプション）
```bash
sudo apt install nginx
# nginx.confでSSL終端、3080ポートへプロキシ
```

---

**重要**: 
- 設定ファイル内の `your-domain.com` を実際のドメインに置き換え
- 生成したシークレットキーを適切に設定
- セキュリティグループでポート3080が開放されていることを確認