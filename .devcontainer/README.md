# LibreChat DevContainer

このDevContainer設定により、LibreChatの開発環境を簡単にセットアップできます。

## 含まれるサービス

- **app**: メインの開発コンテナ（Node.js 20）
- **mongodb**: MongoDBデータベース
- **meilisearch**: Meilisearch検索エンジン
- **vectordb**: PostgreSQL with pgvector（ベクトルデータベース）
- **rag_api**: RAG APIサービス

## 使用方法

### クイックスタート

1. VS Codeでこのプロジェクトを開く
2. コマンドパレット（Ctrl+Shift+P / Cmd+Shift+P）を開く
3. **"Dev Containers: Reopen in Container"** を選択
4. コンテナのビルドと起動を待つ（初回は5-10分程度）
5. コンテナ起動後、`.env`ファイルが自動生成されます（テンプレートから）
6. アプリを起動：
   ```bash
   bash .devcontainer/start-app.sh
   ```
   または手動で：
   ```bash
   # ターミナル1
   npm run backend:dev
   
   # ターミナル2
   npm run frontend:dev
   ```
7. ブラウザで http://localhost:3000 にアクセス

### 詳細なセットアップ手順

詳細な手順については、**[SETUP.md](./SETUP.md)** を参照してください。

### 初回起動時の自動セットアップ

初回起動時は、`post-create.sh`スクリプトが自動実行され、以下がセットアップされます：
   - TypeScriptのグローバルインストール
   - npm依存関係のインストール
   - 必要なパッケージのビルド（data-provider, data-schemas, api）
   - テスト環境ファイルの作成
   - Playwrightのインストール
   - `.env`ファイルの自動作成（テンプレートから）

## ポート

- **3080**: LibreChat API
- **3000**: LibreChat Client (開発モード)
- **27017**: MongoDB
- **7700**: Meilisearch
- **5432**: PostgreSQL
- **8000**: RAG API

## 環境変数

`.env`ファイルをプロジェクトルートに作成してください。

### 初回セットアップ

1. プロジェクトルートに`.env`ファイルを作成
2. 以下のテンプレートを参考に必要な環境変数を設定：

```bash
# === 基本設定 ===
HOST=0.0.0.0
PORT=3080
NODE_ENV=development

# === データベース ===
MONGO_URI=mongodb://mongodb:27017/LibreChat
DATABASE_URL=postgresql://myuser:mypassword@vectordb:5432/mydatabase

# === セキュリティ ===
# 開発環境用のデフォルト値（本番環境では必ず変更）
JWT_SECRET=dev_jwt_secret_change_in_production_32_chars_min
JWT_REFRESH_SECRET=dev_jwt_refresh_secret_change_in_production_32_chars_min
CREDS_KEY=dev_creds_key_change_in_production_32_chars_min
CREDS_IV=dev_creds_iv_16

# === 検索エンジン ===
MEILI_HOST=http://meilisearch:7700
MEILI_MASTER_KEY=5c71cf56d672d009e36070b5bc5e47b743535ae55c818ae3b735bb6ebfb4ba63

# === RAG API ===
RAG_PORT=8000
RAG_API_URL=http://rag_api:8000

# === 認証設定 ===
ALLOW_EMAIL_LOGIN=true
ALLOW_REGISTRATION=true
```

詳細な環境変数の説明については、`SECRETS-TEMPLATE.md`を参照してください。

## 開発コマンド

コンテナ内で以下のコマンドが使用できます：

```bash
# バックエンド開発サーバー起動
npm run backend:dev

# フロントエンド開発サーバー起動
npm run frontend:dev

# テスト実行
npm run test:api
npm run test:client

# E2Eテスト
npm run e2e
```

## トラブルシューティング

### ポートが既に使用されている場合

`.devcontainer/devcontainer.json`の`forwardPorts`を編集して、使用可能なポートに変更してください。

### サービスが起動しない場合

```bash
docker-compose -f .devcontainer/docker-compose.yml ps
```

でサービスの状態を確認してください。

### node_modulesの同期問題

コンテナを再ビルドしてください：
1. コマンドパレットで "Dev Containers: Rebuild Container" を選択

