.PHONY: help build up down restart logs shell clean test verify

# Default target
help:
	@echo "OpenClaw Docker Build Commands"
	@echo "==============================="
	@echo ""
	@echo "Building:"
	@echo "  make build          - Build all Docker images"
	@echo "  make build-nocache  - Build without using cache (clean build)"
	@echo "  make build-beta     - Build with OpenClaw beta version"
	@echo ""
	@echo "Running:"
	@echo "  make up             - Start all services (detached)"
	@echo "  make down           - Stop and remove all services"
	@echo "  make restart        - Restart all services"
	@echo ""
	@echo "Monitoring:"
	@echo "  make logs           - View logs from all services"
	@echo "  make logs-openclaw  - View only OpenClaw logs"
	@echo "  make status         - Show status of all services"
	@echo ""
	@echo "Access:"
	@echo "  make shell          - Open a shell in the OpenClaw container"
	@echo "  make token          - Show the access token from logs"
	@echo "  make approve        - Run openclaw-approve to approve device"
	@echo "  make onboard        - Run openclaw onboard wizard"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean          - Remove stopped containers and unused images"
	@echo "  make clean-all      - Remove all containers, images, and volumes (CAUTION)"
	@echo "  make verify         - Verify the build and installation"
	@echo "  make test           - Run tests (if available)"
	@echo ""
	@echo "Environment:"
	@echo "  make env            - Create .env from .env.example"
	@echo ""

# Build targets
build:
	docker compose build

build-nocache:
	docker compose build --no-cache

build-beta:
	docker compose build --build-arg OPENCLAW_BETA=true

# Running targets
up:
	docker compose up -d
	@echo ""
	@echo "✅ Services started! Run 'make logs' to view output"
	@echo "   or 'make token' to get your access token"

down:
	docker compose down

restart:
	docker compose restart

# Monitoring targets
logs:
	docker compose logs -f

logs-openclaw:
	docker compose logs -f openclaw

status:
	docker compose ps

# Access targets
shell:
	docker compose exec openclaw bash

token:
	@echo "🔑 Searching for access token in logs..."
	@docker compose logs openclaw 2>/dev/null | grep -A2 "Access Token" || echo "⚠️  Token not found. Service may still be starting. Try 'make logs'"

approve:
	docker compose exec openclaw openclaw-approve

onboard:
	docker compose exec openclaw openclaw onboard

# Maintenance targets
clean:
	docker compose down
	docker system prune -f
	@echo "✅ Cleaned up stopped containers and unused images"

clean-all:
	@echo "⚠️  WARNING: This will remove ALL data including volumes!"
	@echo "   Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	docker compose down -v
	docker system prune -a -f --volumes
	@echo "✅ All data cleaned"

verify:
	@echo "🔍 Verifying OpenClaw installation..."
	@docker compose exec openclaw bash -c "command -v openclaw && echo '✅ OpenClaw CLI found'" || echo "❌ OpenClaw CLI not found"
	@docker compose exec openclaw bash -c "command -v docker && echo '✅ Docker CLI found'" || echo "❌ Docker CLI not found"
	@docker compose exec openclaw bash -c "command -v gh && echo '✅ GitHub CLI found'" || echo "❌ GitHub CLI not found"
	@docker compose exec openclaw bash -c "command -v go && echo '✅ Go found'" || echo "❌ Go not found"
	@docker compose exec openclaw bash -c "command -v bun && echo '✅ Bun found'" || echo "❌ Bun not found"
	@docker compose exec openclaw bash -c "command -v python3 && echo '✅ Python found'" || echo "❌ Python not found"
	@echo "✅ Verification complete"

test:
	@echo "Running validation tests..."
	@docker compose exec openclaw bash -c "openclaw --version" || echo "❌ OpenClaw version check failed"
	@echo "✅ Tests complete"

# Environment setup
env:
	@if [ -f .env ]; then \
		echo "⚠️  .env already exists. Remove it first if you want to recreate it."; \
	else \
		cp .env.example .env; \
		echo "✅ Created .env from .env.example"; \
		echo "   Don't forget to edit .env and add your API keys!"; \
	fi

# Install (convenience target for first-time setup)
install: env build up
	@echo ""
	@echo "🎉 Installation complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit .env and add your API keys"
	@echo "2. Run 'make restart' to apply changes"
	@echo "3. Run 'make token' to get your access token"
	@echo "4. Run 'make approve' to approve your device"
	@echo ""
