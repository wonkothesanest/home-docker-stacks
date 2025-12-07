name: "Tailscale Secure Networking for Multi-Host Home Lab"
description: |

## Goal
Implement Tailscale-based secure remote access layer for a multi-node Docker home lab environment using subnet router pattern, enabling private VPN access to all services without opening router ports, with integration with Traefik reverse proxy.

## Why
- **Zero-Trust Remote Access**: Securely access all home-lab services from anywhere without exposing ports on your router
- **Multi-Host Connectivity**: Connect services across wonko.local and orangepi5b.local seamlessly via private network
- **NAT Traversal**: Automatic peer-to-peer connections that work through firewalls and NAT
- **MagicDNS Integration**: Clean DNS names for all nodes (e.g., `wonko`, `orangepi5b`) without manual DNS configuration
- **Simple Architecture**: One subnet router on always-on infrastructure node (orangepi5b) routes entire home LAN
- **Traefik Integration**: Provides secure transport layer for Traefik routing, keeping HTTP routing internal
- **Exit Node Option**: Route internet traffic through home network when traveling
- **No Service Changes**: Existing services remain unchanged, accessed through subnet routing

## What
Implement Tailscale v1.78+ with subnet router pattern:
- Tailscale subnet router on orangepi5b.local (always-on infrastructure host)
- Tailscale client node on wonko.local (workstation)
- Subnet router advertises entire home LAN (192.168.1.0/24 or your subnet)
- Exit node configuration (optional) for internet routing
- MagicDNS for clean hostname resolution
- ACL configuration for minimal attack surface
- State persistence across container restarts
- Integration with Traefik on orangepi5b for HTTP routing

### Success Criteria
- [ ] Tailscale containers running on both hosts with persistent state
- [ ] orangepi5b acts as subnet router, advertising LAN routes
- [ ] wonko accepts routes from orangepi5b
- [ ] Able to access services on both hosts via Tailscale from remote device
- [ ] MagicDNS resolves hostnames (wonko, orangepi5b) correctly
- [ ] Subnet routes approved and active in admin console
- [ ] Traefik on orangepi5b accessible via Tailscale for routing to backend services
- [ ] Services remain accessible via localhost/LAN for backward compatibility
- [ ] Tailscale admin console shows both nodes as connected
- [ ] Documentation complete for remote access patterns

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Official Tailscale Documentation
- url: https://tailscale.com/kb/1282/docker
  why: Primary Docker setup guide, environment variables, network modes, volume configuration
  critical: Covers TS_STATE_DIR persistence, TS_AUTHKEY auth, TS_ROUTES for subnet routing

- url: https://tailscale.com/kb/1019/subnets
  why: Subnet router documentation for advertising LAN routes
  critical: IP forwarding setup, route approval process, accept-routes configuration

- url: https://tailscale.com/kb/1406/quick-guide-subnets
  why: Quick start guide for subnet routing with specific commands

- url: https://tailscale.com/kb/1103/exit-nodes
  why: Exit node setup for routing internet traffic through home network

- url: https://tailscale.com/kb/1081/magicdns
  why: MagicDNS configuration and hostname resolution patterns

- url: https://tailscale.com/kb/1018/acls
  why: ACL policy language for access control and security

- url: https://tailscale.com/blog/docker-tailscale-guide
  why: Deep dive blog post on Docker patterns and best practices

# Codebase References
- file: infra/portainer/docker-compose.yml
  why: Simple service pattern to mirror for Tailscale container structure on orangepi5b

- file: infra/traefik/docker-compose.yml
  why: Traefik runs on orangepi5b, will be accessible via Tailscale

- file: iot/zigbee-stack/docker-compose.yml
  why: Device mounting pattern for special hardware access (reference for /dev/net/tun)

- file: CLAUDE.md
  why: Repository conventions, updated to show Traefik on orangepi5b as edge/gateway node
```

### Current Codebase Structure
```bash
/media/dusty/TB2/workspace/dusty/home-docker-stacks/
├── apps/
│   ├── homepage/              # Dashboard (wonko.local)
│   ├── n8n-stack/             # n8n + Postgres (wonko.local, port 5678)
│   ├── prefect-stack/         # Prefect (wonko.local, ports 4200, 8080)
│   └── librechat/             # (not yet configured)
├── data/
│   ├── neo4j/                 # Neo4j + NeoDash (wonko.local, ports 7475, 7688, 5005)
│   └── search-stack/          # Elasticsearch + Kibana (wonko.local, ports 9200, 5601)
├── infra/
│   ├── mcp/                   # MCP server (wonko.local, port 8000)
│   ├── portainer/             # Portainer (orangepi5b.local, ports 9443, 8000)
│   └── traefik/               # Traefik reverse proxy (orangepi5b.local - edge/gateway node)
├── iot/
│   └── zigbee-stack/          # Zigbee2MQTT + Mosquitto (orangepi5b.local)
└── PRPs/

HOST DISTRIBUTION:
- orangepi5b.local (Raspberry Pi - Infrastructure/Gateway Node):
    * Always-on infrastructure host
    * Traefik (reverse proxy/edge router)
    * Portainer (management)
    * Zigbee2MQTT, Mosquitto (IoT)
    * IP: 192.168.1.101 (example - adjust to actual)
    * ROLE: Tailscale subnet router + exit node

