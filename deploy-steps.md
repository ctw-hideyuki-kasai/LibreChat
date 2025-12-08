# LibreChat デプロイ実行手順

## 現在の状況
✅ EC2インスタンス作成完了 (57.180.19.194)  
✅ SSH接続成功  
🔄 **次: EC2環境構築**

## Step 1: EC2セットアップスクリプト転送・実行

### 1-1. スクリプト転送
```powershell
# PowerShell (Windows)
scp -i librechat-key-pair.pem ec2-setup.sh ubuntu@57.180.19.194:/home/ubuntu/
```

### 1-2. EC2にSSH接続
```powershell
ssh -i librechat-key-pair.pem ubuntu@57.180.19.194
```

### 1-3. セットアップスクリプト実行 (EC2内)
```bash
# EC2内で実行
chmod +x ec2-setup.sh
./ec2-setup.sh

# 実行後、dockerグループ反映のため再ログイン
exit
# 再度SSH接続
ssh -i librechat-key-pair.pem ubuntu@57.180.19.194
```

### 1-4. Docker動作確認 (EC2内)
```bash
docker --version
docker-compose --version
sudo systemctl status docker
```

## Step 2: 設定ファイル作成

### 2-1. .env ファイル作成 (ローカル)

**SECRETS-TEMPLATE.md を参考に作成:**

```bash
#=== 基本設定 ===
HOST=0.0.0.0
PORT=3080
DOMAIN_CLIENT=https://your-domain.com
DOMAIN_SERVER=https://your-domain.com

#=== データベース ===
MONGO_URI=mongodb://mongodb:27017/LibreChat
DATABASE_URL=postgresql://postgres:YOUR_POSTGRES_PASSWORD@postgres:5432/librechat
POSTGRES_DB=librechat
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_GENERATED_PASSWORD

#=== セキュリティ ===
JWT_SECRET=YOUR_GENERATED_JWT_SECRET
JWT_REFRESH_SECRET=YOUR_GENERATED_JWT_REFRESH_SECRET
CREDS_KEY=YOUR_GENERATED_CREDS_KEY
CREDS_IV=YOUR_GENERATED_CREDS_IV

#=== 検索 ===
MEILISEARCH_HOST=http://meilisearch:7700
MEILI_MASTER_KEY=YOUR_GENERATED_MEILI_KEY

#=== AWS Bedrock ===
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
AWS_REGION=us-east-1

#=== その他 ===
NO_INDEX=false
TRUST_PROXY=1
ALLOW_EMAIL_LOGIN=true
ALLOW_REGISTRATION=true
```

### 2-2. librechat.yaml ファイル作成 (ローカル)

```yaml
version: 1.2.1
cache: true
fileStrategy: "local"

interface:
  customWelcome: 'Welcome to LibreChat on AWS!'
  fileSearch: true
  endpointsMenu: true
  modelSelect: true
  parameters: true
  sidePanel: true
  presets: true
  prompts: true
  bookmarks: true
  multiConvo: true
  agents: true

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
      dropParams: ['stop', 'user', 'frequency_penalty', 'presence_penalty']
```

## Step 3: 設定ファイル転送

```powershell
# PowerShell (Windows)
scp -i librechat-key-pair.pem .env ubuntu@57.180.19.194:/home/ubuntu/LibreChat/
scp -i librechat-key-pair.pem librechat.yaml ubuntu@57.180.19.194:/home/ubuntu/LibreChat/
```

## Step 4: LibreChat起動

### 4-1. EC2にSSH接続
```powershell
ssh -i librechat-key-pair.pem ubuntu@57.180.19.194
```

### 4-2. LibreChat起動 (EC2内)
```bash
cd /home/ubuntu/LibreChat

# 設定ファイル確認
ls -la .env librechat.yaml

# Docker Compose起動（プロダクション用）
docker-compose -f deploy-compose.yml up -d

# 起動確認
docker-compose ps

# ログ確認
docker-compose logs librechat
```

### 4-3. 動作確認
```bash
# EC2内から確認
curl -I http://localhost:3080

# 外部から確認（別ターミナル）
curl -I http://57.180.19.194:3080
```

## Step 5: ブラウザアクセステスト

- **HTTP**: http://57.180.19.194:3080
- **ドメイン設定後**: http://your-domain.com:3080

## トラブルシューティング

### コンテナ状況確認
```bash
docker ps -a
docker-compose logs
docker-compose logs librechat
docker-compose logs mongodb
```

### リソース確認
```bash
htop           # CPU/メモリ使用量
df -h          # ディスク使用量
free -h        # メモリ使用量
sudo ufw status # ファイアウォール状況
```

### 再起動手順
```bash
# LibreChat再起動
docker-compose restart librechat

# 全コンテナ再起動
docker-compose -f deploy-compose.yml down
docker-compose -f deploy-compose.yml up -d
```

---

## 次に実行すること

1. **ec2-setup.sh をEC2に転送・実行**
2. **シークレット生成 (SECRETS-TEMPLATE.md参照)**  
3. **.env と librechat.yaml 作成**
4. **設定ファイルをEC2に転送**
5. **LibreChat起動・動作確認**