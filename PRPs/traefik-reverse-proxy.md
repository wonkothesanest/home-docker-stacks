name: "Traefik Reverse Proxy Implementation for Multi-Host Home Lab"
description: |

## Goal
Implement a Traefik-based reverse proxy system running on orangepi5b.local (Raspberry Pi) that acts as the edge/gateway node for routing traffic to services across the home lab, including services running on wonko.local. Provides automatic service discovery for local containers, manual routing for remote services, HTTP to HTTPS redirection, and clean architecture for the multi-node Docker environment.

## Why
- **Unified Access**: Single entry point for all web services instead of remembering port numbers
- **Automatic Service Discovery**: Traefik detects new containers via labels, no manual config files
- **Security**: Centralized TLS/SSL management and HTTP→HTTPS redirection
- **Scalability**: Easy to add new services by adding labels to docker-compose files
- **Clean URLs**: Access services via hostnames (e.g., `n8n.wonko.local`) instead of `wonko.local:5678`
- **Integration Ready**: Foundation for Tailscale remote access and Cloudflare Tunnel public endpoints

## What
Implement Traefik v3 reverse proxy on orangepi5b.local with:
- Docker provider for automatic discovery of local containers (Portainer, Zigbee2MQTT)
- File provider for manual routing to wonko.local services (Elasticsearch, Kibana, n8n, etc.)
- `exposedByDefault = false` for explicit service exposure
- HTTP (port 80) and HTTPS (port 443) entry points
- Automatic HTTP → HTTPS redirection (optional)
- Dashboard for monitoring
- Cross-host routing to wonko.local services via static configuration
- Integration with existing stacks (Elasticsearch, Kibana as primary examples)

### Success Criteria
- [ ] Traefik container running on orangepi5b.local with Docker provider enabled
- [ ] Dashboard accessible at `traefik.orangepi5b.local:9080` or `http://orangepi5b.local:9080`
- [ ] Kibana accessible via Traefik at clean URL (e.g., `kibana.home` or via orangepi5b address)
- [ ] Elasticsearch accessible via Traefik at clean URL (e.g., `elasticsearch.home`)
- [ ] File provider configured for cross-host routing to wonko.local services
- [ ] Local services on orangepi5b (Portainer, Zigbee) optionally routed via Traefik labels
- [ ] No existing services are broken (all services still accessible via direct ports)
- [ ] Documentation for adding both local services (labels) and remote services (file config)

## All Needed Context

### Documentation & References
```yaml
- url: https://doc.traefik.io/traefik/providers/docker/
  why: Docker provider configuration, label syntax, exposedByDefault setting

- url: https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/
  why: Complete provider configuration reference, network settings, security considerations

- url: https://docs.docker.com/guides/traefik/
  why: Docker official guide for Traefik integration, routing examples

- url: https://stackoverflow.com/questions/58356714/how-to-redirect-http-to-https-with-traefik-2-0-and-docker-compose-labels
  why: Working examples of HTTP→HTTPS redirect via entrypoint and middleware approaches

- url: https://github.com/DoTheEvo/Traefik-v2-examples
  why: Real-world Traefik v2+ examples with various configurations

- url: https://doc.traefik.io/traefik/routing/routers/
  why: Router configuration documentation for label syntax

- url: https://doc.traefik.io/traefik/middlewares/http/overview/
  why: Middleware configuration for redirects, auth, headers, etc.

- url: https://doc.traefik.io/traefik/providers/file/
  why: File provider configuration for defining services manually (for wonko.local services)

- url: https://doc.traefik.io/traefik/routing/services/
  why: Service configuration syntax for manually defining backend servers

- file: apps/n8n-stack/docker-compose.yml
  why: Example of wonko.local service that will be routed via file provider

- file: data/search-stack/docker-compose.yml
  why: Example of custom network configuration pattern to mirror

- file: infra/mcp/docker-compose.yml
  why: Example of multi-network service (connects to mcp-network and elasticsearch-network)

- file: infra/portainer/docker-compose.yml
  why: Simple service configuration, currently exposes ports 9443 and 8000
```

### Current Codebase Structure
```bash
/media/dusty/TB2/workspace/dusty/home-docker-stacks/
├── apps/
│   ├── homepage/              # Dashboard with custom Dockerfile
│   ├── n8n-stack/             # n8n + Postgres + Editly (ports: 5678, 3000)
│   ├── prefect-stack/         # Prefect server (ports: 4200, 8080)
│   └── librechat/             # (not yet configured)
├── data/
│   ├── neo4j/                 # Neo4j + NeoDash (ports: 7475, 7688, 5005)
│   └── search-stack/          # Elasticsearch + Kibana (ports: 9200, 5601)
│       └── Uses custom network: elasticsearch-network
├── infra/
│   ├── mcp/                   # MCP server with multi-network (port: 8000)
│   │   └── Networks: mcp-network, elasticsearch-network
│   └── portainer/             # Portainer CE (ports: 9443, 8000)
├── iot/
│   └── zigbee-stack/          # Zigbee2MQTT + Mosquitto (ports: 8081, 1883, 9001)
└── PRPs/
    ├── inputs/
    └── templates/

HOST DISTRIBUTION:
- wonko.local: n8n, prefect, elasticsearch, kibana, neo4j, homepage, mcp (application/data services)
- orangepi5b.local: portainer, zigbee2mqtt, mosquitto, **traefik (NEW)** (infrastructure/edge node)
```