- wonko.local (Main Workstation):
    * May not be always-on
    * n8n, prefect, elasticsearch, kibana, neo4j, homepage, mcp
    * IP: 192.168.1.100 (example - adjust to actual)
    * ROLE: Tailscale client node (accepts routes)

NETWORK TOPOLOGY:
- LAN Subnet: 192.168.1.0/24 (example - verify actual subnet)
- Docker bridge networks: Per-stack isolation
- Traefik network: traefik-network (external, for service routing)
- Tailscale IPs: 100.x.x.x range (assigned by Tailscale)

ARCHITECTURE RATIONALE:
- orangepi5b is subnet router because:
    * Always-on (Raspberry Pi, low power)
    * Already gateway node with Traefik
    * Infrastructure services (Portainer)
    * Logical place for network routing
```

### Desired Codebase Structure with Tailscale
```bash
/media/dusty/TB2/workspace/dusty/home-docker-stacks/
├── infra/
│   ├── tailscale/                          # NEW - Tailscale stack
│   │   ├── docker-compose.yml              # Tailscale service definition
│   │   ├── .env.example                    # Template for auth keys and config
│   │   ├── state/                          # Volume mount for Tailscale state (gitignored)
│   │   └── README.md                       # Quick reference for Tailscale commands
│   ├── traefik/                            # EXISTS on orangepi5b (no changes needed)
│   ├── portainer/                          # EXISTS on orangepi5b
│   └── mcp/                                # EXISTS on wonko
├── docs/
│   └── tailscale-access.md                 # NEW - Guide for accessing services via Tailscale
└── .gitignore                              # MODIFIED - Add state/ directories

DEPLOYMENT:
- orangepi5b.local: infra/tailscale/ (subnet router + exit node)
- wonko.local: infra/tailscale/ (client node, accepts routes)
- Same docker-compose.yml structure, different .env configuration per host
```

### Known Gotchas & Important Considerations

```yaml
# CRITICAL: Subnet Router Host Selection
# orangepi5b is the subnet router because:
# - Always-on (Raspberry Pi, low power consumption)
# - Already serves as gateway/edge node with Traefik
# - Infrastructure host with Portainer
# - wonko is a workstation that may not be always-on
#
# If subnet router is offline, remote access to LAN stops working
# (but direct Tailscale IP access to wonko would still work)

# CRITICAL: Tailscale State Persistence
# Tailscale generates unique node keys stored in TS_STATE_DIR
# If state is lost, the node appears as NEW in admin console
# MUST use Docker volumes to persist /var/lib/tailscale
# Pattern: ./state:/var/lib/tailscale (with state/ in .gitignore)

# CRITICAL: Authentication Keys
# Use reusable, non-ephemeral auth keys for home lab
# Ephemeral keys auto-delete node when container stops
# Generate keys at: https://login.tailscale.com/admin/settings/keys
# One key per host (orangepi5b gets one, wonko gets another)

# CRITICAL: Network Capabilities
# Tailscale requires NET_ADMIN capability to configure network interfaces
# MUST include: cap_add: - NET_ADMIN
# For subnet router, also needs /dev/net/tun device access

# CRITICAL: IP Forwarding for Subnet Router (orangepi5b only)
# The HOST needs IP forwarding enabled
# On Linux: echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
# Docker container ALSO needs --sysctl net.ipv4.ip_forward=1
# Without this, subnet routing will not work

# CRITICAL: Route Approval
# Advertised routes must be approved in Tailscale admin console
# Routes are advertised but not active until approval
# Check admin console > Machines > [orangepi5b] > Subnets section
# Can auto-approve with autoApprovers in ACL policy

# GOTCHA: Userspace vs Kernel Networking
# Use TS_USERSPACE=false for subnet router (kernel mode)
# Better performance and required for subnet routing
# Requires /dev/net/tun device and NET_ADMIN capability

# GOTCHA: Tailscale Hostnames
# MagicDNS provides hostnames: machine-name (e.g., "wonko", "orangepi5b")
# Hostname is taken from TS_HOSTNAME environment variable
# Also available as FQDN: hostname.tail-xxxx.ts.net

# GOTCHA: Accessing Services via Tailscale
# Three ways to access services:
# 1. Via LAN IP through subnet router: http://192.168.1.100:5678
# 2. Via hostname + LAN port: http://wonko:5678 (requires local DNS or /etc/hosts)
# 3. Via Tailscale IP: http://100.x.x.x:5678 (direct Tailscale address)
#
# Subnet routing enables #1 and #2 without any service changes

# GOTCHA: Traefik Integration
# Traefik on orangepi5b is accessible via:
# - LAN IP: http://192.168.1.101 (through subnet router)
# - Tailscale IP: http://100.y.y.y (orangepi5b's Tailscale IP)
# - MagicDNS: http://orangepi5b (if local DNS configured)
#
# Traefik can route to services on wonko via LAN IPs
# No changes needed to Traefik configuration

# Pattern from existing codebase to follow:
# - Named volumes for persistence (portainer_data, es_data)
# - .env files for secrets (all stacks use .env + .env.example)
# - restart: unless-stopped (standard policy)
# - External networks when cross-stack communication needed
# - Environment variables use ${VAR} syntax
```

## Implementation Blueprint

### Architecture: Subnet Router on orangepi5b

**Decision**: orangepi5b.local acts as Tailscale subnet router

**Rationale**:
- Always-on infrastructure host (Raspberry Pi)
- Already serves as gateway/edge node with Traefik
- Logical location for network routing infrastructure
- wonko is workstation that may shutdown
- Simple: one subnet router for entire home LAN
- No changes to existing services required

**How it works**:
```
Remote Device
    ↓ (Tailscale VPN)
