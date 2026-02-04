# Quick Start Guide - For Complete Beginners

Welcome to OpenClaw! This guide will help you get started even if you've never used Docker before.

## What You'll Need

- A computer (Windows, Mac, or Linux)
- About 30 minutes
- An internet connection

## Step 1: Install Docker

### Windows & Mac
1. Go to [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Download and install Docker Desktop for your operating system
3. Open Docker Desktop and wait for it to start (you'll see a whale icon)

### Linux
Open a terminal and run:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```
Then log out and log back in.

**Verify Installation:**
Open a terminal (or Command Prompt on Windows) and type:
```bash
docker --version
```
You should see something like "Docker version 24.x.x"

## Step 2: Get the Code

### Option A: Download ZIP (Easier)
1. Go to https://github.com/Marduc666/openclaw-coolify
2. Click the green "Code" button
3. Select "Download ZIP"
4. Extract the ZIP file to a folder (e.g., Desktop/openclaw)

### Option B: Use Git (Recommended)
```bash
git clone https://github.com/Marduc666/openclaw-coolify.git
cd openclaw-coolify
```

## Step 3: Configure API Keys

You need at least one AI provider API key. Here's how to get them:

### Get an OpenAI API Key (Easiest)
1. Go to [platform.openai.com](https://platform.openai.com/)
2. Sign up or log in
3. Go to API Keys section
4. Create a new key
5. Copy it (you won't see it again!)

### Other Options (Pick One)
- **Anthropic Claude**: [console.anthropic.com](https://console.anthropic.com/)
- **Google Gemini**: [ai.google.dev](https://ai.google.dev/)

### Add Your Key

1. Open the project folder
2. Copy `.env.example` and rename it to `.env`
3. Open `.env` in a text editor (Notepad, TextEdit, etc.)
4. Find the line `OPENAI_API_KEY=` and add your key after the `=`
   ```
   OPENAI_API_KEY=sk-proj-abc123yourkey
   ```
5. Save the file

**Using Terminal:**
```bash
cp .env.example .env
# Then edit .env with your favorite editor
nano .env  # or vim, or code, etc.
```

## Step 4: Build and Start OpenClaw

### Using Make (Recommended - Mac/Linux)

```bash
# Build everything
make build

# Start the services
make up

# View the logs to find your access token
make logs
```

### Using Docker Compose (Windows/Mac/Linux)

```bash
# Build and start
docker compose up --build -d

# View logs
docker compose logs -f openclaw
```

**Wait Time:** The first build takes 10-20 minutes depending on your internet speed. Grab a coffee! ☕

## Step 5: Access OpenClaw

1. **Find Your Access Token**
   
   Look in the logs for something like:
   ```
   🔑 Access Token: a1b2c3d4e5f6...
   ```

2. **Open Your Browser**
   
   Go to: `http://localhost:18789?token=YOUR_TOKEN_HERE`
   
   (Replace YOUR_TOKEN_HERE with the actual token from step 1)

3. **Approve Your Device**
   
   In a terminal, run:
   ```bash
   docker compose exec openclaw openclaw-approve
   ```
   
   Or with Make:
   ```bash
   make approve
   ```

## Step 6: Start Using OpenClaw

You should now see the OpenClaw dashboard in your browser!

### Optional: Run Onboarding

To configure your AI assistant's personality:

```bash
make onboard
# or
docker compose exec openclaw openclaw onboard
```

### Optional: Connect Telegram

1. Open Telegram and talk to [@BotFather](https://t.me/botfather)
2. Create a new bot with `/newbot`
3. Copy the token you receive
4. Add it to your `.env` file:
   ```
   TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
   ```
5. Restart OpenClaw:
   ```bash
   make restart
   # or
   docker compose restart
   ```

## Common Issues

### "Cannot connect to Docker daemon"
- **Solution**: Make sure Docker Desktop is running (check the system tray)

### "Port 18789 is already in use"
- **Solution**: Something else is using that port. Either:
  1. Stop the other program, or
  2. Change the port in `.env`:
     ```
     OPENCLAW_GATEWAY_PORT=19000
     ```

### "docker: command not found"
- **Solution**: Docker isn't installed or not in your PATH
  - Reinstall Docker Desktop
  - On Linux, make sure you logged out and back in after installation

### Build is Taking Forever
- **Solution**: This is normal for the first build! It's downloading:
  - Node.js
  - Python
  - Go
  - Chrome
  - Many development tools
  
  Subsequent builds will be much faster.

### "No API key configured"
- **Solution**: Make sure you:
  1. Created the `.env` file (not `.env.example`)
  2. Added your API key correctly
  3. Restarted the services

## Useful Commands

```bash
# See what's running
docker compose ps

# View logs
docker compose logs -f openclaw

# Stop everything
docker compose down

# Restart after changes
docker compose restart

# Get a shell inside the container
docker compose exec openclaw bash

# Remove everything and start fresh
docker compose down -v
```

## Using Make (Easier)

If you have `make` installed:

```bash
make help          # See all commands
make build         # Build images
make up            # Start services
make down          # Stop services
make logs          # View logs
make token         # Show access token
make approve       # Approve device
make shell         # Open shell
make verify        # Verify installation
```

## Next Steps

1. **Read the Full Guide**: Check out [BUILD.md](BUILD.md) for advanced topics
2. **Explore Skills**: Add new capabilities via ClawHub
3. **Connect Channels**: Link WhatsApp, Discord, Slack
4. **Deploy to Cloud**: Use Coolify for public access

## Getting Help

If you're stuck:

1. Check the logs: `docker compose logs openclaw`
2. Look for errors in red
3. Search or create an issue on GitHub
4. Include:
   - What you were trying to do
   - The exact error message
   - Your operating system

## Security Tips

- ✅ Never commit your `.env` file to Git
- ✅ Keep your API keys secret
- ✅ Only approve devices you recognize
- ✅ Use strong tokens
- ✅ Update regularly: `docker compose pull && docker compose up -d`

---

**Congratulations!** 🎉 You now have your own private AI assistant running!

Need more help? Check out:
- [BUILD.md](BUILD.md) - Detailed build documentation
- [README.md](README.md) - Project overview and features
- [BOOTSTRAP.md](BOOTSTRAP.md) - For developers