### Desired Codebase Structure with Traefik
```bash
/media/dusty/TB2/workspace/dusty/home-docker-stacks/
├── infra/
│   ├── traefik/                           # NEW - Traefik on orangepi5b.local
│   │   ├── docker-compose.yml             # Traefik service definition
│   │   ├── .env.example                   # Template for domain configuration
│   │   ├── config/                        # NEW - File provider directory
│   │   │   └── dynamic.yml                # Manual service definitions for wonko.local
│   │   └── README.md                      # Deployment notes for orangepi5b
│   ├── mcp/                               # Runs on wonko.local
│   └── portainer/                         # Runs on orangepi5b.local (can add Traefik labels)
├── apps/                                  # All run on wonko.local
│   ├── n8n-stack/
│   │   └── docker-compose.yml             # NO CHANGES (routed via file provider)
│   └── ...
├── data/                                  # All run on wonko.local
│   ├── search-stack/
│   │   └── docker-compose.yml             # NO CHANGES (routed via file provider)
│   └── ...
└── docs/
    └── traefik-integration.md             # NEW - Guide for adding services to Traefik

RESPONSIBILITIES:
- infra/traefik/docker-compose.yml: Core Traefik with Docker + File providers
- infra/traefik/.env.example: Domain names, wonko.local IP address
- infra/traefik/config/dynamic.yml: Manual routes to wonko.local services (Kibana, ES, n8n, etc.)
- docs/traefik-integration.md: Guide for adding local (labels) and remote (file) services

DEPLOYMENT:
- infra/traefik/ deployed on orangepi5b.local via Portainer or docker compose
- No changes needed to services on wonko.local (they keep port mappings)
- File provider watches config/dynamic.yml for changes (hot-reload)
```

### Known Gotchas & Important Considerations

```yaml
# CRITICAL: Multi-Host Architecture Understanding
# Traefik's Docker provider connects to ONE Docker daemon only (local socket).
# This setup uses a HYBRID approach:
#   - Docker provider: Auto-discovers local containers on orangepi5b.local (Portainer, Zigbee)
#   - File provider: Manual routes to wonko.local services (Kibana, ES, n8n, etc.)
#
# ARCHITECTURE DECISION:
# - Traefik runs on orangepi5b.local as the edge/gateway node
# - All external traffic enters through orangepi5b.local (ports 80, 443)
# - Traefik forwards requests to wonko.local via internal network (e.g., http://wonko.local:9200)
# - Services on wonko.local MUST keep their port mappings for Traefik to reach them

# CRITICAL: Docker Socket Security
# Mounting /var/run/docker.sock gives full Docker API access.
# This is a security risk in multi-user environments.
# For production, consider using:
#   - Docker Socket Proxy (tecnativa/docker-socket-proxy)
#   - SSH-based connection
#   - Docker API over TLS
# For home lab: Direct socket mount is acceptable

# CRITICAL: Network Configuration for This Architecture
# LOCAL services on orangepi5b (Portainer, Zigbee):
#   - Add to traefik-network for Docker provider discovery
#   - Use labels for routing (auto-discovery)
#
# REMOTE services on wonko.local (Kibana, ES, n8n):
#   - NO network changes needed (different physical host)
#   - Traefik reaches them via internal IP/hostname (http://wonko.local:PORT)
#   - Defined manually in config/dynamic.yml (File provider)
#   - Services MUST expose ports (already the case)

# CRITICAL: Port Specification
# If container exposes multiple ports, Traefik picks the lowest.
# ALWAYS specify port explicitly for clarity:
#   - "traefik.http.services.<name>.loadbalancer.server.port=8000"

# CRITICAL: File Provider Configuration
# File provider watches a directory for YAML/TOML config files
# Mount the config directory: ./config:/etc/traefik/config
# Enable with: --providers.file.directory=/etc/traefik/config
# Hot-reload: Changes to dynamic.yml are detected automatically
#
# GOTCHA: Dashboard Access
# Dashboard router MUST be explicitly enabled when exposedByDefault=false
# Add labels to Traefik container itself OR define in file provider:
#   - "traefik.http.routers.dashboard.rule=Host(`traefik.orangepi5b.local`)"
#   - "traefik.http.routers.dashboard.service=api@internal"

# GOTCHA: HTTPS/TLS Certificate Setup
# For local development without real certificates:
#   1. Use HTTP only (simplest)
#   2. Use Traefik's default self-signed certificate
#   3. Generate local CA and import to browsers
#   4. Use Let's Encrypt DNS challenge (requires public DNS)
#
# For production with Cloudflare:
#   - Use Cloudflare Origin Certificates
#   - OR use Let's Encrypt with DNS challenge (cloudflare provider)

# Pattern from existing codebase:
# - Named volumes for persistence (see portainer_data, es_data)
# - .env files for configuration (see all stacks)
# - Custom networks when services need isolation (see elasticsearch-network)
# - Environment variables use ${VAR} syntax
# - restart: unless-stopped is standard
# - version: '3.8' is used consistently (though deprecated, still works)
```