orangepi5b (subnet router)
    ↓ (advertises 192.168.1.0/24)
Home LAN
    ↓
Services on wonko.local (192.168.1.100)
Services on orangepi5b.local (192.168.1.101)
```

### Data Models and Structure

```yaml
# Tailscale Configuration Structure

ENVIRONMENT VARIABLES (orangepi5b - subnet router):
  TS_AUTHKEY:                    # Auth key from Tailscale admin console
    - Format: "tskey-auth-xxxxx-xxxxxxxxxxxxxx"
    - Type: Reusable (for persistent nodes)
    - Required: Yes

  TS_STATE_DIR:                  # State persistence directory
    - Value: "/var/lib/tailscale"
    - Mapped to: ./state:/var/lib/tailscale
    - Required: Yes

  TS_HOSTNAME:                   # Hostname for this node
    - Value: "orangepi5b"
    - Shown in: Tailscale admin console, MagicDNS

  TS_ROUTES:                     # Subnet routes to advertise
    - Value: "192.168.1.0/24"
    - Required: Yes (for subnet router)

  TS_USERSPACE:                  # Networking mode
    - Value: "false" (kernel mode, required for subnet router)

  TS_EXTRA_ARGS:                 # Additional arguments
    - Value: "--advertise-exit-node --ssh"
    - Purpose: Enable exit node and SSH access

ENVIRONMENT VARIABLES (wonko - client node):
  TS_AUTHKEY:                    # Different auth key
  TS_STATE_DIR:                  # Same path
  TS_HOSTNAME:                   # "wonko"
  TS_USERSPACE:                  # "false"
  TS_EXTRA_ARGS:                 # "--accept-routes --ssh"
  # NO TS_ROUTES - client node doesn't advertise routes

DOCKER VOLUMES:
  state_volume:
    type: bind
    source: ./state
    target: /var/lib/tailscale
    purpose: Persist node identity, keys, configuration

DOCKER DEVICES (kernel mode):
  /dev/net/tun:
    mode: rw
    purpose: TUN device for kernel networking

CAPABILITIES:
  NET_ADMIN:
    purpose: Configure network interfaces
    required: yes

SYSCTLS (subnet router only - orangepi5b):
  net.ipv4.ip_forward:
    value: 1
    purpose: Enable IP forwarding for routing
```

### Task List

```yaml
Task 1: Prepare Tailscale Infrastructure on Both Hosts
  ON BOTH orangepi5b AND wonko:
    CREATE infra/tailscale/ directory structure:
      mkdir -p infra/tailscale/state
      touch infra/tailscale/docker-compose.yml
      touch infra/tailscale/.env.example
      touch infra/tailscale/README.md

  UPDATE .gitignore (in repo root):
    ADD: infra/tailscale/state/
    ADD: infra/tailscale/.env
    PURPOSE: Prevent committing Tailscale state and auth keys

  PATTERN: Mirror infra/portainer/ structure
  CRITICAL: Create state directory BEFORE first run

Task 2: Generate Tailscale Auth Keys
  MANUAL STEP - Login to Tailscale admin console:
    URL: https://login.tailscale.com/admin/settings/keys

  GENERATE auth key for orangepi5b.local:
    - Click "Generate auth key"
    - Description: "orangepi5b.local homelab subnet router"
    - Enable "Reusable" (allow reconnection)
    - Disable "Ephemeral" (persist node)
    - Optional: Set expiration (90 days, 1 year, never)
    - Optional: Add tags: tag:homelab, tag:gateway
    - Copy key: tskey-auth-xxxxx-xxxxxxxxxxxxxx

  GENERATE second auth key for wonko.local:
    - Description: "wonko.local homelab client"
    - Same settings (reusable, non-ephemeral)
    - Optional: Add tags: tag:homelab, tag:workstation
    - Copy key: tskey-auth-yyyyy-yyyyyyyyyyyyyy

  SECURITY NOTE: Auth keys are secrets, never commit to git

Task 3: Create Tailscale Docker Compose (orangepi5b - Subnet Router)
  ON orangepi5b.local:

  CREATE infra/tailscale/docker-compose.yml:
    ---
    services:
      tailscale:
        image: tailscale/tailscale:stable
        container_name: tailscale
        hostname: orangepi5b
        restart: unless-stopped

        environment:
          - TS_AUTHKEY=${TS_AUTHKEY}
          - TS_STATE_DIR=/var/lib/tailscale
          - TS_HOSTNAME=orangepi5b
          - TS_ROUTES=${LAN_SUBNET}
          - TS_USERSPACE=false
          - TS_EXTRA_ARGS=--advertise-exit-node --ssh

        volumes:
          - ./state:/var/lib/tailscale

        devices:
          - /dev/net/tun:/dev/net/tun:rw

        cap_add:
          - NET_ADMIN

        sysctls:
          - net.ipv4.ip_forward=1
          - net.ipv6.conf.all.forwarding=1
    ---

  CREATE infra/tailscale/.env.example:
    ---
    # Tailscale Authentication Key (generate at https://login.tailscale.com/admin/settings/keys)
    # Use a reusable, non-ephemeral key
    TS_AUTHKEY=tskey-auth-xxxxx-xxxxxxxxxxxxxx

    # Your home LAN subnet (adjust to your actual network)
    # Common values: 192.168.1.0/24, 192.168.0.0/24, 10.0.0.0/24
    LAN_SUBNET=192.168.1.0/24
    ---

  CREATE infra/tailscale/README.md:
    ---
    # Tailscale Subnet Router (orangepi5b)

    This node acts as a subnet router, advertising the home LAN to the Tailscale network.

    ## Common Commands

    # Check status
    docker compose exec tailscale tailscale status

    # View logs
    docker compose logs -f

    # Restart
    docker compose restart

    # Check routes
    docker compose exec tailscale tailscale status --json | jq '.Self.AdvertisedRoutes'

    ## Setup
    1. Copy .env.example to .env
    2. Edit .env with your auth key and LAN subnet
    3. docker compose up -d
    4. Approve routes in Tailscale admin console
    ---

  PATTERN: Mirror infra/portainer/docker-compose.yml structure
  CRITICAL: This configuration makes orangepi5b a subnet router + exit node

