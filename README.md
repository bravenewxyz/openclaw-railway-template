# Moltbot Railway Template (1‑click deploy)

This repo packages **OpenClaw** for Railway with a comprehensive **/setup** web wizard so users can deploy and onboard **without running any commands**.

## What you get

- **OpenClaw Gateway + Control UI** (served at `/` and `/openclaw`)
- A powerful **Setup Wizard** at `/setup` (protected by a password) with:
  - **Debug Console** - Run openclaw commands without SSH
  - **Config Editor** - Edit openclaw.json with automatic backups
  - **Pairing Helper** - Approve devices via UI
  - **Plugin Management** - List and enable plugins
  - **Import/Export Backup** - Migrate configurations easily
- Persistent state via **Railway Volume** (so config/credentials/memory survive redeploys)
- **Public health endpoint** at `/healthz` for monitoring
- **Custom provider support** for Ollama, vLLM, and other OpenAI-compatible APIs
- **Flexible OpenClaw version control** via environment variable
- **Smart Railway proxy detection** for proper client IP handling

## Quick Start

1. **Deploy to Railway** using this template
2. Set required environment variables (see below)
3. Visit `https://your-app.up.railway.app/setup`
4. Complete the setup wizard
5. Start chatting at `/openclaw`

## Environment Variables

### Required

- **`SETUP_PASSWORD`** - Password to access `/setup` wizard

### Recommended