## Implementation Blueprint

### Multi-Host Architecture

**Architecture: Single Traefik on orangepi5b.local (Edge/Gateway Node)**

This setup uses orangepi5b.local as the edge node where all external traffic enters the home lab:

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

**Benefits:**
- Clean separation: orangepi5b handles routing, wonko.local handles workloads
- No resource overhead on main workstation (wonko.local)
- Aligns with Docker Compose (no Swarm required)
- Easy to extend with Tailscale or Cloudflare Tunnel integration
- Services on wonko.local remain unchanged (keep port mappings)

### Data Models and Structure

```yaml
# Traefik Configuration Structure

STATIC CONFIG (set at startup via command arguments):
  entrypoints:
    web:
      address: ":80"
      # Optional: http.redirections.entryPoint for global HTTP→HTTPS redirect
    websecure:
      address: ":443"

  providers:
    docker:
      endpoint: "unix:///var/run/docker.sock"
      exposedByDefault: false      # Only expose containers with traefik.enable=true
      network: "traefik-network"   # Default network for local container communication

    file:
      directory: "/etc/traefik/config"  # Watch this directory for dynamic config
      watch: true                       # Hot-reload on file changes

  api:
    dashboard: true                # Enable dashboard
    insecure: true                 # Allow dashboard without auth (dev only)

DYNAMIC CONFIG - Docker Provider (labels on local containers):
  traefik.enable: "true"           # Required when exposedByDefault=false
  traefik.http.routers.<name>.rule: "Host(`service.home`)"
  traefik.http.routers.<name>.entrypoints: "web"
  traefik.http.services.<name>.loadbalancer.server.port: "8080"
  traefik.docker.network: "traefik-network"  # If service on multiple networks

DYNAMIC CONFIG - File Provider (config/dynamic.yml for wonko.local services):
http:
  routers:
    kibana:
      rule: "Host(`kibana.home`)"
      entryPoints: ["web"]
      service: "kibana"

    elasticsearch:
      rule: "Host(`elasticsearch.home`) || Host(`es.home`)"
      entryPoints: ["web"]
      service: "elasticsearch"

  services:
    kibana:
      loadBalancer:
        servers:
          - url: "http://wonko.local:5601"  # Direct to wonko.local service

    elasticsearch:
      loadBalancer:
        servers:
          - url: "http://wonko.local:9200"  # Direct to wonko.local service
```

### Task List