Task 4: Enable Host IP Forwarding (orangepi5b only)
  ON orangepi5b.local host (not in container):

  RUN:
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

  VERIFY:
    sysctl net.ipv4.ip_forward
    # Expected output: net.ipv4.ip_forward = 1

  PURPOSE: Allow Tailscale container to route packets between Tailscale and LAN
  CRITICAL: Without this, subnet routing will not work
  PERSISTENCE: Changes persist across reboots via sysctl.d file

Task 5: Deploy Tailscale on orangepi5b
  ON orangepi5b.local:

  RUN in infra/tailscale/:
    cp .env.example .env
    # Edit .env with actual auth key and LAN subnet
    nano .env  # or vim, or vi

    docker compose up -d

  VERIFY container is running:
    docker compose ps
    # Expected: tailscale container status "Up"

    docker compose logs -f
    # Expected: "Logged in as...", "Advertised routes...", "Running"
    # Press Ctrl+C to exit logs

  CHECK Tailscale status:
    docker compose exec tailscale tailscale status
    # Expected: "orangepi5b", Tailscale IP (100.x.x.x), status

    docker compose exec tailscale tailscale ip -4
    # Expected: Shows 100.x.x.x IP address

  TROUBLESHOOTING:
    - If "authentication failed": Check TS_AUTHKEY is valid and not expired
    - If "permission denied /dev/net/tun": Check device mount in docker-compose.yml
    - If "operation not permitted": Check NET_ADMIN capability

Task 6: Approve Subnet Routes in Admin Console
  MANUAL STEP - Login to Tailscale admin console:
    URL: https://login.tailscale.com/admin/machines

  FIND orangepi5b node:
    - Look for "orangepi5b" in machine list
    - Should have "Subnet" badge indicating advertised routes

  APPROVE ROUTES:
    - Click on orangepi5b machine
    - Scroll to "Subnets" section
    - See advertised route: 192.168.1.0/24 (status: pending approval)
    - Click "Approve" button next to the route

  OPTIONAL - Enable exit node:
    - In same view, scroll to "Exit node" section
    - See "Advertised as exit node"
    - Enable/allow if you want to route internet through home network

  VERIFY routes are active:
    ON orangepi5b, run:
    docker compose exec tailscale tailscale status
    # Expected: Shows route as "approved" or "accepted"

  ALTERNATIVE: Configure autoApprovers in ACL policy file (see Task 11)

Task 7: Create Tailscale Docker Compose (wonko - Client Node)
  ON wonko.local:

  CREATE infra/tailscale/docker-compose.yml:
    ---
    services:
      tailscale:
        image: tailscale/tailscale:stable
        container_name: tailscale
        hostname: wonko
        restart: unless-stopped

        environment:
          - TS_AUTHKEY=${TS_AUTHKEY}
          - TS_STATE_DIR=/var/lib/tailscale
          - TS_HOSTNAME=wonko
          - TS_USERSPACE=false
          - TS_EXTRA_ARGS=--accept-routes --ssh

        volumes:
          - ./state:/var/lib/tailscale

        devices:
          - /dev/net/tun:/dev/net/tun:rw

        cap_add:
          - NET_ADMIN
    ---

  CREATE infra/tailscale/.env.example:
    ---
    # Tailscale Authentication Key (generate at https://login.tailscale.com/admin/settings/keys)
    # Use a reusable, non-ephemeral key (different from orangepi5b's key)
    TS_AUTHKEY=tskey-auth-yyyyy-yyyyyyyyyyyyyy
    ---

  CREATE infra/tailscale/README.md:
    ---
    # Tailscale Client Node (wonko)

    This node accepts routes from the subnet router (orangepi5b).

    ## Common Commands

    # Check status
    docker compose exec tailscale tailscale status

    # View logs
    docker compose logs -f

    # Restart
    docker compose restart

    # Check received routes
    docker compose exec tailscale ip route show table 52
    ---

  DIFFERENCES from orangepi5b:
    - NO TS_ROUTES (not advertising routes)
    - NO sysctls (not routing traffic)
    - Uses --accept-routes to receive routes from orangepi5b
    - No exit node advertisement

  PATTERN: Same structure as orangepi5b, simpler configuration

