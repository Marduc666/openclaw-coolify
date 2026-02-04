# Building OpenClaw Docker Image - Beginner's Guide

This guide will help you build and run the OpenClaw Docker image from scratch. No prior Docker experience required!

## Prerequisites

Before you begin, make sure you have installed:

1. **Docker** - [Install Docker](https://docs.docker.com/get-docker/)
2. **Docker Compose** - Usually comes with Docker Desktop

To verify your installation, run:
```bash
docker --version
docker compose version
```

## Quick Start (Recommended)

The easiest way to build and run OpenClaw:

### Option 1: Using Make (Simplest)

```bash
# Build the image
make build

# Start all services
make up

# View logs
make logs

# Stop services
make down
```

### Option 2: Using Docker Compose

```bash
# Build and start all services
docker compose up --build -d

# View logs
docker compose logs -f openclaw

# Stop all services
docker compose down
```

### Option 3: Manual Docker Build

```bash
# Build just the OpenClaw image
docker build -t openclaw:latest .

# Run the container manually (advanced)
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  -v openclaw-data:/data \
  -v openclaw-config:/root/.openclaw \
  -v openclaw-workspace:/root/openclaw-workspace \
  openclaw:latest
```

## Environment Configuration

Before building, copy the example environment file:

```bash
cp .env.example .env
```

Then edit `.env` and add your API keys:

```bash
# Required: At least one AI provider
OPENAI_API_KEY=your_openai_key_here
# or
ANTHROPIC_API_KEY=your_claude_key_here
# or
GEMINI_API_KEY=your_gemini_key_here

# Optional: For Telegram integration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# Optional: For GitHub integration
GITHUB_TOKEN=your_github_token
GITHUB_USERNAME=your_github_username
GITHUB_EMAIL=your_email@example.com
```

## Understanding the Build Process

### What Gets Built?

1. **Main OpenClaw Container** (`openclaw` service)
   - Based on Node.js LTS (Debian Bookworm)
   - Includes Python, Go, and various development tools
   - Pre-installs the OpenClaw CLI and dependencies
   - Configures workspace and data persistence

2. **SearXNG Search Engine** (`searxng` service)
   - Private, tracking-free search engine
   - Used by OpenClaw for web searches

3. **Docker Socket Proxy** (`docker-proxy` service)
   - Secure proxy for Docker API access
   - Allows OpenClaw to create sandboxed containers safely

4. **Container Registry** (`registry` service)
   - Local Docker registry for caching images

### Build Arguments

You can customize the build with these arguments:

```bash
# Build with beta version of OpenClaw
docker compose build --build-arg OPENCLAW_BETA=true

# Specify a different Go version
docker compose build --build-arg GO_VERSION=1.23.5

# Change the gateway port
docker compose build --build-arg OPENCLAW_GATEWAY_PORT=8080
```

## Post-Build: First Run

After building successfully:

1. **Start the services:**
   ```bash
   docker compose up -d
   ```

2. **Check the logs for your access token:**
   ```bash
   docker compose logs openclaw | grep "Access Token"
   ```

3. **Access the dashboard:**
   - Look for the line: `🔑 Access Token: <your-token>`
   - Open: `http://localhost:18789?token=<your-token>`

4. **Approve your device:**
   ```bash
   docker compose exec openclaw openclaw-approve
   ```

5. **Run onboarding (optional):**
   ```bash
   docker compose exec openclaw openclaw onboard
   ```

## Troubleshooting

### Build Fails

**Issue:** "npm install -g openclaw" fails

**Solution:** 
- Check your internet connection
- Try building without cache: `docker compose build --no-cache`
- Check if you're behind a proxy

**Issue:** "Permission denied" errors

**Solution:**
- On Linux, add your user to the docker group:
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker
  ```

### Container Won't Start

**Issue:** Container exits immediately

**Solution:**
1. Check logs: `docker compose logs openclaw`
2. Ensure required environment variables are set in `.env`
3. Check if port 18789 is already in use: `lsof -i :18789`

**Issue:** "Cannot connect to Docker daemon"

**Solution:**
- Make sure Docker Desktop is running
- On Linux: `sudo systemctl start docker`

### Out of Disk Space

Docker images can be large. To clean up:

```bash
# Remove unused images
docker image prune -a

# Remove all unused data (be careful!)
docker system prune -a --volumes
```

## Development & Testing

### Testing Your Changes

After modifying the Dockerfile or scripts:

```bash
# Rebuild only the changed service
docker compose build openclaw

# Restart the service
docker compose up -d openclaw

# Check logs
docker compose logs -f openclaw
```

### Validating the Build

Run the build verification script:

```bash
./scripts/verify-build.sh
```

This checks:
- ✅ All required tools are installed
- ✅ OpenClaw binary is accessible
- ✅ Configuration is valid
- ✅ Volumes are properly mounted

## Production Deployment

### Deploy to Coolify

1. Fork this repository to your GitHub account
2. In Coolify:
   - Create a new Project
   - Select "Public Repository"
   - Enter your repository URL
   - Coolify will automatically detect `coolify.json` and deploy

### Environment Variables in Coolify

In Coolify, add these environment variables:
- `OPENAI_API_KEY` (or another AI provider)
- `SERVICE_FQDN_OPENCLAW` (auto-set by Coolify)
- `GITHUB_TOKEN` (optional, for GitHub integration)
- `TELEGRAM_BOT_TOKEN` (optional, for Telegram)

### Security Best Practices

1. **Never commit `.env` to Git** - it contains secrets
2. **Rotate your access token regularly**
3. **Use strong API keys**
4. **Keep Docker images updated**
   ```bash
   docker compose pull
   docker compose up -d
   ```

## Advanced Topics

### Multi-Stage Builds

The current Dockerfile uses a single-stage build. For smaller images, consider:
- Splitting build dependencies from runtime
- Using Alpine-based images
- Removing build tools after installation

### Custom Skills

Add custom skills to the `skills/` directory:

```bash
skills/
  my-custom-skill/
    SKILL.md          # Instructions for the AI
    scripts/          # Helper scripts
    package.json      # Dependencies (optional)
```

### Updating OpenClaw

To update to the latest version:

```bash
# Update to latest stable
docker compose build --build-arg OPENCLAW_BETA=false --no-cache

# Update to latest beta
docker compose build --build-arg OPENCLAW_BETA=true --no-cache
```

## Resources

- **GitHub Repository:** [Marduc666/openclaw-coolify](https://github.com/Marduc666/openclaw-coolify)
- **Docker Documentation:** [docs.docker.com](https://docs.docker.com/)
- **Docker Compose Documentation:** [docs.docker.com/compose/](https://docs.docker.com/compose/)
- **Troubleshooting:** Check the GitHub Issues page for common problems and solutions

## Getting Help

If you run into issues:

1. Check the logs: `docker compose logs openclaw`
2. Review this guide's Troubleshooting section
3. Check existing GitHub Issues
4. Create a new issue with:
   - Your Docker version
   - The command you ran
   - The full error message
   - Relevant logs

---

**Happy Building! 🚀**

Remember: Building Docker images takes time on the first run. Subsequent builds will be faster due to layer caching.
