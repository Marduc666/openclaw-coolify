#!/usr/bin/env bash
# verify-build.sh - Verify OpenClaw Docker build
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "🔍 OpenClaw Build Verification"
echo "======================================"
echo ""

# Function to check command exists
check_command() {
    local cmd=$1
    local name=$2
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name found${NC} ($(command -v "$cmd"))"
        return 0
    else
        echo -e "${RED}❌ $name NOT found${NC}"
        return 1
    fi
}

# Function to check if service is running
check_service() {
    local service=$1
    if docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
        echo -e "${GREEN}✅ Service '$service' is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Service '$service' is NOT running${NC}"
        return 1
    fi
}

ERRORS=0

# Check if we're in the right directory
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${RED}❌ docker-compose.yaml not found. Run this script from the repository root.${NC}"
    exit 1
fi

echo "📋 Checking Prerequisites..."
echo "-----------------------------------"

# Check Docker
if ! check_command docker "Docker"; then
    echo -e "${YELLOW}⚠️  Install Docker: https://docs.docker.com/get-docker/${NC}"
    ((ERRORS++))
fi

# Check Docker Compose
if ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose NOT found${NC}"
    echo -e "${YELLOW}⚠️  Install Docker Compose: https://docs.docker.com/compose/install/${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ Docker Compose found${NC} ($(docker compose version))"
fi

echo ""
echo "📦 Checking Configuration Files..."
echo "-----------------------------------"

# Check .dockerignore
if [ -f ".dockerignore" ]; then
    echo -e "${GREEN}✅ .dockerignore exists${NC}"
else
    echo -e "${YELLOW}⚠️  .dockerignore not found (recommended)${NC}"
fi

# Check .env file
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
    
    # Check for at least one API key
    if grep -q "OPENAI_API_KEY=.\+" .env || \
       grep -q "ANTHROPIC_API_KEY=.\+" .env || \
       grep -q "GEMINI_API_KEY=.\+" .env || \
       grep -q "MINIMAX_API_KEY=.\+" .env; then
        echo -e "${GREEN}✅ At least one API key is configured${NC}"
    else
        echo -e "${YELLOW}⚠️  No API keys found in .env. Add at least one AI provider key.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .env file not found. Copy from .env.example:${NC}"
    echo "   cp .env.example .env"
fi

echo ""
echo "🐳 Checking Docker Images..."
echo "-----------------------------------"

# Check if images exist
if docker images | grep -q "openclaw-coolify[-_]openclaw"; then
    echo -e "${GREEN}✅ OpenClaw image exists${NC}"
    docker images | grep "openclaw-coolify[-_]openclaw" | head -1
else
    echo -e "${YELLOW}⚠️  OpenClaw image not built yet. Run: make build${NC}"
fi

if docker images | grep -q "openclaw-coolify[-_]searxng"; then
    echo -e "${GREEN}✅ SearXNG image exists${NC}"
else
    echo -e "${YELLOW}⚠️  SearXNG image not built yet.${NC}"
fi

echo ""
echo "🚀 Checking Running Services..."
echo "-----------------------------------"

# Check if services are running
if docker compose ps 2>/dev/null | grep -q "Up"; then
    echo "Services status:"
    docker compose ps
    echo ""
    
    # Check individual services
    check_service "openclaw" || ((ERRORS++))
    check_service "docker-proxy" || ((ERRORS++))
    check_service "searxng" || ((ERRORS++))
else
    echo -e "${YELLOW}⚠️  No services are currently running. Start with: make up${NC}"
fi

echo ""
echo "🔧 Checking Container Tools (if running)..."
echo "-----------------------------------"

if docker compose ps openclaw 2>/dev/null | grep -q "Up"; then
    # Check tools inside container
    echo "Checking tools inside OpenClaw container..."
    
    docker compose exec -T openclaw bash -c "command -v openclaw" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ openclaw CLI installed${NC}" || \
        echo -e "${RED}❌ openclaw CLI NOT found${NC}"
    
    docker compose exec -T openclaw bash -c "command -v docker" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ docker CLI installed${NC}" || \
        echo -e "${RED}❌ docker CLI NOT found${NC}"
    
    docker compose exec -T openclaw bash -c "command -v gh" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ GitHub CLI installed${NC}" || \
        echo -e "${RED}❌ GitHub CLI NOT found${NC}"
    
    docker compose exec -T openclaw bash -c "command -v go" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ Go installed${NC}" || \
        echo -e "${RED}❌ Go NOT found${NC}"
    
    docker compose exec -T openclaw bash -c "command -v bun" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ Bun installed${NC}" || \
        echo -e "${RED}❌ Bun NOT found${NC}"
    
    docker compose exec -T openclaw bash -c "command -v python3" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ Python installed${NC}" || \
        echo -e "${RED}❌ Python NOT found${NC}"
    
    docker compose exec -T openclaw bash -c "command -v cloudflared" >/dev/null 2>&1 && \
        echo -e "${GREEN}✅ Cloudflared installed${NC}" || \
        echo -e "${RED}❌ Cloudflared NOT found${NC}"
else
    echo -e "${YELLOW}⚠️  OpenClaw container not running. Start with: make up${NC}"
fi

echo ""
echo "📁 Checking Docker Volumes..."
echo "-----------------------------------"

# Check volumes
if docker volume ls | grep -q "openclaw-data"; then
    echo -e "${GREEN}✅ openclaw-data volume exists${NC}"
else
    echo -e "${YELLOW}⚠️  openclaw-data volume not created yet${NC}"
fi

if docker volume ls | grep -q "openclaw-config"; then
    echo -e "${GREEN}✅ openclaw-config volume exists${NC}"
else
    echo -e "${YELLOW}⚠️  openclaw-config volume not created yet${NC}"
fi

if docker volume ls | grep -q "openclaw-workspace"; then
    echo -e "${GREEN}✅ openclaw-workspace volume exists${NC}"
else
    echo -e "${YELLOW}⚠️  openclaw-workspace volume not created yet${NC}"
fi

echo ""
echo "======================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Verification PASSED!${NC}"
    echo ""
    echo "Everything looks good! 🎉"
    echo ""
    echo "Next steps:"
    echo "  1. If not running: make up"
    echo "  2. View logs: make logs"
    echo "  3. Get token: make token"
    echo "  4. Approve device: make approve"
else
    echo -e "${RED}❌ Verification found $ERRORS issue(s)${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
fi
echo "======================================"

exit $ERRORS
