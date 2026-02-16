# WUD - What's Up Docker

WUD (What's Up Docker) monitors Docker images for available updates and provides a web UI to view and manage container updates. It can also send notifications when new versions are available.

## Features

- **Web UI Dashboard**: Visual interface showing all containers and their update status
- **Automatic Monitoring**: Checks for image updates on a configurable schedule
- **Multiple Notifications**: Ntfy, Email, Discord, Slack, Telegram, Gotify, Pushover, Apprise
- **Triggers**: Webhook support for automation (e.g., trigger n8n workflows)
- **Per-Container Control**: Exclude specific containers or customize watch behavior
- **Registry Support**: Works with Docker Hub, GHCR, private registries, and more

## Quick Start

### 1. Copy and Configure Environment

```bash
cd infra/wud
cp .env.example .env
nano .env
```

**Minimum Configuration**:

```bash
# Web UI access (change default password!)
WUD_AUTH_USER=admin
WUD_AUTH_PASSWORD=your-secure-password

# Choose a notification method (Ntfy is easiest)
NTFY_ENDPOINT=https://ntfy.sh
NTFY_TOPIC=my-docker-updates-orangepi5b
```

### 2. Deploy

```bash
docker compose up -d
```

### 3. Access Web UI

- **Direct**: http://orangepi5b.local:3000
- **Via Traefik**: http://wud.home (if Traefik is configured)

Login with the credentials you set in `.env`.

### 4. Check Logs

```bash
docker compose logs -f wud
```

## Web UI Usage

The WUD dashboard shows:
- **All containers** with their current and available image versions
- **Update status** (up-to-date, update available, unknown)
- **Image details** (tags, layers, size, age)
- **Manual update triggers** (if configured with trigger plugins)

### Dashboard Features

- **Filter containers**: By name, status, or registry
- **Sort**: By name, status, or last update check
- **Details**: Click any container to see image details and available tags
- **Refresh**: Manually trigger an update check

## Configuration

### Web UI Authentication

**Recommended**: Always set a password for security.

```bash
WUD_AUTH_USER=admin
WUD_AUTH_PASSWORD=SecurePassword123!
```

To disable authentication (not recommended):
```bash
WUD_AUTH_USER=
WUD_AUTH_PASSWORD=
```

### Update Check Schedule

Control how often WUD checks for updates:

```bash
# Every 6 hours (default, recommended)
WATCH_SCHEDULE=0 */6 * * *

# Every 12 hours
WATCH_SCHEDULE=0 */12 * * *

# Daily at 2 AM
WATCH_SCHEDULE=0 2 * * *

# Every 15 minutes (for testing)
WATCH_SCHEDULE=*/15 * * * *
```

### Notification Methods

#### Ntfy (Recommended)

Simplest push notification setup:

```bash
NTFY_ENDPOINT=https://ntfy.sh
NTFY_TOPIC=my-docker-updates-orangepi5b
NTFY_PRIORITY=default
```

Then subscribe:
- Mobile: Install Ntfy app, subscribe to topic
- Web: Visit https://ntfy.sh/my-docker-updates-orangepi5b
- CLI: `ntfy subscribe my-docker-updates-orangepi5b`

#### Email (SMTP)

```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your-email@gmail.com
SMTP_TO=your-email@gmail.com
```

**Gmail**: Use an [App Password](https://support.google.com/accounts/answer/185833)

#### Discord

1. Create webhook in Discord server settings
2. Set in `.env`:
   ```bash
   DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
   ```

#### Slack

1. Create webhook in Slack workspace settings
2. Set in `.env`:
   ```bash
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR_WEBHOOK_URL
   ```

#### Telegram

1. Create bot with @BotFather
2. Get chat ID from @userinfobot
3. Set in `.env`:
   ```bash
   TELEGRAM_BOT_TOKEN=your-bot-token
   TELEGRAM_CHAT_ID=your-chat-id
   ```

#### Gotify (Self-Hosted)

```bash
GOTIFY_URL=https://gotify.example.com
GOTIFY_TOKEN=your-app-token
```

#### Apprise (80+ Services)

Apprise supports many services including:
- Matrix, Mattermost, Microsoft Teams
- IFTTT, Home Assistant, Nextcloud
- SMS providers, and many more

```bash
APPRISE_URL=service://token@host
```

See [Apprise documentation](https://github.com/caronc/apprise) for URL formats.

### Multiple Notification Methods

WUD can send to multiple notification services simultaneously. Just configure multiple notifiers in `.env`:

```bash
# Get both push notifications and email
NTFY_ENDPOINT=https://ntfy.sh
NTFY_TOPIC=docker-updates

SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
# ... etc
```

## Per-Container Configuration

### Exclude Containers from Monitoring

Add label to containers you don't want to monitor:

```yaml
labels:
  - "wud.watch=false"
```

### Watch Specific Tag Pattern

Only get notified for certain tags:

```yaml
labels:
  # Only watch semantic version tags (1.2.3)
  - "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"

  # Exclude beta/dev tags
  - "wud.tag.exclude=^.*-(beta|dev|rc).*$"
```

### Custom Display Name

```yaml
labels:
  - "wud.display.name=My Custom Container Name"
```

### Link to Documentation

```yaml
labels:
  - "wud.link.template=https://github.com/user/repo/releases"
```

## Traefik Integration

WUD is pre-configured for Traefik in the docker-compose.yml:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.wud.rule=Host(`wud.home`)
  - traefik.http.services.wud.loadbalancer.server.port=3000
```

Access via: http://wud.home (or your configured domain)

## Triggers and Automation

### Webhook Trigger

Trigger external automation when updates are detected:

```bash
WEBHOOK_URL=https://your-n8n-instance.com/webhook/docker-update
```

WUD will POST to this URL with update details:

```json
{
  "name": "container-name",
  "image": "user/image:tag",
  "updateAvailable": true,
  "currentVersion": "1.0.0",
  "newVersion": "1.1.0"
}
```

Use this to:
- Trigger n8n workflows
- Call Prefect flows
- Post to Slack/Discord with custom formatting
- Create GitHub issues automatically
- Any custom automation you need

## Registry Configuration

WUD works with multiple registries:

### Docker Hub (Default)
No configuration needed. WUD automatically queries Docker Hub for public images.

### GitHub Container Registry (GHCR)

For private GHCR images, add to `docker-compose.yml`:

```yaml
environment:
  - WUD_REGISTRY_GHCR_URL=https://ghcr.io
  - WUD_REGISTRY_GHCR_TOKEN=your-github-token
```

### Private Registry

```yaml
environment:
  - WUD_REGISTRY_CUSTOM_URL=https://registry.example.com
  - WUD_REGISTRY_CUSTOM_USERNAME=username
  - WUD_REGISTRY_CUSTOM_PASSWORD=password
```

## Troubleshooting

### Web UI Not Loading

1. Check container is running:
   ```bash
   docker compose ps
   ```

2. Check logs:
   ```bash
   docker compose logs -f wud
   ```

3. Verify port is accessible:
   ```bash
   curl http://localhost:3000
   ```

### No Notifications

1. Check logs for errors:
   ```bash
   docker compose logs wud | grep -i error
   ```

2. Verify notification settings in `.env`

3. Test notification by restarting container (triggers test notification):
   ```bash
   docker compose restart wud
   ```

### Authentication Issues

If you forget your password:

1. Edit `.env` and change password
2. Restart container:
   ```bash
   docker compose restart wud
   ```

### Container Not Detected

WUD discovers containers via Docker socket. Ensure:
1. Docker socket is mounted: `/var/run/docker.sock:/var/run/docker.sock:ro`
2. Container doesn't have `wud.watch=false` label
3. Check logs for discovery errors

### Rate Limiting (Docker Hub)

Docker Hub has rate limits for anonymous requests (100 pulls per 6 hours).

**Solution**: Add Docker Hub credentials in `docker-compose.yml`:

```yaml
environment:
  - WUD_REGISTRY_HUB_LOGIN=your-docker-username
  - WUD_REGISTRY_HUB_TOKEN=your-docker-password-or-token
```

This increases the limit to 200 pulls per 6 hours (free account) or unlimited (paid).

## Comparison with Diun

| Feature | WUD | Diun |
|---------|-----|------|
| Web UI | ✅ Yes | ❌ No |
| Notifications | ✅ Yes | ✅ Yes |
| Triggers/Webhooks | ✅ Yes | ❌ No |
| Resource Usage | ~50MB RAM | ~20MB RAM |
| Configuration | Environment vars | Environment vars |
| Best for | Visual monitoring, automation | Lightweight notifications only |

**Choose WUD**: You want a dashboard and/or need webhooks for automation

## API Access

WUD provides a REST API (requires authentication):

### Get All Containers

```bash
curl -u admin:password http://localhost:3000/api/containers
```

### Trigger Update Check

```bash
curl -u admin:password -X POST http://localhost:3000/api/containers/check
```

See [WUD API docs](https://fmartinou.github.io/whats-up-docker/#/api/) for more endpoints.

## Additional Resources

- [WUD Documentation](https://fmartinou.github.io/whats-up-docker/)
- [Configuration Reference](https://fmartinou.github.io/whats-up-docker/#/configuration/)
- [Notifiers](https://fmartinou.github.io/whats-up-docker/#/notifiers/)
- [Triggers](https://fmartinou.github.io/whats-up-docker/#/triggers/)
- [Registry Configuration](https://fmartinou.github.io/whats-up-docker/#/registries/)
- [GitHub Repository](https://github.com/fmartinou/whats-up-docker)

## Security Best Practices

1. **Always set a strong password** for the web UI
2. **Use HTTPS** when exposing WUD externally (via Traefik)
3. **Restrict access** using firewall rules or Traefik middleware
4. **Use read-only Docker socket** (`:ro` flag)
5. **Keep WUD updated** (check for updates regularly!)

## Updating WUD

To update WUD to the latest version:

```bash
cd infra/wud
docker compose pull
docker compose up -d
```

## Uninstalling

To remove WUD:

```bash
cd infra/wud
docker compose down -v  # -v also removes data volume
```
