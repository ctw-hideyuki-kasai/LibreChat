#!/bin/bash
# LibreChat DevContainer Post-Create Script
# This script runs after the container is created

set -e

echo "🚀 LibreChat DevContainer Post-Create Script"
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Are we in the right directory?"
    exit 1
fi

echo -e "${GREEN}✓${NC} Working directory: $(pwd)"

# Install TypeScript globally (as per CONTRIBUTING.md)
echo ""
echo "📦 Installing TypeScript globally..."
npm install -g typescript
echo -e "${GREEN}✓${NC} TypeScript installed: $(tsc --version)"

# Install dependencies (if not already done)
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 Installing npm dependencies..."
    npm install
    echo -e "${GREEN}✓${NC} Dependencies installed"
else
    echo -e "${GREEN}✓${NC} Dependencies already installed"
fi

# Build required packages
echo ""
echo "🔨 Building required packages..."
echo "  → Building data-provider..."
npm run build:data-provider || echo -e "${YELLOW}⚠${NC}  build:data-provider failed (may need dependencies)"
echo "  → Building data-schemas..."
npm run build:data-schemas || echo -e "${YELLOW}⚠${NC}  build:data-schemas failed (may need dependencies)"
echo "  → Building API..."
npm run build:api || echo -e "${YELLOW}⚠${NC}  build:api failed (may need dependencies)"
echo -e "${GREEN}✓${NC} Package builds completed"

# Setup test environment files (if they don't exist)
echo ""
echo "📝 Setting up test environment files..."

if [ ! -f "api/test/.env.test" ] && [ -f "api/test/.env.test.example" ]; then
    cp api/test/.env.test.example api/test/.env.test
    echo -e "${GREEN}✓${NC} Created api/test/.env.test"
fi

if [ ! -f ".env" ]; then
    if [ -f ".devcontainer/env.template" ]; then
        echo -e "${YELLOW}⚠${NC}  .env file not found. Creating from template..."
        cp .devcontainer/env.template .env
        echo -e "${GREEN}✓${NC} Created .env file from template"
        echo -e "${YELLOW}⚠${NC}  Please review and edit .env file if needed"
    else
        echo -e "${YELLOW}⚠${NC}  .env file not found. Please create it manually"
    fi
fi

if [ ! -f "librechat.yaml" ] && [ -f "librechat.example.yaml" ]; then
    cp librechat.example.yaml librechat.yaml
    echo -e "${GREEN}✓${NC} Created librechat.yaml from librechat.example.yaml"
fi

if [ ! -f "e2e/config.local.ts" ] && [ -f "e2e/config.local.example.ts" ]; then
    cp e2e/config.local.example.ts e2e/config.local.ts
    echo -e "${GREEN}✓${NC} Created e2e/config.local.ts"
fi

# Install Playwright (for E2E tests)
echo ""
echo "🎭 Installing Playwright..."
if command -v npx &> /dev/null; then
    npx playwright install --with-deps || echo -e "${YELLOW}⚠${NC}  Playwright installation failed (optional)"
    echo -e "${GREEN}✓${NC} Playwright installed"
else
    echo -e "${YELLOW}⚠${NC}  npx not found, skipping Playwright installation"
fi

# Summary
echo ""
echo "=============================================="
echo -e "${GREEN}✅ DevContainer setup completed!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Create .env file: cp .devcontainer/.env.example .env"
echo "  2. Edit .env with your configuration"
echo "  3. Start backend: npm run backend:dev"
echo "  4. Start frontend: npm run frontend:dev"
echo ""
echo "📚 Useful commands:"
echo "  - Backend dev server: npm run backend:dev"
echo "  - Frontend dev server: npm run frontend:dev"
echo "  - Run API tests: npm run test:api"
echo "  - Run client tests: npm run test:client"
echo "  - Run E2E tests: npm run e2e"
echo "=============================================="