```yaml
Task 1: Create Traefik Infrastructure on orangepi5b.local
  CREATE infra/traefik/docker-compose.yml:
    - Define traefik service with traefik:v3.6 image (ARM-compatible)
    - Configure command arguments for:
        * Entrypoints (web:80, websecure:443)
        * Docker provider (exposedByDefault=false)
        * File provider (directory=/etc/traefik/config, watch=true)
        * API dashboard (insecure=true for dev)
    - Expose ports 80, 443, 9080 (dashboard - avoiding conflict with port 8080)
    - Mount Docker socket: /var/run/docker.sock:/var/run/docker.sock:ro
    - Mount config directory: ./config:/etc/traefik/config:ro
    - Create traefik-network (for local containers like Portainer)
    - Add labels for Traefik dashboard access
    - Set restart: unless-stopped

  CREATE infra/traefik/.env.example:
    - DOMAIN=home  # Base domain for services
    - WONKO_HOST=wonko.local  # Hostname/IP of wonko.local for routing
    - Add comments explaining each variable

  PATTERN: Mirror structure from infra/portainer/
  CRITICAL: Must enable BOTH Docker and File providers

Task 2: Create Dynamic Configuration for wonko.local Services
  CREATE infra/traefik/config/dynamic.yml:
    - Define HTTP routers for:
        * kibana: Host(`kibana.home`) → wonko.local:5601
        * elasticsearch: Host(`es.home`) → wonko.local:9200
    - Define HTTP services with loadBalancer servers pointing to wonko.local
    - Use YAML format (not TOML)
    - Include comments explaining each section

  CRITICAL: Services must use format: http://wonko.local:PORT
  NOTE: Traefik will hot-reload this file when changed (watch=true)

Task 3: Create Traefik Network on orangepi5b.local
  RUN on orangepi5b.local:
    - docker network create traefik-network

  PURPOSE: Network for local containers (Portainer, Zigbee) to join Traefik
  NOTE: wonko.local services don't need this network (different host)
  NOTE: Must be created before starting Traefik

Task 4: Deploy Traefik on orangepi5b.local
  DEPLOY OPTIONS:
    Option A - Via Portainer (RECOMMENDED if Portainer already running):
      - In Portainer UI, add new stack from Git repository
      - Point to: infra/traefik/docker-compose.yml
      - Set environment variables in Portainer UI
      - Deploy stack

    Option B - Via SSH and docker compose:
      - SSH to orangepi5b.local
      - cd /path/to/home-docker-stacks/infra/traefik
      - cp .env.example .env
      - Edit .env with actual values
      - docker network create traefik-network (if not exists)
      - docker compose up -d

  VERIFY after deployment:
    - docker compose ps (container should be "Up")
    - docker compose logs -f (check for errors)
    - Dashboard accessible: http://orangepi5b.local:9080/dashboard/

Task 5: Test File Provider Routing to Kibana (wonko.local)
  VERIFY wonko.local service is accessible:
    - FROM orangepi5b.local: curl http://wonko.local:5601 (should return Kibana HTML)
    - If fails: Check network connectivity between hosts

  TEST Traefik routing:
    - Add DNS/hosts entry: kibana.home → orangepi5b.local IP
    - FROM any device: curl http://kibana.home
    - Should return Kibana HTML (routed through Traefik)

  CHECK Traefik dashboard:
    - Visit: http://orangepi5b.local:9080/dashboard/
    - Navigate to HTTP > Routers (should see "kibana" router)
    - Navigate to HTTP > Services (should see "kibana" service)

  TROUBLESHOOTING:
    - If 404: Check dynamic.yml syntax and file mount
    - If "Bad Gateway": Verify wonko.local:5601 is accessible from orangepi5b
    - If "Service Unavailable": Check service definition in dynamic.yml
    - Check Traefik logs: docker compose logs traefik

Task 6: Test File Provider Routing to Elasticsearch (wonko.local)
  ADD DNS/hosts entry: es.home → orangepi5b.local IP

  TEST Elasticsearch routing:
    - FROM any device: curl http://es.home
    - Should return Elasticsearch JSON response (routed through Traefik)
    - Verify in Traefik dashboard (should see "elasticsearch" router/service)

  VERIFY both services work:
    - curl http://kibana.home/api/status
    - curl http://es.home/_cluster/health

  SUCCESS CRITERIA:
    - Both Kibana and Elasticsearch accessible via Traefik
    - Original ports still work (wonko.local:5601, wonko.local:9200)
    - Traefik dashboard shows both routers and services

Task 7: Optional - Add Local Service via Docker Provider (Portainer)
  NOTE: This task is optional - demonstrates Docker provider for local services

  MODIFY infra/portainer/docker-compose.yml (on orangepi5b.local):
    - ADD to portainer service:
        networks:
          - default
          - traefik-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.portainer.rule=Host(`portainer.home`)"
          - "traefik.http.routers.portainer.entrypoints=web"
          - "traefik.http.services.portainer.loadbalancer.server.port=9443"
          - "traefik.http.services.portainer.loadbalancer.server.scheme=https"

    - ADD to networks section:
        networks:
          default:
          traefik-network:
            external: true

  VERIFY:
    - curl -Ik https://portainer.home (routed through Traefik)
    - Traefik dashboard shows portainer router (auto-discovered via labels)

Task 8: Create Integration Documentation
  CREATE docs/traefik-integration.md:
    - Title: "Adding Services to Traefik Reverse Proxy (orangepi5b.local)"
    - Section 1: Architecture Overview
        * Traefik on orangepi5b.local as edge node
        * Docker provider for local services
        * File provider for remote wonko.local services
    - Section 2: Adding wonko.local Services (File Provider)
        * Edit infra/traefik/config/dynamic.yml
        * Define router with Host() rule
        * Define service with wonko.local:PORT URL
        * Example: Adding n8n, Prefect, Neo4j
    - Section 3: Adding orangepi5b Services (Docker Provider)
        * Add container to traefik-network
        * Add labels for routing
        * Example: Zigbee2MQTT, Mosquitto
    - Section 4: Common Troubleshooting
        * 404 errors, Bad Gateway, connectivity issues
        * How to check Traefik logs and dashboard

  PATTERN: Use existing CLAUDE.md format and style
  INCLUDE: Real examples from Kibana, Elasticsearch, optionally Portainer

Task 9: Optional - Enable HTTPS Redirect
  NOTE: This task is optional and can be done after basic HTTP setup works

  MODIFY infra/traefik/docker-compose.yml:
    - ADD to command section:
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"

  VERIFY:
    - curl -I http://kibana.home (should return 301/308 to https://)
    - Browser access redirects to HTTPS (will show certificate warning with self-signed cert)

  NEXT STEPS for production:
    - Configure Let's Encrypt certificate resolver with DNS challenge
    - OR use Cloudflare Origin Certificates
    - Update dynamic.yml routers to include TLS configuration

Task 10: Update Repository Documentation
  MODIFY CLAUDE.md:
    - ADD Traefik to "Host Distribution" section under orangepi5b.local
    - ADD traefik/ to "Stack Organization" under infra/
    - ADD Traefik ports (80, 443, 9080) to "Port Mappings" section
    - ADD note about hybrid architecture (Docker + File providers)
    - ADD note that wonko.local services are routed via File provider (no changes needed)

  CREATE infra/traefik/README.md:
    - Deployment location: orangepi5b.local
    - Prerequisites: Docker, docker-compose, network connectivity to wonko.local
    - Quick start instructions
    - Link to docs/traefik-integration.md

Task 11: Final Validation and Cleanup
  VERIFY ALL on orangepi5b.local:
    - Traefik container running: docker compose ps
    - Dashboard accessible: http://orangepi5b.local:9080/dashboard/
    - Kibana accessible via Traefik: curl http://kibana.home
    - Elasticsearch accessible via Traefik: curl http://es.home
    - Original ports still work on wonko.local (5601, 9200)
    - Traefik dashboard shows both routers and services (kibana, elasticsearch)
    - File provider config is loaded (check dashboard: Providers > file)

  TEST from external device (not orangepi5b or wonko):
    - Add DNS entries or /etc/hosts:
        <orangepi5b-IP> kibana.home
        <orangepi5b-IP> es.home
    - curl http://kibana.home
    - curl http://es.home
    - Both should work (traffic routed through orangepi5b to wonko.local)

  CLEANUP:
    - Verify .env is in .gitignore
    - Commit changes to git:
        * infra/traefik/docker-compose.yml
        * infra/traefik/.env.example
        * infra/traefik/config/dynamic.yml
        * docs/traefik-integration.md
        * CLAUDE.md

  OPTIONAL NEXT STEPS:
    - Add more wonko.local services to dynamic.yml (n8n, Prefect, Neo4j)
    - Add local orangepi5b services via Docker provider labels
    - Set up Tailscale integration for remote access
    - Configure Cloudflare Tunnel for public endpoints
    - Implement Let's Encrypt certificates with DNS challenge
```

