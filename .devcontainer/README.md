# LibreChat DevContainer セットアップガイド

## 概要

このディレクトリには、LibreChatを開発するためのDevContainer設定が含まれています。

## 前提条件

- Docker Desktop（Windows/Mac）またはDocker Engine（Linux）がインストールされていること
- VS Codeに「Dev Containers」拡張機能がインストールされていること

## セットアップ手順

### 1. Docker Desktopの起動

Windows/Macの場合、Docker Desktopを起動してください。

### 2. VS CodeでDevContainerを開く

1. VS Codeでこのプロジェクトを開く
2. コマンドパレット（`Ctrl+Shift+P` / `Cmd+Shift+P`）を開く
3. 「Dev Containers: Reopen in Container」を選択
4. 初回起動時は、コンテナのビルドとセットアップに数分かかります

### 3. 自動セットアップ

DevContainerが起動すると、以下のコマンドが自動実行されます：

- `npm ci` - 依存関係のインストール
- `npm run build:data-provider` - データプロバイダーのビルド
- `npm run build:data-schemas` - データスキーマのビルド
- `npm run build:api` - APIのビルド
- `npm run build:client-package` - クライアントパッケージのビルド

### 4. 開発サーバーの起動

DevContainer内のターミナルで以下のコマンドを実行：

```bash
# バックエンドサーバー（開発モード）
npm run backend:dev

# 別のターミナルでフロントエンドサーバー（開発モード）
npm run frontend:dev
```

### 5. アクセス

- LibreChat: http://localhost:3080
- MongoDB: localhost:27017（コンテナ内からのみアクセス可能）
- Meilisearch: localhost:7700（コンテナ内からのみアクセス可能）

## 含まれるサービス

### app（メインコンテナ）
- Node.js 18環境
- プロジェクトのソースコードが `/workspaces` にマウント
- vscodeユーザーで実行

### mongodb
- MongoDBデータベース
- データは `.devcontainer/data-node` に永続化

### meilisearch
- Meilisearch検索エンジン
- データは `.devcontainer/meili_data_v1.5` に永続化

## トラブルシューティング

### コンテナが起動しない

1. Docker Desktopが起動しているか確認
2. ポート3080、27017、7700が使用されていないか確認
3. `.devcontainer/docker-compose.yml` の設定を確認

### 依存関係のインストールに失敗する

```bash
# コンテナ内で手動実行
npm ci
```

### ビルドエラーが発生する

```bash
# 各パッケージを個別にビルド
npm run build:data-provider
npm run build:data-schemas
npm run build:api
npm run build:client-package
```

### ポートが既に使用されている

`.devcontainer/docker-compose.yml` のポート設定を変更するか、既存のプロセスを停止してください。

## 開発時の注意事項

- コンテナ内でファイルを編集すると、ホストマシンにも反映されます
- データベースのデータは `.devcontainer/data-node` に保存されます
- コンテナを削除すると、データも削除されます（永続化ボリュームを除く）

## 参考リンク

- [LibreChat公式ドキュメント](https://docs.librechat.ai/)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)




