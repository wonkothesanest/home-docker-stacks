# Traefik Reverse Proxy

Traefik v3 reverse proxy running on orangepi5b.local as the edge/gateway node for the home lab infrastructure.

## Architecture

**Deployment Location:** orangepi5b.local (Raspberry Pi)

**Traffic Flow:**
```
Internet/LAN → orangepi5b.local:80/443 (Traefik) → Routes to:
  - Local containers on orangepi5b (via Docker provider + labels)
  - Remote services on wonko.local (via File provider + static config)
```

**Provider Strategy:**
- **Docker Provider**: Auto-discovers containers on orangepi5b.local
  - Example: Portainer, Zigbee2MQTT, Mosquitto
  - Uses labels for routing configuration
  - Accesses via /var/run/docker.sock

- **File Provider**: Manual configuration for wonko.local services
  - Example: Elasticsearch (wonko.local:9200), Kibana (wonko.local:5601)
  - Defined in config/dynamic.yml
  - Hot-reload on file changes
  - No modifications needed to wonko.local services

## Prerequisites

- Docker and docker-compose installed on orangepi5b.local
- Network connectivity from orangepi5b.local to wonko.local
- Services running on wonko.local with exposed ports

## Quick Start

### Option A: Deploy via Portainer (Recommended)

1. In Portainer UI on orangepi5b.local:
   - Navigate to **Stacks → Add Stack → Git Repository**
   - Repository URL: `https://github.com/youruser/home-docker-stacks`
   - Repository reference: `main` (or your branch)
   - Compose path: `infra/traefik/docker-compose.yml`

2. Set Environment Variables in Portainer UI:
   - `DOMAIN=homelab.local`
   - `WONKO_HOST=wonko.local`

3. Deploy stack

4. Create the external network (if not exists):
   ```bash
   docker network create traefik-network
   ```

### Option B: Deploy via SSH and docker compose

1. SSH to orangepi5b.local:
   ```bash
   ssh user@orangepi5b.local
   ```

2. Navigate to the traefik directory:
   ```bash
   cd /path/to/home-docker-stacks/infra/traefik
   ```

3. Create .env file from template:
   ```bash
   cp .env.example .env
   ```

4. Edit .env with actual values:
   ```bash
   nano .env
   ```

5. Create the external network:
   ```bash
   docker network create traefik-network
   ```

6. Start Traefik:
   ```bash
   docker compose up -d
   ```

## Verification

After deployment, verify Traefik is running:

```bash
# Check container status
docker compose ps

# Check logs
docker compose logs -f

# Verify network exists
docker network ls | grep traefik-network

# Access dashboard
curl -I http://orangepi5b.local:9080/dashboard/
```

Dashboard should be accessible at: http://orangepi5b.local:9080/dashboard/

## Accessing Services

### Configure DNS/Hosts

Add entries to `/etc/hosts` on client machines (or configure DNS server):

```
<orangepi5b-IP> traefik.homelab.local
<orangepi5b-IP> kibana.homelab.local
<orangepi5b-IP> es.homelab.local
<orangepi5b-IP> elasticsearch.homelab.local
```

### Test Access

```bash
# Test Kibana
curl http://kibana.homelab.local

# Test Elasticsearch
curl http://es.homelab.local
```

## Adding Services

See [docs/traefik-integration.md](../../docs/traefik-integration.md) for detailed instructions on:
- Adding wonko.local services (File Provider)
- Adding orangepi5b.local services (Docker Provider)
- Troubleshooting common issues

## Ports

- `80` - HTTP entry point
- `443` - HTTPS entry point (currently not configured with TLS)
- `9080` - Traefik dashboard (mapped from internal port 8080)

## Important Notes

- Services on wonko.local must keep their port mappings for Traefik to reach them
- The `traefik-network` must be created externally before starting Traefik
- Dashboard is in insecure mode (no auth) - suitable for development only
- For production, add authentication middleware to the dashboard router

## Troubleshooting

### Container won't start
- Check logs: `docker compose logs traefik`
- Verify network exists: `docker network ls | grep traefik-network`
- Ensure .env file exists with proper values

### Services return 404
- Check dynamic.yml syntax
- Verify file provider is loaded in dashboard: Providers → file
- Check router configuration in dashboard: HTTP → Routers

### Services return Bad Gateway
- Verify wonko.local services are accessible from orangepi5b
- Test: `curl http://wonko.local:5601` (from orangepi5b)
- Check service URLs in config/dynamic.yml

### Dashboard not accessible
- Verify port 9080 is not in use: `netstat -tulpn | grep 9080`
- Check Traefik container is running: `docker compose ps`
- Try: http://orangepi5b.local:9080/dashboard/ (note trailing slash)

## Security Considerations

- Docker socket is mounted read-only (`:ro`)
- Dashboard should use authentication middleware in production
- Consider using Docker Socket Proxy for additional security
- HTTPS/TLS configuration should be added for production use

## Next Steps

- Add more wonko.local services to config/dynamic.yml
- Add local orangepi5b services via Docker provider labels
- Configure Let's Encrypt certificates for HTTPS
- Add authentication middleware for dashboard
- Set up Tailscale integration for remote access
- Configure Cloudflare Tunnel for public endpoints
