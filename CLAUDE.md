# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains Docker Compose stacks for a multi-host home infrastructure. Stacks are organized by purpose (apps, data, infra, iot) and deployed across different hosts via Docker Compose or Portainer.

## Architecture

### Host Distribution

**orangepi5b.local (Raspberry Pi - Always-On Infrastructure)**
- Traefik (infra/traefik) - Reverse proxy and edge/gateway node for routing traffic
- Portainer Server (infra/portainer) - Container management UI
- Tailscale (infra/tailscale) - Subnet router for secure remote access to entire home LAN
- Zigbee2MQTT + Mosquitto (iot/zigbee-stack) - IoT device communication

**wonko.local (Local Workstation)**
- n8n + Postgres + Editly (apps/n8n-stack) - Workflow automation and video editing
- Prefect Server (apps/prefect-stack) - Workflow orchestration
- Elasticsearch + Kibana (data/search-stack) - Search and analytics
- Neo4j + NeoDash (data/neo4j) - Graph database and visualization
- Homepage (apps/homepage) - Dashboard with custom Docker build
- MCP Server (infra/mcp) - Model Context Protocol server with ES integration
- Tailscale (infra/tailscale) - Client node accepting routes from orangepi5b subnet router

### Stack Organization

```
apps/         - Application services (n8n, prefect, homepage)
data/         - Data infrastructure (elasticsearch, neo4j)
infra/        - Infrastructure services (traefik, portainer, tailscale, mcp)
iot/          - IoT services (zigbee, mosquitto)
```

Each stack directory contains:
- `docker-compose.yml` - Service definitions
- `.env` - Local environment variables (gitignored)
- `.env.example` - Template for environment variables (tracked in git)

## Common Commands

### Deploy a Stack

```bash
cd <stack-directory>
cp .env.example .env
# Edit .env with appropriate values
docker compose up -d
```

### Check Stack Status

```bash
cd <stack-directory>
docker compose ps
docker compose logs -f
```

### Stop/Remove a Stack

```bash
cd <stack-directory>
docker compose down
docker compose down -v  # Also remove volumes
```

### Build Custom Images

Homepage uses a custom Dockerfile that copies configs into the base image:

```bash
cd apps/homepage
docker compose build
docker compose up -d
```

### Restart a Service

```bash
cd <stack-directory>
docker compose restart <service-name>
```

## Important Patterns

### Environment Variables

Always copy `.env.example` to `.env` before deploying. The `.env` file contains sensitive values and is gitignored. The `.env.example` shows required variables with placeholder values.

### Volume Management

Some stacks use named volumes, others use bind mounts:
- Named volumes: Managed by Docker (e.g., `postgres_data`, `es_data`)
- Bind mounts: Direct filesystem paths (e.g., `./zigbee2mqtt-data`, `./prefect_data`)

The `data/search-stack` uses a named volume with a specific name (`prefect_data_getters_es_data`) to share data with the MCP server stack.

### Network Configuration

**Traefik Reverse Proxy:**
Traefik on orangepi5b.local acts as the edge/gateway node using a hybrid architecture:
- **Docker Provider**: Auto-discovers local containers on orangepi5b.local (Portainer, Zigbee)
- **File Provider**: Manual routing to wonko.local services (Elasticsearch, Kibana, n8n, etc.)
- Services on wonko.local keep their port mappings; no changes needed
- Local services on orangepi5b join `traefik-network` for routing
- See `docs/traefik-integration.md` for adding services to Traefik

**Multi-Network Services:**
The MCP server stack (infra/mcp) connects to multiple networks:
- `mcp-network` - Internal MCP communication
- `elasticsearch-network` - Shared with ES/Kibana for data access

**Tailscale Remote Access:**
Tailscale provides secure remote access using subnet routing:
- **orangepi5b.local**: Acts as subnet router, advertising home LAN (192.168.1.0/24)
- **wonko.local**: Client node accepting routes from orangepi5b
- **Architecture**: orangepi5b is always-on and routes traffic to entire home network
- **Deployment**: Use host-specific docker-compose files:
  - `docker-compose.orangepi5b.yml` on orangepi5b
  - `docker-compose.wonko.yml` on wonko
- **Configuration**: Each host requires unique auth key in `.env` file
- **Access**: All services accessible via LAN IPs through subnet router
- See `docs/tailscale-access.md` for remote access guide

### Custom Builds

Homepage (apps/homepage) requires building a custom image that includes configuration files baked into the image, rather than mounting them at runtime.

### Device Access

The Zigbee stack (iot/zigbee-stack) requires:
- Device mapping via `DONGLE` env var (e.g., `/dev/ttyACM0`)
- `dialout` group membership for serial port access

### Port Mappings

Key service ports:
- Traefik: 80 (HTTP), 443 (HTTPS), 9080 (dashboard)
- Portainer: 9443 (HTTPS), 8000 (tunnel)
- n8n: 5678
- Prefect: 4200 (UI), 8080 (API)
- Elasticsearch: 9200
- Kibana: 5601
- Neo4j: 7475 (HTTP), 7688 (Bolt)
- NeoDash: 5005
- Zigbee2MQTT: 8081
- Mosquitto: 1883 (MQTT), 9001 (WebSocket)
- Homepage: Configurable via PORT env var
- MCP Server: 8000

## Development Workflow

When modifying stacks:
1. Test changes locally with `docker compose up` (without `-d` for logs)
2. Update `.env.example` if new environment variables are added
3. Document any new volume mounts or network requirements
4. For multi-host deployments, verify host-specific configurations

When adding new stacks:
1. Create directory under appropriate category (apps/data/infra/iot)
2. Add `docker-compose.yml`
3. Add `.env.example` with all required variables
4. Update this CLAUDE.md with stack purpose and any special requirements
5. Update ReadMe.md host overview if applicable