Task 8: Deploy Tailscale on wonko
  ON wonko.local:

  RUN in infra/tailscale/:
    cp .env.example .env
    # Edit .env with wonko's auth key (different from orangepi5b)
    nano .env

    docker compose up -d
    docker compose logs -f

  VERIFY:
    docker compose exec tailscale tailscale status
    # Expected: "wonko", 100.y.y.y IP, should see orangepi5b as peer
    # Expected: Shows routes received from orangepi5b

    docker compose exec tailscale tailscale ip -4
    # Expected: Shows wonko's Tailscale IP (different from orangepi5b)

  TEST connectivity between hosts:
    # From wonko, ping orangepi5b via Tailscale
    docker compose exec tailscale ping orangepi5b
    # Expected: Ping successful via Tailscale network

Task 9: Test Remote Access from Tailscale-Connected Device
  PREREQUISITE: Install Tailscale on laptop/phone/remote device for testing
    - Download from: https://tailscale.com/download
    - Login with same account as homelab nodes

  TEST basic connectivity:
    # From remote device:
    tailscale status
    # Expected: Shows both "orangepi5b" and "wonko" in peer list

    ping orangepi5b
    # Expected: Successful ping via MagicDNS

    ping wonko
    # Expected: Successful ping via MagicDNS

  TEST Tailscale IP access:
    # Get IPs from admin console or tailscale status
    ping 100.x.x.x  # orangepi5b's Tailscale IP
    ping 100.y.y.y  # wonko's Tailscale IP
    # Expected: Both successful

  TEST subnet routing:
    # From remote device, access services via LAN IPs
    curl -I http://192.168.1.101:9443  # Portainer on orangepi5b
    # Expected: HTTPS redirect or connection (may have cert warning)

    curl -I http://192.168.1.100:5601  # Kibana on wonko
    # Expected: HTTP 200 OK

    ping 192.168.1.100  # wonko's LAN IP
    ping 192.168.1.101  # orangepi5b's LAN IP
    # Expected: Both successful through subnet router

  EXPECTED: All services on both hosts reachable via LAN IPs through subnet router
  TROUBLESHOOTING:
    - If can ping Tailscale IPs but not LAN IPs: Routes not approved in admin console
    - If no response: Check IP forwarding on orangepi5b host
    - If partial access: Check firewall rules on hosts

Task 10: Test Traefik Access via Tailscale
  PREREQUISITE: Traefik deployed on orangepi5b (per traefik-reverse-proxy.md PRP)

  FROM remote Tailscale device:

  TEST Traefik dashboard:
    # Via LAN IP through subnet router
    curl -I http://192.168.1.101:8080/dashboard/
    # Expected: HTTP 200 OK or 301 redirect

    # Via Tailscale IP
    curl -I http://100.x.x.x:8080/dashboard/
    # Expected: HTTP 200 OK

    # Via MagicDNS hostname
    curl -I http://orangepi5b:8080/dashboard/
    # Expected: HTTP 200 OK

  TEST Traefik routing to services:
    # If Traefik routes are configured for services
    curl -H "Host: kibana.local" http://192.168.1.101/
    # Expected: Kibana response routed through Traefik

  VERIFY: Traefik can route to services on wonko via LAN
    # Traefik on orangepi5b can reach wonko services via LAN IPs
    # No special configuration needed due to subnet routing

  BENEFIT: Entire home lab accessible via Traefik through Tailscale

Task 11: Configure MagicDNS and ACL Policy
  MANUAL STEP - MagicDNS (usually enabled by default):
    - Login to admin console: https://login.tailscale.com/admin/dns
    - Verify "MagicDNS" is enabled
    - Hostnames: orangepi5b, wonko (simple names)
    - FQDNs: orangepi5b.tail-xxxx.ts.net, wonko.tail-xxxx.ts.net

  MANUAL STEP - ACL Policy:
    - Login to admin console: https://login.tailscale.com/admin/acls
    - Default policy allows all (fine for personal tailnet)

    RECOMMENDED ACL for home lab:
      {
        "acls": [
          // Allow all homelab nodes to communicate
          {
            "action": "accept",
            "src": ["tag:homelab"],
            "dst": ["tag:homelab:*"]
          },
          // Allow owner to access everything
          {
            "action": "accept",
            "src": ["autogroup:owner"],
            "dst": ["*:*"]
          }
        ],
        "tagOwners": {
          "tag:homelab": ["autogroup:admin"]
        },
        "autoApprovers": {
          "routes": {
            "192.168.1.0/24": ["tag:homelab"]
          }
        }
      }

  BENEFIT of autoApprovers:
    - Routes automatically approved from tagged nodes
    - No manual approval needed in admin console
    - Edit "192.168.1.0/24" to match your actual subnet

  TEST MagicDNS:
    # From any Tailscale device:
    nslookup orangepi5b
    # Expected: Resolves to 100.x.x.x

    nslookup wonko
    # Expected: Resolves to 100.y.y.y

Task 12: Optional - Test Exit Node
  PURPOSE: Route internet traffic through home network when traveling

  FROM remote Tailscale device:

  CHECK current exit node status:
    tailscale status
    # Look for "exit node" information

  ENABLE orangepi5b as exit node:
    tailscale set --exit-node=orangepi5b

  VERIFY internet routes through home:
    curl ifconfig.me
    # Expected: Shows your home public IP (not your current location's IP)

  TEST internet connectivity:
    curl -I https://www.google.com
    # Expected: HTTP 200 OK

  DISABLE exit node:
    tailscale set --exit-node=

  VERIFY back to normal routing:
    curl ifconfig.me
    # Expected: Shows your current location's IP

  USE CASE: Access geo-restricted content, appear to be at home

