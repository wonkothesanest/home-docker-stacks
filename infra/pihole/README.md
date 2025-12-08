# Pi-hole Stack

Network-wide ad blocking and DNS management using Pi-hole on orangepi5b.local.

## Overview

Pi-hole acts as a DNS sinkhole, blocking ads and trackers at the DNS level for all devices on your network. This stack integrates with Traefik for web UI access.

## Features

- **DNS-based ad blocking**: Blocks ads and trackers before they reach your devices
- **Network-wide protection**: Works on all devices without client-side configuration
- **Custom blocklists**: Add your own domains to block or whitelist
- **Query logging**: Monitor DNS queries and blocked requests
- **Traefik integration**: Access web UI via `pihole.homelab.local`
- **Custom DNS configuration**: Resolves all `*.homelab.local` domains to Traefik

## Important: Deployment Method

**⚠️ Pi-hole must be deployed from the file system, NOT via Portainer's git deployment feature.**

The Pi-hole stack uses a custom entrypoint script (`pihole-startup.sh`) that needs to be mounted from the local filesystem. While the script is tracked in git for version control, Portainer's git deployment has limitations with mounting executable scripts.

**Recommended Deployment:**
1. Clone/pull the repository to your orangepi5b file system
2. Deploy using `docker compose up -d` directly, OR
3. Use Portainer's "Add Stack" → "Upload" feature to deploy from the local file system

## Prerequisites

- Docker and Docker Compose installed on orangepi5b
- Traefik running (for web UI routing)
- Port 53 available (no other DNS server running on host)

## Quick Start

1. **Copy environment template**:
   ```bash
   cd /path/to/infra/pihole
   cp .env.example .env
   ```

2. **Edit `.env` with your values**:
   ```bash
   nano .env
   ```
   - Set `DOMAIN` to match your Traefik domain (e.g., `homelab.local`)
   - Set `WEBPASSWORD` to a strong password
   - Set `SERVER_IP` to your orangepi5b IP address (e.g., `192.168.1.100`)

3. **Deploy the stack**:
   ```bash
   docker compose up -d
   ```

4. **Verify deployment**:
   ```bash
   docker compose ps
   docker compose logs -f
   ```

5. **Set the admin password** (if WEBPASSWORD in .env doesn't work):
   ```bash
   docker exec -it pihole pihole setpassword
   ```
   Enter your desired password when prompted. This sets the web interface login password.

## Access

- **Web Interface**:
  - Via Traefik: `http://pihole.homelab.local/admin`
  - Direct access: `http://<orangepi5b-ip>:8082/admin`
- **DNS Server**: Point your devices to the orangepi5b IP address (port 53)

## Configuration

### Setting Pi-hole as Your DNS Server

**Router-wide (Recommended)**:
1. Log into your router's admin interface
2. Find DHCP/DNS settings
3. Set primary DNS to your orangepi5b IP address
4. Save and reboot router
5. All devices will automatically use Pi-hole

**Per-device**:
- Set DNS server in network settings to orangepi5b IP
- Works for testing before router-wide deployment

### Upstream DNS Servers

Edit `.env` to change upstream DNS providers:
```bash
# Cloudflare (default)
UPSTREAM_DNS=1.1.1.1;1.0.0.1

# Google DNS
UPSTREAM_DNS=8.8.8.8;8.8.4.4

# Quad9 (privacy-focused)
UPSTREAM_DNS=9.9.9.9;149.112.112.112
```

### Custom Blocklists

1. Access web interface at `http://pihole.homelab.local/admin`
2. Navigate to **Group Management > Adlists**
3. Add blocklist URLs (many community lists available)
4. Update gravity: **Tools > Update Gravity**

## Management

### View Logs
```bash
docker compose logs -f pihole
```

### Restart Service
```bash
docker compose restart pihole
```

### Update Pi-hole
```bash
docker compose pull
docker compose up -d
```

### Update Gravity (Blocklists)
```bash
docker compose exec pihole pihole updateGravity
```

### Set/Reset Password
```bash
# Recommended method (prompts for password)
docker exec -it pihole pihole setpassword

# Alternative method (also prompts for password)
docker compose exec pihole pihole -a -p
```

**Note**: The `WEBPASSWORD` environment variable in `.env` may not always work reliably. If you cannot log in to the web interface, use the `setpassword` command above to manually set the password.

## Backup & Restore

### Backup Configuration
```bash
# Pi-hole stores config in ./pihole directory
tar -czf pihole-backup-$(date +%Y%m%d).tar.gz pihole/ dnsmasq.d/
```

### Restore Configuration
```bash
# Extract backup before starting container
tar -xzf pihole-backup-YYYYMMDD.tar.gz
docker compose up -d
```

## Troubleshooting

### Port 53 Already in Use
Check if systemd-resolved is using port 53:
```bash
sudo lsof -i :53
```

If systemd-resolved is running:
```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

### DNS Not Resolving
1. Check Pi-hole is running: `docker compose ps`
2. Check logs: `docker compose logs pihole`
3. Verify port 53 is exposed: `sudo netstat -tulpn | grep :53`
4. Test DNS query: `dig @<orangepi5b-ip> google.com`

### Web Interface Not Accessible
1. Check Traefik is running
2. Verify domain in `.env` matches Traefik `DOMAIN`
3. Direct access: `http://<orangepi5b-ip>:8082/admin`

### Verify homelab.local DNS Configuration
Check if the custom DNS entries were loaded:

```bash
# 1. Check if config file was created by startup script
docker exec pihole cat /etc/dnsmasq.d/02-homelab-local.conf
# Should show: address=/homelab.local/10.0.0.192

# 2. Check startup logs for custom script output
docker compose logs pihole | grep "Custom Startup"
# Should show messages about creating DNS config

# 3. Test DNS resolution inside container
docker exec pihole nslookup traefik.homelab.local localhost
# Should return 10.0.0.192

# 4. Test from host
dig @10.0.0.192 traefik.homelab.local
# Should return 10.0.0.192

# 5. Verify startup script is mounted and executable
docker exec pihole ls -la /custom-startup.sh
docker exec pihole test -x /custom-startup.sh && echo "Executable" || echo "Not executable"
```

If the config file doesn't exist, the custom entrypoint script may not have executed. Check that you deployed from the file system (not Portainer git) and that `pihole-startup.sh` is in the stack directory.

## Integration with Traefik

Pi-hole automatically registers with Traefik using Docker labels:
- URL: `http://pihole.homelab.local/admin`
- No manual Traefik configuration needed
- Ensure both containers can communicate

## Performance

- **Memory**: ~200-300 MB typical usage
- **CPU**: Minimal (DNS queries are lightweight)
- **Storage**: ~100 MB for container + blocklists

## Security Notes

- Change default password immediately after deployment
- Consider adding authentication middleware via Traefik for public access
- Regularly update blocklists and Pi-hole image
- Monitor query logs for suspicious DNS activity

## Additional Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole GitHub](https://github.com/pi-hole/pi-hole)
- [Community Blocklists](https://firebog.net/)