### Pseudocode for Key Components

```yaml
# Task 1: Traefik docker-compose.yml structure (on orangepi5b.local)

services:
  traefik:
    image: traefik:v3.6  # ARM64-compatible
    container_name: traefik
    restart: unless-stopped

    command:
      # Entry Points
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"

      # Docker Provider (for local orangepi5b containers)
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik-network"

      # File Provider (for wonko.local services)
      - "--providers.file.directory=/etc/traefik/config"
      - "--providers.file.watch=true"

      # API/Dashboard
      - "--api.dashboard=true"
      - "--api.insecure=true"  # Only for dev; use auth middleware for production

      # Logging (optional)
      - "--log.level=INFO"
      - "--accesslog=true"

    ports:
      - "80:80"       # HTTP entry point
      - "443:443"     # HTTPS entry point
      - "9080:8080"   # Dashboard (9080 on host, 8080 internal - avoids port conflict)

    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"  # Docker API access for local containers
      - "./config:/etc/traefik/config:ro"                # File provider config directory

    networks:
      - traefik-network

    labels:
      # Enable Traefik for its own dashboard
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.${DOMAIN}`)"
      - "traefik.http.routers.dashboard.entrypoints=web"
      - "traefik.http.routers.dashboard.service=api@internal"

networks:
  traefik-network:
    external: true
```

```yaml
# Task 2: File Provider dynamic.yml (for wonko.local services)

# infra/traefik/config/dynamic.yml

http:
  # Routers define how to match requests
  routers:
    kibana:
      rule: "Host(`kibana.home`)"
      entryPoints:
        - "web"
      service: "kibana"

    elasticsearch:
      rule: "Host(`es.home`) || Host(`elasticsearch.home`)"
      entryPoints:
        - "web"
      service: "elasticsearch"

    # Add more services as needed
    # n8n:
    #   rule: "Host(`n8n.home`)"
    #   entryPoints:
    #     - "web"
    #   service: "n8n"

  # Services define backend servers
  services:
    kibana:
      loadBalancer:
        servers:
          - url: "http://wonko.local:5601"  # Point to wonko.local service

    elasticsearch:
      loadBalancer:
        servers:
          - url: "http://wonko.local:9200"  # Point to wonko.local service

    # n8n:
    #   loadBalancer:
    #     servers:
    #       - url: "http://wonko.local:5678"
```

```yaml
# Task 7: Docker Provider pattern (for local orangepi5b services)

# Example: Adding Portainer (already running on orangepi5b) to Traefik

# infra/portainer/docker-compose.yml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9443:9443"
      - "8000:8000"
    volumes:
      - portainer_data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - default           # Keep existing network
      - traefik-network   # Add for Traefik routing

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`portainer.home`)"
      - "traefik.http.routers.portainer.entrypoints=web"
      - "traefik.http.services.portainer.loadbalancer.server.port=9443"
      - "traefik.http.services.portainer.loadbalancer.server.scheme=https"

networks:
  default:
  traefik-network:
    external: true

volumes:
  portainer_data:

# FOR MULTI-NETWORK SERVICES (like app + database):
services:
  webapp:
    image: webapp:latest
    networks:
      - default           # For database communication
      - traefik-network   # For Traefik routing
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`webapp.wonko.local`)"
      - "traefik.http.routers.webapp.entrypoints=web"
      - "traefik.http.services.webapp.loadbalancer.server.port=3000"
      - "traefik.docker.network=traefik-network"  # CRITICAL: Tell Traefik which network to use

  database:
    image: postgres:15
    networks:
      - default  # Only internal network, not exposed via Traefik

networks:
  default:
    name: webapp-network
  traefik-network:
    external: true

# FOR SERVICES WITH WEBSOCKETS:
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.ws-app.rule=Host(`ws.wonko.local`)"
  - "traefik.http.routers.ws-app.entrypoints=web"
  - "traefik.http.services.ws-app.loadbalancer.server.port=8080"
  # No special websocket config needed in Traefik v2+; it handles upgrades automatically