- **`OPENCLAW_STATE_DIR=/data/.openclaw`** - Config and credentials directory
- **`OPENCLAW_WORKSPACE_DIR=/data/workspace`** - Agent workspace directory
- **`OPENCLAW_GATEWAY_TOKEN`** - Stable auth token (auto-generated if not set)
- **`OPENCLAW_VERSION=v2026.2.15`** - Pin to a stable OpenClaw release (see [Version Control](#openclaw-version-control))

### Optional

- **`OPENCLAW_PUBLIC_PORT=8080`** - Wrapper HTTP port (default: 8080)
- **`PORT`** - Fallback if OPENCLAW_PUBLIC_PORT not set
- **`INTERNAL_GATEWAY_PORT=18789`** - Gateway internal port
- **`OPENCLAW_ENTRY`** - Path to openclaw entry.js (default: /openclaw/dist/entry.js)
- **`OPENCLAW_TEMPLATE_DEBUG=true`** - Enable debug logging (logs sensitive tokens)
- **`OPENCLAW_TRUST_PROXY_ALL=true`** - Trust all proxies (Railway auto-detected by default)

### Legacy (auto-migrated)

- `CLAWDBOT_*` variables automatically migrate to `OPENCLAW_*`
- `MOLTBOT_*` variables automatically migrate to `OPENCLAW_*`

## OpenClaw Version Control

The template supports flexible version control to prevent breakage from unstable OpenClaw releases:

### How It Works

Set the **`OPENCLAW_VERSION`** environment variable to control which OpenClaw version to build:

- **With `OPENCLAW_VERSION` set**: Uses that specific tag/branch (e.g., `v2026.2.15`)
- **Without `OPENCLAW_VERSION`**: Uses `main` branch (may be unstable)

### Recommended Configuration

```
OPENCLAW_VERSION=v2026.2.15
```

This pins your deployment to a known stable release, protecting you from upstream breakage.

### Use Cases

**Pin to Stable Release (Recommended)**
```
OPENCLAW_VERSION=v2026.2.15
```
Use when main branch is broken or to ensure consistent deployments.

**Use Latest Main (Advanced)**
```
(Leave OPENCLAW_VERSION unset)
```
Automatically uses latest main branch. Good for testing but may break unexpectedly.

**Test Specific Branch**
```
OPENCLAW_VERSION=feature-branch-name
```
Useful for testing unreleased features.

### Finding Available Versions

List all OpenClaw releases:
```bash
git ls-remote --tags https://github.com/openclaw/openclaw.git | grep -v '\^{}' | sed 's|.*refs/tags/||'
```

See **[OPENCLAW-VERSION-CONTROL.md](OPENCLAW-VERSION-CONTROL.md)** for detailed documentation.

## New Features in This Fork

### Debug Console 🔧
Run openclaw commands without SSH access:
- **Gateway lifecycle:** restart, stop, start
- **OpenClaw CLI:** version, status, health, doctor, logs
- **Config inspection:** get any config value
- **Device management:** list and approve pairing requests
- **Plugin management:** list and enable plugins
- **Strict allowlist:** Only 13 safe commands permitted

### Config Editor ✏️
- Edit `openclaw.json` directly in the browser
- Automatic timestamped backups before each save (`.bak-YYYY-MM-DDTHH-MM-SS-SSSZ`)
- Gateway auto-restart after changes
- Syntax highlighting (monospace font)
- 500KB safety limit with validation

### Pairing Helper 🔐
- List pending device pairing requests
- One-click approval via UI
- No SSH required
- Fixes "disconnected (1008): pairing required" errors

### Import/Export Backup 💾
- **Export:** Download `.tar.gz` of config + workspace
- **Import:** Restore from backup file (250MB max)
- Path traversal protection
- Perfect for migration or disaster recovery

### Custom Providers 🔌
Add OpenAI-compatible providers during setup:
- Ollama (local LLMs)
- vLLM (high-performance serving)
- LM Studio (desktop GUI)
- Any OpenAI-compatible API endpoint
- Support for environment variable API keys

### Better Diagnostics 📊
- Public `/healthz` endpoint (no auth required)
- `/setup/api/debug` for comprehensive diagnostics
- Automatic `openclaw doctor` on failures (5min rate limit)
- Detailed error messages with troubleshooting hints
- TCP-based gateway health probes (more reliable)

### Smart Railway Integration 🚂
- Auto-detects Railway environment via `RAILWAY_*` env vars
- Configures trusted proxies automatically for correct client IPs
- Secure localhost-only proxy trust (127.0.0.1)
- Optional override with `OPENCLAW_TRUST_PROXY_ALL`

### Enhanced Reliability 🛡️
- 60-second gateway readiness timeout (was 20s)
- Background health monitoring with automatic diagnostics
- Graceful shutdown handling (SIGTERM → SIGKILL escalation)
- Secret redaction in debug output (5 token patterns)
- Credentials directory with strict 700 permissions

## Railway Deploy Instructions

### Using Railway Template

1. Click "Deploy on Railway" button (if available)
2. Configure environment variables:

**Required:**
- `SETUP_PASSWORD` — Your chosen password for `/setup`

**Recommended:**
- `OPENCLAW_VERSION=v2026.2.15` — Pin to stable release
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`

3. Railway will automatically:
   - Create a volume at `/data`
   - Build from the Dockerfile
   - Enable public networking
   - Generate a domain like `your-app.up.railway.app`

### Manual Railway Setup

1. Create new project from GitHub repo
2. Add a **Volume** service mounted at `/data`
3. Set environment variables (see above)
4. Enable **Public Networking**
5. Deploy

Then:
- Visit `https://<your-app>.up.railway.app/setup` (password: your `SETUP_PASSWORD`)
- Complete setup wizard
- Visit `/openclaw` to start chatting

## Getting Chat Tokens

### Telegram bot token

1. Open Telegram and message **@BotFather**
2. Run `/newbot` and follow the prompts
3. BotFather will give you a token like: `123456789:AA...`
4. Paste that token into `/setup`

### Discord bot token

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. **New Application** → pick a name
3. Open the **Bot** tab → **Add Bot**
4. Copy the **Bot Token** and paste into `/setup`
5. **IMPORTANT:** Enable **MESSAGE CONTENT INTENT** in Bot settings (required)
6. Invite the bot to your server (OAuth2 URL Generator → scopes: `bot`, `applications.commands`)

## Troubleshooting

### "disconnected (1008): pairing required"

**Solution 1: Use Pairing Helper (UI)**
1. Visit `/setup`
2. Scroll to "Pairing helper" section
3. Click "Refresh pending devices"
4. Click "Approve" for each device

**Solution 2: Use Debug Console**
1. Select `openclaw.devices.list`
2. Note the requestId
3. Select `openclaw.devices.approve`
4. Enter requestId and click Run

### "Application failed to respond" / 502 Bad Gateway

1. Visit `/healthz` to check gateway status
2. Visit `/setup` → Debug Console
3. Run `openclaw doctor` command
4. Check `/setup/api/debug` for full diagnostics

**Common causes:**
- Gateway not started (check `/healthz` → `gateway.processRunning`)
- Volume not mounted at `/data`
- Missing `OPENCLAW_STATE_DIR` or `OPENCLAW_WORKSPACE_DIR` variables

### Gateway won't start

1. Verify volume is mounted at `/data`
2. Check environment variables:
   ```
   OPENCLAW_STATE_DIR=/data/.openclaw
   OPENCLAW_WORKSPACE_DIR=/data/workspace
   ```
3. Run `openclaw doctor --fix` in Debug Console
4. Check `/setup/api/debug` for detailed error info
5. Verify credentials directory exists with 700 permissions

### Token mismatch errors

1. Set `OPENCLAW_GATEWAY_TOKEN` in Railway Variables
2. Use `/setup` to reset and reconfigure
3. Or edit config via Config Editor to ensure `gateway.auth.token` matches

### Build fails on Railway

1. Check if OpenClaw main branch is broken
2. Set `OPENCLAW_VERSION=v2026.2.15` to pin to stable release
3. Check Railway build logs for specific errors
4. Verify all required files are in the repository

### Import backup fails

**"File too large: X.XMB (max 250MB)"**
- Reduce workspace files before exporting
- Split large data into multiple imports

**"Import requires both STATE_DIR and WORKSPACE_DIR under /data"**
- Set in Railway Variables:
  ```
  OPENCLAW_STATE_DIR=/data/.openclaw
  OPENCLAW_WORKSPACE_DIR=/data/workspace
  ```

**"Config file too large: X.XKB (max 500KB)"**
- Config exceeds safety limit
- Remove unnecessary data from config

## Local Development

### Quick smoke test

```bash
docker build -t openclaw-railway-template .

docker run --rm -p 8080:8080 \
  -e PORT=8080 \
  -e SETUP_PASSWORD=test \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -e OPENCLAW_VERSION=v2026.2.15 \
  -v $(pwd)/.tmpdata:/data \
  openclaw-railway-template

# Open http://localhost:8080/setup (password: test)
```

### Development with live reload

```bash
# Set environment variables
export SETUP_PASSWORD=test
export OPENCLAW_STATE_DIR=/tmp/openclaw-test/.openclaw
export OPENCLAW_WORKSPACE_DIR=/tmp/openclaw-test/workspace
export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

# Run the wrapper
npm run dev
# or
node src/server.js

# Visit http://localhost:8080/setup (password: test)
```

### Override OpenClaw version locally

```bash
docker build --build-arg OPENCLAW_VERSION=v2026.2.16 -t openclaw-test .
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Developer documentation and architecture notes
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines and development setup
- **[MIGRATION.md](MIGRATION.md)** - Migration guide from older versions
- **[OPENCLAW-VERSION-CONTROL.md](OPENCLAW-VERSION-CONTROL.md)** - Version control feature details
- **[DAY7-TEST-REPORT.md](DAY7-TEST-REPORT.md)** - Comprehensive test results
- **[QA-SANITY-CHECK-REPORT.md](QA-SANITY-CHECK-REPORT.md)** - Local validation results

## Support & Community

- **Report Issues**: https://github.com/codetitlan/moltbot-railway-template/issues
- **Discord**: https://discord.com/invite/clawd
- **OpenClaw Docs**: https://docs.openclaw.com

## License

[LICENSE](LICENSE)

## Credits

Based on [clawdbot-railway-template](https://github.com/vignesh07/clawdbot-railway-template) with significant enhancements.

### Major Contributors

- **Debug Console, Config Editor, Pairing Helper** - Enhanced onboarding workflow
- **Import/Export Backup** - Migration and disaster recovery
- **Custom Provider Support** - Ollama, vLLM, and more
- **Smart Railway Integration** (PR #12 by [@ArtificialSight](https://github.com/ArtificialSight)) - Proxy detection
- **OpenClaw Version Control** - Flexible version management
- **Enhanced Diagnostics** - Better error messages and troubleshooting
- **Automatic Migration** - Legacy env var support

### Features

- ✅ SSH-free command execution via Debug Console
- ✅ Browser-based configuration editing
- ✅ One-click device pairing approval
- ✅ Complete backup import/export system
- ✅ Support for custom AI providers
- ✅ Flexible OpenClaw version pinning
- ✅ Smart Railway environment detection
- ✅ Comprehensive health monitoring
- ✅ Automatic migration from legacy templates
- ✅ Security hardening (secret redaction, path validation)
