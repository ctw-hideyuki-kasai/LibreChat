#!/bin/bash
# LibreChat アプリ起動スクリプト
# DevContainer内で使用

set -e

echo "🚀 LibreChat アプリ起動スクリプト"
echo "=================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# .envファイルの確認
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC}  .envファイルが見つかりません"
    echo "   .devcontainer/env.templateをコピーして.envファイルを作成してください"
    echo "   コマンド: cp .devcontainer/env.template .env"
    exit 1
fi

# librechat.yamlの確認
if [ ! -f "librechat.yaml" ]; then
    echo -e "${YELLOW}⚠${NC}  librechat.yamlファイルが見つかりません"
    if [ -f "librechat.example.yaml" ]; then
        echo "   librechat.example.yamlからコピーします..."
        cp librechat.example.yaml librechat.yaml
        echo -e "${GREEN}✓${NC}  librechat.yamlを作成しました"
    else
        echo "   librechat.yamlファイルが必要です"
        exit 1
    fi
fi

# サービスが起動しているか確認
echo ""
echo "🔍 依存サービスの確認中..."

# MongoDB接続確認
if ! timeout 5 bash -c "echo > /dev/tcp/mongodb/27017" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  MongoDBに接続できません。DevContainerのdocker-composeサービスが起動しているか確認してください"
else
    echo -e "${GREEN}✓${NC}  MongoDB接続OK"
fi

# Meilisearch接続確認
if ! curl -s http://meilisearch:7700/health > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC}  Meilisearchに接続できません"
else
    echo -e "${GREEN}✓${NC}  Meilisearch接続OK"
fi

echo ""
echo "=================================="
echo -e "${BLUE}📋 起動オプション:${NC}"
echo ""
echo "1. バックエンドのみ起動:"
echo "   npm run backend:dev"
echo ""
echo "2. フロントエンドのみ起動:"
echo "   npm run frontend:dev"
echo ""
echo "3. 両方起動（別ターミナルで実行）:"
echo "   ターミナル1: npm run backend:dev"
echo "   ターミナル2: npm run frontend:dev"
echo ""
echo "=================================="
echo ""
read -p "起動方法を選択してください (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}🚀 バックエンドサーバーを起動します...${NC}"
        echo "   API: http://localhost:3080"
        npm run backend:dev
        ;;
    2)
        echo ""
        echo -e "${GREEN}🚀 フロントエンド開発サーバーを起動します...${NC}"
        echo "   Client: http://localhost:3000"
        npm run frontend:dev
        ;;
    3)
        echo ""
        echo -e "${YELLOW}⚠${NC}  別々のターミナルで以下を実行してください:"
        echo ""
        echo "   ターミナル1: npm run backend:dev"
        echo "   ターミナル2: npm run frontend:dev"
        echo ""
        echo "   または、VS Codeの統合ターミナルを2つ開いて実行してください"
        ;;
    *)
        echo "無効な選択です"
        exit 1
        ;;
esac