# FOR SERVICES WITH PATH-BASED ROUTING:
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`wonko.local`) && PathPrefix(`/api`)"
  - "traefik.http.routers.api.entrypoints=web"
  - "traefik.http.services.api.loadbalancer.server.port=8000"
  # Optional: Strip prefix if app doesn't expect /api in path
  - "traefik.http.middlewares.api-stripprefix.stripprefix.prefixes=/api"
  - "traefik.http.routers.api.middlewares=api-stripprefix"
```

### Integration Points

```yaml
DEPLOYMENT LOCATION:
  - Traefik deployed on: orangepi5b.local
  - Accessible services on: wonko.local
  - Network connectivity: orangepi5b.local must be able to reach wonko.local services

NETWORK INTEGRATION:
  CREATE on orangepi5b.local:
    - traefik-network (external Docker network for local services)
    - Command: docker network create traefik-network

  FOR wonko.local SERVICES:
    - NO network changes required (different physical host)
    - Services MUST expose ports (already done)
    - Traefik routes to: http://wonko.local:PORT

  FOR orangepi5b.local SERVICES (optional):
    - Add to traefik-network
    - Add Traefik labels for routing

EXISTING STACKS TO ROUTE VIA FILE PROVIDER (wonko.local):
  Initial Implementation:
    - data/search-stack/ (Elasticsearch port 9200, Kibana port 5601)
      * Add to dynamic.yml: es.home → wonko.local:9200
      * Add to dynamic.yml: kibana.home → wonko.local:5601

  Future Additions (add to dynamic.yml as needed):
    - apps/n8n-stack/ (n8n port 5678)
    - apps/prefect-stack/ (Prefect UI port 4200)
    - data/neo4j/ (Neo4j HTTP port 7475, NeoDash port 5005)
    - apps/homepage/ (port via env var)
    - infra/mcp/ (MCP server port 8000)

LOCAL orangepi5b.local SERVICES (optional Docker provider integration):
  - infra/portainer/ (HTTPS port 9443) - Add labels to route via Traefik
  - iot/zigbee-stack/ (Zigbee2MQTT port 8081) - Add labels to route via Traefik

ENVIRONMENT VARIABLES:
  CREATE infra/traefik/.env on orangepi5b.local:
    - DOMAIN=home
    - WONKO_HOST=wonko.local  # or wonko.local IP address

  NO CHANGES to existing service .env files on wonko.local

DNS/HOSTS FILE CONFIGURATION:
  ADD to /etc/hosts on client machines (or configure DNS server):
    <orangepi5b-IP> traefik.home
    <orangepi5b-IP> kibana.home
    <orangepi5b-IP> es.home
    <orangepi5b-IP> elasticsearch.home

  ALTERNATIVE: Use wildcard DNS like nip.io:
    - kibana.192.168.1.50.nip.io (assuming 192.168.1.50 is orangepi5b IP)
    - es.192.168.1.50.nip.io

PORTAINER DEPLOYMENT:
  - Traefik stack managed via Portainer on orangepi5b.local
  - Add stack from Git repo OR manual compose file
  - Set environment variables in Portainer UI:
      * DOMAIN=home
      * WONKO_HOST=wonko.local
  - Deploy stack to orangepi5b.local
  - Portainer will pull updates from Git when configured

FILE PROVIDER HOT-RELOAD:
  - Edit infra/traefik/config/dynamic.yml to add/modify services
  - Traefik automatically reloads (watch=true)
  - No container restart needed for routing changes
  - Check Traefik logs to confirm: "Configuration loaded"
```

## Validation Loop

### Level 1: Syntax & Structure
```bash
# ON orangepi5b.local - Validate Traefik docker-compose
cd /path/to/home-docker-stacks/infra/traefik
docker compose config  # Should parse without errors, output resolved config

# Validate dynamic.yml syntax
cat config/dynamic.yml  # Check YAML is valid, routers and services defined

# Expected: No errors, valid YAML structure
```

### Level 2: Container and File Provider Tests
```bash
# ON orangepi5b.local - Deploy Traefik
cd /path/to/home-docker-stacks/infra/traefik
cp .env.example .env
# Edit .env with actual values

# Create network if not exists
docker network create traefik-network

# Start Traefik
docker compose up -d

# Verify Traefik is running
docker compose ps  # Should show traefik container "Up"
docker compose logs  # Should show "Configuration loaded" for both docker and file providers

# Verify network exists
docker network ls | grep traefik-network  # Should show the network

# Verify dashboard (from orangepi5b or any machine on network)
curl -I http://orangepi5b.local:9080/dashboard/  # Should return 200 OK (note trailing slash)

# Verify File provider loaded dynamic.yml
docker compose logs traefik | grep "Configuration loaded"
# Should see: "Configuration loaded from file: /etc/traefik/config/dynamic.yml"

# Expected: Traefik running, both providers active, no errors
```

### Level 3: Cross-Host Routing Tests
```bash
# FROM orangepi5b.local - Test connectivity to wonko.local
curl -I http://wonko.local:5601  # Test Kibana direct access
curl -I http://wonko.local:9200  # Test Elasticsearch direct access
# Expected: Both return 200 OK (if services running on wonko.local)

