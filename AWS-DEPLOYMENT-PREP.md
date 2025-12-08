# LibreChat AWS Deployment 事前準備ドキュメント

## 概要

LibreChatをAWS EC2 + Docker Compose（小規模プラン）でデプロイするための事前準備項目とチェックリスト。
SSL証明書付きドメインあり、AWS Bedrock利用前提。

## 1. 必要な秘密鍵・シークレット生成

### Linux/macOS/WSL環境での生成方法

```bash
# JWT_SECRET (32文字以上推奨)
JWT_SECRET=$(openssl rand -hex 32)
echo "JWT_SECRET=${JWT_SECRET}"

# JWT_REFRESH_SECRET (32文字以上推奨)  
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
echo "JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}"

# CREDS_KEY (正確に32文字)
CREDS_KEY=$(openssl rand -hex 32)
echo "CREDS_KEY=${CREDS_KEY}"

# CREDS_IV (正確に16文字)
CREDS_IV=$(openssl rand -hex 16)
echo "CREDS_IV=${CREDS_IV}"

# MEILI_MASTER_KEY (検索エンジン用)
MEILI_MASTER_KEY=$(openssl rand -base64 32)
echo "MEILI_MASTER_KEY=${MEILI_MASTER_KEY}"

# PostgreSQL パスワード
POSTGRES_PASSWORD=$(openssl rand -base64 16)
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
```

### Windows PowerShell環境での生成方法

```powershell
# JWT_SECRET
$JWT_SECRET = -join ((1..32) | ForEach {'{0:x}' -f (Get-Random -Max 16)})
Write-Host "JWT_SECRET=$JWT_SECRET"

# JWT_REFRESH_SECRET
$JWT_REFRESH_SECRET = -join ((1..32) | ForEach {'{0:x}' -f (Get-Random -Max 16)})
Write-Host "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET"

# CREDS_KEY (32文字)
$CREDS_KEY = -join ((1..32) | ForEach {'{0:x}' -f (Get-Random -Max 16)})
Write-Host "CREDS_KEY=$CREDS_KEY"

# CREDS_IV (16文字)
$CREDS_IV = -join ((1..16) | ForEach {'{0:x}' -f (Get-Random -Max 16)})
Write-Host "CREDS_IV=$CREDS_IV"
```

## 2. AWS設定

### EC2インスタンス要件
- **インスタンスタイプ**: `t3.medium` または `t3.large`
- **AMI**: Ubuntu 20.04 LTS
- **ストレージ**: 30GB以上
- **セキュリティグループ**: HTTP(80), HTTPS(443), SSH(22)
- **Elastic IP**: 固定IPアドレス取得済み

### IAM設定 - Bedrock用権限

以下のポリシーを持つIAMユーザーを作成：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels"
      ],
      "Resource": "*"
    }
  ]
}
```

### Route53設定
- ドメイン: **設定済み**
- SSL証明書: **設定済み**
- A/CNAMEレコード: EC2のElastic IPに設定

## 3. 設定ファイル

### .env ファイル設定

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
POSTGRES_PASSWORD=YOUR_POSTGRES_PASSWORD

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

#=== SSL/HTTPS ===
NO_INDEX=false
TRUST_PROXY=1

#=== 認証設定 ===
ALLOW_EMAIL_LOGIN=true
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=false
ALLOW_SOCIAL_REGISTRATION=false
SESSION_EXPIRY=900000
REFRESH_TOKEN_EXPIRY=604800000
```

### librechat.yaml 設定

```yaml
version: 1.2.1
cache: true

# ファイルストレージ戦略（初期はローカル）
fileStrategy: "local"

# インターフェース設定
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

# エンドポイント設定
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
          - 'meta.llama3-1-70b-instruct-v1:0'
          - 'meta.llama3-1-8b-instruct-v1:0'
        fetch: false
      titleConvo: true
      titleModel: 'anthropic.claude-3-haiku-20240307-v1:0'
      modelDisplayLabel: 'AWS Bedrock'
      dropParams: ['stop', 'user', 'frequency_penalty', 'presence_penalty']
```

## 4. 事前準備チェックリスト

### AWS関連
- [ ] EC2インスタンス作成・起動済み
- [ ] Elastic IP取得・アタッチ済み
- [ ] セキュリティグループ設定済み（HTTP/HTTPS/SSH）
- [ ] IAMユーザー作成・Bedrock権限付与済み
- [ ] AWS Access Key/Secret Key取得済み

### ドメイン・SSL関連
- [ ] ドメイン取得済み・Route53設定済み
- [ ] SSL証明書取得済み・設定済み
- [ ] DNS A/CNAMEレコード設定済み（EC2 IP宛て）

### 設定ファイル関連
- [ ] 各種シークレット生成済み
- [ ] .env ファイル作成済み
- [ ] librechat.yaml ファイル作成済み
- [ ] 環境変数値記録・管理済み

### EC2環境関連
- [ ] Docker, Docker Compose インストール済み
- [ ] git インストール済み
- [ ] LibreChatリポジトリクローン済み
- [ ] 必要なポート（80, 443, 3080）開放済み

## 5. デプロイ手順概要

1. **EC2接続**: SSH接続でEC2にアクセス
2. **依存関係インストール**: Docker, Docker Compose, Git
3. **リポジトリクローン**: LibreChatソースコード取得
4. **設定ファイル配置**: .env, librechat.yaml配置
5. **Docker Compose起動**: `docker-compose -f deploy-compose.yml up -d`
6. **SSL設定**: Let's Encrypt or 既存証明書設定
7. **動作確認**: アプリケーション起動確認

## 6. 注意事項

- **セキュリティ**: 生成したシークレットは安全に管理
- **バックアップ**: 設定ファイルのバックアップを取得
- **モニタリング**: CloudWatch等でログ・メトリクス監視設定
- **更新**: 定期的なセキュリティアップデート実施

## 7. トラブルシューティング

### よくある問題
- **ポート競合**: 他のサービスが3080ポートを使用
- **メモリ不足**: t3.microでは不足、t3.medium以上推奨
- **SSL証明書**: Let's Encryptの場合、ドメイン検証必須
- **Bedrock権限**: IAMポリシーの設定不備

### ログ確認方法
```bash
# コンテナログ確認
docker-compose logs librechat

# システムリソース確認
htop
df -h
```

---

**作成日**: 2025-11-18  
**対象環境**: AWS EC2 + Docker Compose  
**LibreChatバージョン**: v0.8.0-rc3対応