Task 13: Document Tailscale Access Patterns
  CREATE docs/tailscale-access.md:
    ---
    # Accessing Home Lab Services via Tailscale

    ## Overview
    Tailscale provides secure remote access to all home lab services using subnet routing.

    - **Subnet Router**: orangepi5b.local advertises home LAN (192.168.1.0/24)
    - **Client Node**: wonko.local accepts routes from orangepi5b
    - **MagicDNS**: Hostnames `orangepi5b` and `wonko` resolve automatically

    ## Prerequisites
    - Tailscale installed on your device
    - Connected to your tailnet (same account as homelab)

    ## Access Patterns

    ### Via LAN IPs (Recommended)
    Access services using their regular LAN IPs through subnet routing:
    - Kibana: http://192.168.1.100:5601
    - n8n: http://192.168.1.100:5678
    - Portainer: https://192.168.1.101:9443
    - Traefik Dashboard: http://192.168.1.101:8080/dashboard/

    ### Via Tailscale IPs
    Access services using Tailscale-assigned IPs:
    - orangepi5b: http://100.x.x.x:9443 (find IP in admin console)
    - wonko: http://100.y.y.y:5601

    ### Via Traefik (if configured)
    Access services through Traefik reverse proxy on orangepi5b:
    - http://192.168.1.101/ (with appropriate Host header)
    - Or configured Traefik routes

    ## Common Tasks

    ### Check Tailscale Status
    tailscale status

    ### View Available Routes
    ip route show table 52

    ### Enable Exit Node (Route Internet Through Home)
    tailscale set --exit-node=orangepi5b

    ### Disable Exit Node
    tailscale set --exit-node=

    ## Troubleshooting

    ### Can't Access LAN IPs
    - Check routes approved in admin console
    - Verify orangepi5b subnet router is online
    - Check IP forwarding: `sysctl net.ipv4.ip_forward`

    ### MagicDNS Not Resolving
    - Verify MagicDNS enabled in admin console
    - Check /etc/resolv.conf has Tailscale nameserver (100.100.100.100)

    ### Service Not Responding
    - Verify service is running on host
    - Check firewall rules on host
    - Test from LAN first to isolate Tailscale vs service issue
    ---

  UPDATE CLAUDE.md:
    - ADD Tailscale to "Host Distribution" section:
        * orangepi5b.local: Tailscale subnet router + exit node
        * wonko.local: Tailscale client node

    - ADD tailscale/ to "Stack Organization" under infra/

    - ADD note about remote access via Tailscale subnet routing

  UPDATE ReadMe.md:
    - Document Tailscale remote access setup
    - Link to docs/tailscale-access.md

Task 14: Final Validation and Cleanup
  VERIFY ALL:
    - [ ] Tailscale containers running on both hosts: `docker compose ps`
    - [ ] Both nodes show "Connected" in admin console
    - [ ] Subnet routes approved and active
    - [ ] Can ping both Tailscale IPs from remote device
    - [ ] Can ping LAN IPs through subnet router from remote device
    - [ ] Can access services via LAN IPs from remote device
    - [ ] Traefik accessible and functional via Tailscale
    - [ ] MagicDNS resolves hostnames correctly
    - [ ] Exit node works (optional)
    - [ ] State directories persist across container restarts
    - [ ] Logs show no errors

  VERIFY SECURITY:
    - [ ] .env files are gitignored: `git status`
    - [ ] state/ directories are gitignored
    - [ ] Auth keys not committed to git
    - [ ] Services NOT accessible from internet without Tailscale

  CLEANUP:
    - Verify .gitignore updated
    - Commit docker-compose.yml and .env.example files
    - Commit documentation
    - Do NOT commit .env or state/ directories

  DOCUMENTATION:
    - [ ] docs/tailscale-access.md created
    - [ ] CLAUDE.md updated
    - [ ] infra/tailscale/README.md created on both hosts

  TEST SCENARIOS:
    - [ ] Access Kibana from remote device via Tailscale
    - [ ] Access Portainer from remote device via Tailscale
    - [ ] Access Traefik dashboard from remote device
    - [ ] Services routed through Traefik work remotely
```

### Pseudocode for Key Components

```yaml
# Task 3: Tailscale docker-compose.yml (orangepi5b - subnet router)

services:
  tailscale:
    image: tailscale/tailscale:stable
    container_name: tailscale
    hostname: orangepi5b

    environment:
      # Authentication key from admin console
      - TS_AUTHKEY=${TS_AUTHKEY}

      # State directory for persistence
      - TS_STATE_DIR=/var/lib/tailscale

      # Hostname for MagicDNS
      - TS_HOSTNAME=orangepi5b

      # Advertise home LAN subnet
      - TS_ROUTES=${LAN_SUBNET}

      # Kernel networking mode (required for subnet routing)
      - TS_USERSPACE=false

      # Enable exit node and SSH
      - TS_EXTRA_ARGS=--advertise-exit-node --ssh

    volumes:
      # Persist Tailscale state across restarts
      - ./state:/var/lib/tailscale

    devices:
      # TUN device for kernel networking
      - /dev/net/tun:/dev/net/tun:rw

    cap_add:
      # Required for network configuration
      - NET_ADMIN

    sysctls:
      # Enable IP forwarding for routing
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.forwarding=1

    restart: unless-stopped