# FROM any machine with DNS/hosts configured - Test Traefik routing
# (Add to /etc/hosts: <orangepi5b-IP> kibana.home es.home)

curl -I http://kibana.home
# Expected: 200 OK, routed through Traefik to wonko.local:5601

curl -I http://es.home
# Expected: 200 OK, routed through Traefik to wonko.local:9200

# Verify Traefik dashboard shows File provider services
curl http://orangepi5b.local:9080/api/http/routers | jq '.[] | select(.name=="kibana")'
# Expected: Shows kibana router configuration

curl http://orangepi5b.local:9080/api/http/services | jq '.[] | select(.name=="kibana")'
# Expected: Shows kibana service with wonko.local:5601 as server

# Check File provider in dashboard
curl http://orangepi5b.local:9080/api/overview | jq '.providers'
# Expected: Shows both "docker" and "file" providers
```

### Level 4: Integration Tests
```bash
# Test service functionality (not just Traefik routing)

# Kibana health check
curl http://kibana.home/api/status | jq '.status.overall.state'
# Expected: "green"

# Elasticsearch cluster health
curl http://es.home/_cluster/health | jq '.status'
# Expected: "yellow" or "green"

# Test that original ports still work (backward compatibility)
curl -I http://wonko.local:5601  # Kibana direct access
curl -I http://wonko.local:9200  # Elasticsearch direct access
# Expected: Both return 200 OK

# Test FROM different machine on network (not orangepi5b or wonko)
# Add to /etc/hosts: <orangepi5b-IP> kibana.home
# Browser: http://kibana.home
# Expected: Kibana UI loads (routed orangepi5b → wonko.local)
```

### Level 5: Optional HTTPS Test (Task 9)
```bash
# Only after enabling HTTPS redirect (Task 9)

# Test redirect
curl -I http://kibana.home
# Expected: 301 or 308 redirect to https://kibana.home

# Test HTTPS (will fail cert validation without proper certs)
curl -Ik https://kibana.home
# Expected: 200 OK (with -k to skip cert validation)

# Without -k flag, should see certificate error (expected with self-signed cert)
```

## Final Validation Checklist
- [ ] Traefik container running on orangepi5b.local: `docker compose ps`
- [ ] Dashboard accessible: http://orangepi5b.local:9080/dashboard/
- [ ] Network created on orangepi5b: `docker network ls | grep traefik-network`
- [ ] Kibana accessible via Traefik: `curl http://kibana.home`
- [ ] Elasticsearch accessible via Traefik: `curl http://es.home`
- [ ] Both services visible in Traefik dashboard (HTTP > Routers, HTTP > Services)
- [ ] File provider loaded: Dashboard shows "file" provider under Providers
- [ ] Original wonko.local ports still work: `curl http://wonko.local:5601`
- [ ] Cross-host routing works from external machine (not orangepi5b or wonko)
- [ ] Documentation created: docs/traefik-integration.md
- [ ] CLAUDE.md updated with orangepi5b.local Traefik deployment
- [ ] .env.example created and tracked in git
- [ ] .env file created locally but NOT tracked in git (.gitignore)
- [ ] config/dynamic.yml tracked in git (contains no secrets)
- [ ] No sensitive data (passwords, IPs, tokens) in git-tracked files

## Git Security Checklist
```bash
# MUST be in .gitignore (contains sensitive data):
infra/traefik/.env              # Actual environment values
infra/traefik/acme.json         # Let's Encrypt certificates (if using ACME)
infra/traefik/traefik-data/     # Certificates and runtime data

# SHOULD be tracked in git (no sensitive data):
infra/traefik/.env.example      # Template with placeholder values
infra/traefik/docker-compose.yml
infra/traefik/config/dynamic.yml  # Only contains: hostnames, wonko.local references
infra/traefik/README.md
docs/traefik-integration.md

# Verify before committing:
git diff --cached  # Review staged changes
grep -r "password" infra/traefik/  # Check for passwords
grep -r "192.168" infra/traefik/   # Check for hardcoded IPs (should only be in .env)
```

## Anti-Patterns to Avoid
- ❌ Don't use `exposedByDefault=true` - be explicit with `traefik.enable=true`
- ❌ Don't mount Docker socket as read-write - use `:ro` flag
- ❌ Don't remove wonko.local port mappings - they're needed for Traefik to reach services
- ❌ Don't use `--api.insecure=true` in production - add auth middleware
- ❌ Don't put actual values in .env.example - use placeholders like `DOMAIN=home`
- ❌ Don't commit .env file to git - only commit .env.example
- ❌ Don't hardcode IPs in dynamic.yml - use hostnames (wonko.local, not 192.168.x.x)
- ❌ Don't use HTTP→HTTPS redirect without proper certificates (scary browser warnings)
- ❌ Don't create `traefik-network` inside docker-compose - use external network
- ❌ Don't skip connectivity test from orangepi5b to wonko.local before deploying Traefik
- ❌ Don't expect Docker provider to discover wonko.local services (use File provider)

