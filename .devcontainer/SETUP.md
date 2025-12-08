# LibreChat DevContainer ローカル動作確認セットアップガイド

このガイドでは、DevContainerを使用してローカルでLibreChatアプリを動作確認する手順を説明します。

## 📋 前提条件

- VS Codeがインストールされていること
- VS Code拡張機能「Dev Containers」がインストールされていること
- Docker Desktopがインストールされ、起動していること

## 🚀 セットアップ手順

### ステップ1: DevContainerを開く

1. VS Codeでこのプロジェクトを開く
2. コマンドパレットを開く（`Ctrl+Shift+P` / `Cmd+Shift+P`）
3. **"Dev Containers: Reopen in Container"** を選択
4. 初回はコンテナのビルドに時間がかかります（5-10分程度）

### ステップ2: 環境変数ファイルの作成

コンテナが起動したら、プロジェクトルートに`.env`ファイルを作成します：

```bash
# コンテナ内のターミナルで実行
cp .devcontainer/env.template .env
```

### ステップ3: 環境変数の設定（オプション）

`.env`ファイルを編集して、必要に応じて設定を変更します：

```bash
# エディタで開く
code .env
```

**最低限必要な設定:**
- `PORT=3080` - APIサーバーのポート（デフォルトでOK）
- `MONGO_URI=mongodb://mongodb:27017/LibreChat` - MongoDB接続（DevContainer用に設定済み）
- `MEILI_HOST=http://meilisearch:7700` - Meilisearch接続（DevContainer用に設定済み）

**AI機能を使用する場合:**
- `OPENAI_API_KEY=your_key_here` - OpenAI APIキー
- `ANTHROPIC_API_KEY=your_key_here` - Anthropic APIキー
- その他のAIプロバイダーのAPIキー

### ステップ4: アプリケーションの起動

#### 方法1: 起動スクリプトを使用（推奨）

```bash
bash .devcontainer/start-app.sh
```

スクリプトが対話形式で起動方法を選択できます。

#### 方法2: 手動で起動

**バックエンドのみ起動:**
```bash
npm run backend:dev
```
- APIサーバー: http://localhost:3080

**フロントエンドのみ起動:**
```bash
npm run frontend:dev
```
- 開発サーバー: http://localhost:3000

**両方起動（推奨）:**
VS Codeの統合ターミナルを2つ開いて、それぞれで実行：

**ターミナル1:**
```bash
npm run backend:dev
```

**ターミナル2:**
```bash
npm run frontend:dev
```

### ステップ5: ブラウザでアクセス

1. フロントエンド: http://localhost:3000
2. API: http://localhost:3080

## 🔧 トラブルシューティング

### ポートが既に使用されている

`.devcontainer/devcontainer.json`の`forwardPorts`を編集して、使用可能なポートに変更してください。

### サービスに接続できない

DevContainerのdocker-composeサービスが起動しているか確認：

```bash
docker-compose -f .devcontainer/docker-compose.yml ps
```

すべてのサービスが`Up`状態であることを確認してください。

### MongoDB接続エラー

```bash
# MongoDBコンテナのログを確認
docker-compose -f .devcontainer/docker-compose.yml logs mongodb
```

### 依存関係のインストールエラー

```bash
# 依存関係を再インストール
npm install
```

### ビルドエラー

```bash
# パッケージを再ビルド
npm run build:data-provider
npm run build:data-schemas
npm run build:api
```

## 📚 便利なコマンド

### 開発コマンド

```bash
# バックエンド開発サーバー
npm run backend:dev

# フロントエンド開発サーバー
npm run frontend:dev

# テスト実行
npm run test:api          # APIテスト
npm run test:client       # クライアントテスト
npm run e2e               # E2Eテスト

# リント
npm run lint              # リントチェック
npm run lint:fix          # リント自動修正
```

### データベース操作

```bash
# ユーザー作成
npm run create-user

# ユーザー一覧
npm run list-users

# パスワードリセット
npm run reset-password
```

## 🌐 アクセスURL

- **フロントエンド（開発）**: http://localhost:3000
- **APIサーバー**: http://localhost:3080
- **MongoDB**: localhost:27017
- **Meilisearch**: http://localhost:7700
- **PostgreSQL**: localhost:5432
- **RAG API**: http://localhost:8000

## 📝 注意事項

1. **初回起動時**: `post-create.sh`スクリプトが自動実行され、セットアップが行われます
2. **環境変数**: `.env`ファイルはGit管理対象外です。機密情報を含むため、共有しないでください
3. **データ永続化**: MongoDB、Meilisearch、PostgreSQLのデータは`.devcontainer/`ディレクトリ内に保存されます
4. **ポート競合**: 他のアプリケーションが同じポートを使用している場合、エラーが発生します

## 🎉 次のステップ

アプリが起動したら：

1. ブラウザで http://localhost:3000 にアクセス
2. 初回はユーザー登録が必要です
3. AI機能を使用する場合は、`.env`ファイルにAPIキーを設定してください

問題が発生した場合は、`.devcontainer/README.md`も参照してください。