# .env file (orangepi5b):
# TS_AUTHKEY=tskey-auth-xxxxx-xxxxxxxxxxxxxx
# LAN_SUBNET=192.168.1.0/24
```

```yaml
# Task 7: Tailscale docker-compose.yml (wonko - client node)

services:
  tailscale:
    image: tailscale/tailscale:stable
    container_name: tailscale
    hostname: wonko

    environment:
      # Different auth key from orangepi5b
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_HOSTNAME=wonko
      # NO TS_ROUTES - not a subnet router
      - TS_USERSPACE=false
      # Accept routes from subnet router, enable SSH
      - TS_EXTRA_ARGS=--accept-routes --ssh

    volumes:
      - ./state:/var/lib/tailscale

    devices:
      - /dev/net/tun:/dev/net/tun:rw

    cap_add:
      - NET_ADMIN

    # NO sysctls - not routing traffic

    restart: unless-stopped

# .env file (wonko):
# TS_AUTHKEY=tskey-auth-yyyyy-yyyyyyyyyyyyyy
```

### Integration Points

```yaml
TAILSCALE NODES:
  orangepi5b.local:
    - Role: Subnet router + exit node
    - Advertises: 192.168.1.0/24 (home LAN)
    - Provides: Internet routing (exit node)
    - Hostname: orangepi5b (via MagicDNS)
    - Tailscale IP: 100.x.x.x (assigned by Tailscale)
    - Always-on: Yes (Raspberry Pi, low power)

  wonko.local:
    - Role: Client node
    - Accepts: Routes from orangepi5b
    - Hostname: wonko (via MagicDNS)
    - Tailscale IP: 100.y.y.y (assigned by Tailscale)
    - Always-on: No (workstation, may shutdown)

ACCESS FLOW:
  Remote Device
      ↓ (Tailscale VPN connection)
  orangepi5b (subnet router)
      ↓ (advertises 192.168.1.0/24)
  Home LAN
      ↓
  Services on wonko (192.168.1.100:5678, :5601, etc.)
  Services on orangepi5b (192.168.1.101:9443, :8080, etc.)

TRAEFIK INTEGRATION:
  - Traefik runs on orangepi5b (edge/gateway node)
  - Accessible via Tailscale:
      * LAN IP: http://192.168.1.101:80, :443, :8080
      * Tailscale IP: http://100.x.x.x:80, :443, :8080
      * MagicDNS: http://orangepi5b:80, :443, :8080
  - Traefik routes to services on wonko via LAN IPs
  - No Traefik configuration changes needed
  - Subnet routing makes everything "just work"

MAGICDNS:
  Hostnames:
    - Short: orangepi5b, wonko
    - FQDN: orangepi5b.tail-xxxx.ts.net, wonko.tail-xxxx.ts.net
  Resolution:
    - Automatic from any Tailscale client
    - No /etc/hosts or local DNS needed

ENVIRONMENT VARIABLES:
  CREATE infra/tailscale/.env on each host:
    # orangepi5b:
    TS_AUTHKEY=tskey-auth-xxxxx-xxxxxxxxxxxxxx
    LAN_SUBNET=192.168.1.0/24

    # wonko:
    TS_AUTHKEY=tskey-auth-yyyyy-yyyyyyyyyyyyyy

  NO CHANGES to other stacks (.env files remain unchanged)

.GITIGNORE:
  ADD to root .gitignore:
    # Tailscale
    infra/tailscale/.env
    infra/tailscale/state/

HOST SYSTEM CHANGES:
  orangepi5b.local:
    - Enable IP forwarding: /etc/sysctl.d/99-tailscale.conf
    - No firewall changes (Tailscale handles this)

  wonko.local:
    - No system changes needed (client only)
```

## Validation Loop

### Level 1: Container Tests (orangepi5b)
```bash
# Deploy Tailscale on orangepi5b
cd infra/tailscale
cp .env.example .env
# Edit .env with auth key and LAN subnet
docker compose up -d

# Verify container is running
docker compose ps
# Expected: tailscale container status "Up"

# Check logs
docker compose logs
# Expected: "Logged in", "Advertised routes", no errors

# Check Tailscale status
docker compose exec tailscale tailscale status
# Expected: "orangepi5b", 100.x.x.x IP, "Connected"

# Verify advertised routes
docker compose exec tailscale tailscale status --json | jq '.Self.AdvertisedRoutes'
# Expected: ["192.168.1.0/24"]

# Check IP forwarding on host
sysctl net.ipv4.ip_forward
# Expected: net.ipv4.ip_forward = 1
```

### Level 2: Admin Console Verification
```bash
# Manual steps:

1. Login: https://login.tailscale.com/admin/machines
   - Expected: "orangepi5b" in machine list, green "Connected" status

2. Click on orangepi5b
   - Expected: Tailscale IP shown (100.x.x.x)
   - Expected: "Subnet" badge present

3. Scroll to Subnets section
   - Expected: Route "192.168.1.0/24" shown
   - Action: Click "Approve" if pending

4. Check exit node section
   - Expected: "Advertised as exit node" shown
   - Action: Enable if desired