## Multi-Host Architecture - How It Works

### This Implementation Uses
- **Traefik on orangepi5b.local**: Acts as edge/gateway node
- **Docker Provider**: Auto-discovers local orangepi5b containers (Portainer, Zigbee)
- **File Provider**: Manual routes to wonko.local services (Kibana, ES, n8n, etc.)
- **Network Flow**: Client → orangepi5b:80/443 → Traefik → wonko.local:PORT

### Workarounds for Multi-Host
1. **Keep current approach**: Services on orangepi5b.local use direct port exposure
2. **Run Traefik on each host**: Separate reverse proxy per host, different domains
3. **Use Docker Swarm**: Enables overlay networks and multi-host discovery (NOT recommended per user preference)
4. **External service discovery**: Consul/etcd for service registry (complex)
5. **SSH Docker connection**: Traefik connects to remote Docker daemon via SSH (experimental)

### Tailscale Integration (Future)
- Tailscale provides secure remote access to entire network
- Access services via Tailscale IPs: `http://100.x.y.z:5678`
- Can be combined with Traefik: Tailscale for network access, Traefik for routing
- Traefik can route based on Tailscale IPs if needed

### Cloudflare Tunnel Integration (Future)
- Cloudflare Tunnel exposes local services to internet without port forwarding
- Run cloudflared container connected to Traefik network
- Route public URLs → Cloudflare Tunnel → Traefik → Services
- Requires Cloudflare account and tunnel setup

## Portainer GitHub Integration

**CRITICAL**: Ensure the stack can be deployed directly from GitHub via Portainer:

```yaml
REQUIREMENTS:
  - All necessary files in infra/traefik/ directory
  - .env.example with clear placeholder values
  - docker-compose.yml uses ${VARIABLE} syntax (not hardcoded values)
  - config/dynamic.yml tracked in git with wonko.local references
  - README.md with deployment instructions

PORTAINER DEPLOYMENT STEPS:
  1. In Portainer UI on orangepi5b.local:
     - Stacks → Add Stack → Git Repository
     - Repository URL: https://github.com/youruser/home-docker-stacks
     - Repository reference: main (or your branch)
     - Compose path: infra/traefik/docker-compose.yml
  2. Set Environment Variables in Portainer UI:
     - DOMAIN=home
     - WONKO_HOST=wonko.local
  3. Deploy stack
  4. Portainer will automatically pull updates when you push to GitHub

VALIDATION:
  - Test deploy from GitHub before marking PRP complete
  - Verify environment variables are correctly substituted
  - Confirm config/dynamic.yml is accessible (mounted correctly)
```

## Next Steps After PRP Completion
1. Test Portainer deployment from GitHub repository
2. Verify Kibana and Elasticsearch routing via Traefik
3. Add more wonko.local services to dynamic.yml (n8n, Prefect, Neo4j)
4. Optional: Add local orangepi5b services via Docker provider labels
5. Set up Let's Encrypt certificates with DNS challenge for HTTPS
6. Configure Cloudflare Tunnel for public endpoints (if needed)
7. Add authentication middleware for sensitive services (dashboard, Portainer)
8. Implement monitoring/logging for Traefik access logs

## References and Sources
- [Traefik Docker Provider Documentation](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik Docker Provider Configuration Reference](https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/)
- [Docker Official Traefik Guide](https://docs.docker.com/guides/traefik/)
- [HTTP to HTTPS Redirect Examples](https://stackoverflow.com/questions/58356714/how-to-redirect-http-to-https-with-traefik-2-0-and-docker-compose-labels)
- [Traefik v2 Examples Repository](https://github.com/DoTheEvo/Traefik-v2-examples)
- [Traefik Router Configuration](https://doc.traefik.io/traefik/routing/routers/)
- [Traefik Middleware Overview](https://doc.traefik.io/traefik/middlewares/http/overview/)

---

## PRP Confidence Score: 9.0/10

**Reasoning:**
- ✅ Comprehensive context provided (docs, examples, codebase patterns)
- ✅ Clear step-by-step tasks (11 tasks) with validation at each step
- ✅ Real-world examples from user's existing stacks (Kibana, Elasticsearch on wonko.local)
- ✅ Known gotchas and anti-patterns documented
- ✅ Architecture clearly defined: orangepi5b.local as edge node, File provider for wonko.local
- ✅ Git security checklist included (.gitignore requirements)
- ✅ Portainer GitHub deployment instructions explicit
- ✅ Validation gates are executable and specific to orangepi5b deployment
- ✅ Pseudocode includes complete docker-compose.yml and dynamic.yml examples
- ⚠️  -0.5: DNS/hosts file configuration is environment-specific (but alternatives provided)
- ⚠️  -0.5: HTTPS/TLS setup is optional and marked for future implementation

**Expected Outcome:**
- AI agent successfully deploys Traefik on orangepi5b.local
- Kibana and Elasticsearch accessible via clean URLs (kibana.home, es.home)
- File provider routing works cross-host (orangepi5b → wonko.local)
- Stack deployable from GitHub via Portainer
- Any issues resolvable using troubleshooting steps and validation gates provided
- wonko.local services require NO modifications (ports remain exposed)