# Verify route approval via CLI
docker compose exec tailscale tailscale status
# Expected: Shows route status as approved
```

### Level 3: Container Tests (wonko)
```bash
# Deploy Tailscale on wonko
cd infra/tailscale
cp .env.example .env
# Edit .env with wonko's auth key
docker compose up -d

# Verify
docker compose exec tailscale tailscale status
# Expected: "wonko", 100.y.y.y IP
# Expected: Shows orangepi5b as peer
# Expected: Shows received routes

# Test connectivity to orangepi5b
docker compose exec tailscale ping orangepi5b
# Expected: Successful ping
```

### Level 4: Remote Access Tests
```bash
# From remote device with Tailscale:

# Check peer list
tailscale status
# Expected: Both "orangepi5b" and "wonko" in list

# Test Tailscale IP connectivity
ping 100.x.x.x  # orangepi5b
ping 100.y.y.y  # wonko
# Expected: Both successful

# Test MagicDNS
ping orangepi5b
ping wonko
# Expected: Both resolve and respond

# Test subnet routing - LAN IPs
ping 192.168.1.101  # orangepi5b LAN IP
ping 192.168.1.100  # wonko LAN IP
# Expected: Both successful through subnet router
```

### Level 5: Service Access Tests
```bash
# From remote Tailscale device:

# Test services on wonko via LAN IP
curl -I http://192.168.1.100:5601  # Kibana
# Expected: HTTP 200 OK

curl -I http://192.168.1.100:5678  # n8n
# Expected: HTTP 200 OK

# Test services on orangepi5b
curl -Ik https://192.168.1.101:9443  # Portainer
# Expected: HTTPS connection (cert warning OK)

# Test Traefik dashboard
curl -I http://192.168.1.101:8080/dashboard/
# Expected: HTTP 200 OK or redirect
```

### Level 6: Exit Node Test (Optional)
```bash
# From remote Tailscale device:

# Enable exit node
tailscale set --exit-node=orangepi5b

# Verify IP shows home network
curl ifconfig.me
# Expected: Your home public IP

# Test internet connectivity
curl -I https://www.google.com
# Expected: HTTP 200 OK

# Disable exit node
tailscale set --exit-node=
```

## Final Validation Checklist
- [ ] orangepi5b Tailscale container running: `docker compose ps`
- [ ] wonko Tailscale container running: `docker compose ps`
- [ ] Both nodes "Connected" in admin console
- [ ] Subnet routes approved: admin console > orangepi5b > Subnets
- [ ] Can ping Tailscale IPs from remote device
- [ ] Can ping LAN IPs from remote device (subnet routing works)
- [ ] MagicDNS resolves `orangepi5b` and `wonko`
- [ ] Can access Kibana (wonko) via Tailscale from remote
- [ ] Can access Portainer (orangepi5b) via Tailscale from remote
- [ ] Traefik dashboard accessible via Tailscale
- [ ] Exit node works if enabled
- [ ] State persists across container restart: `docker compose restart && docker compose ps`
- [ ] .env files gitignored: `git status`
- [ ] Documentation complete: `docs/tailscale-access.md` exists
- [ ] CLAUDE.md updated with Tailscale info

## Anti-Patterns to Avoid
- ❌ Don't use ephemeral auth keys (node disappears on restart)
- ❌ Don't skip persisting TS_STATE_DIR (lose node identity)
- ❌ Don't forget NET_ADMIN capability (Tailscale won't work)
- ❌ Don't skip IP forwarding on orangepi5b host (subnet routing fails)
- ❌ Don't forget to approve routes in admin console (routes won't activate)
- ❌ Don't commit .env files to git (exposes auth keys)
- ❌ Don't use TS_USERSPACE=true for subnet router (won't work properly)
- ❌ Don't advertise same subnet from multiple nodes (routing conflicts)
- ❌ Don't skip testing connectivity after each stage (catch issues early)
- ❌ Don't make wonko the subnet router (it may shutdown, breaking remote access)

## References and Sources
- [Using Tailscale with Docker - Official Docs](https://tailscale.com/kb/1282/docker)
- [Subnet routers - Full Documentation](https://tailscale.com/kb/1019/subnets)
- [Configure a subnet router - Quick Guide](https://tailscale.com/kb/1406/quick-guide-subnets)
- [Exit Nodes Documentation](https://tailscale.com/kb/1103/exit-nodes)
- [MagicDNS Overview](https://tailscale.com/kb/1081/magicdns)
- [ACL Policy Language](https://tailscale.com/kb/1018/acls)
- [Docker deep dive blog post](https://tailscale.com/blog/docker-tailscale-guide)

---

## PRP Confidence Score: 9.5/10

**Reasoning:**
- ✅ Simplified to single approach (subnet router only)
- ✅ Clear architecture with orangepi5b as always-on subnet router
- ✅ Comprehensive step-by-step tasks with validation
- ✅ All necessary context and commands provided
- ✅ Integration with existing Traefik setup
- ✅ Extensive validation loops with expected outputs
- ✅ Security considerations (ACLs, auth keys, gitignore)
- ✅ No complex sidecar patterns to confuse implementation
- ⚠️ -0.5: Requires manual admin console steps (auth keys, route approval)

**Expected Outcome:** AI agent should successfully deploy Tailscale on both hosts with orangepi5b acting as subnet router, enabling remote access to all services via LAN IPs. Simple, straightforward implementation with one clear path.
