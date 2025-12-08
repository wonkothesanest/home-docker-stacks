name: "Portainer Container Migration - Multi-Host Home Lab Consolidation"
description: |

## ⚠️ CRITICAL: TWO-PHASE PROCESS - DO NOT SKIP

**This migration is split into TWO mandatory phases:**

### PHASE A: PLANNING ONLY (Safe - No Changes Made)
- Inventory all containers
- Design migration plans
- Create backup procedures
- Document rollback steps
- **OUTPUT: Migration plans for human review**

### 🛑 MANDATORY STOP POINT 🛑
**STOP HERE. DO NOT PROCEED TO PHASE B WITHOUT:**
1. ✅ Human review of all migration plans
2. ✅ Human verification of backup procedures
3. ✅ Human confirmation that backups are tested and working
4. ✅ Human approval to proceed with actual migration
5. ✅ Maintenance window scheduled (if needed)

### PHASE B: EXECUTION (Makes Changes - Only After Human Approval)
- Execute backups
- Stop containers
- Migrate data
- Deploy new stacks
- Validate services

**AI AGENT INSTRUCTION**: After completing Phase A, you MUST stop and present all plans to the user for review. DO NOT begin Phase B (actual migration) without explicit user approval. This is a safety-critical requirement.

---

## Goal
Migrate all manually-started Docker containers across home lab hosts (orangepi5b.local, wonko.local) to Portainer-managed stacks backed by GitHub repository, ensuring zero data loss, standardized configuration, and reproducible deployments. This creates a single source of truth model where all infrastructure is version-controlled and manageable through Portainer UI.

## Why
- **Reproducibility**: All container configurations tracked in Git, not lost in shell history
- **Consistency**: Standardized deployment patterns across hosts using docker-compose.yml
- **Disaster Recovery**: Easy recreation of entire infrastructure from Git repository
- **Team Visibility**: Clear documentation of what runs where, how it's configured
- **Portainer Benefits**: Visual management, stack updates via Git sync, centralized control
- **Data Safety**: Explicit volume management prevents accidental data loss

## What
Create comprehensive inventory and migration plan for all Docker containers, converting manual deployments to Portainer stacks with preserved persistent data.

### Success Criteria

**Phase A (Planning) - Must Complete Before Stop Point:**
- [ ] Complete inventory document listing all containers across all hosts with full configuration
- [ ] All containers have corresponding docker-compose.yml in appropriate category (apps/data/infra/iot)
- [ ] All .env.example files created with required variables documented
- [ ] Migration checklist created per service with backup/rollback procedures
- [ ] Data migration plan for each service with volume mappings documented
- [ ] Backup procedures documented and validated
- [ ] **STOP: Present plans to human for review**

**Phase B (Execution) - Only After Human Approval:**
- [ ] Human has reviewed and approved all migration plans
- [ ] Backups executed and verified for all services
- [ ] Test migration executed on at least one non-critical service
- [ ] Production migrations executed with validation at each step
- [ ] Documentation updated with Portainer stack deployment instructions
- [ ] Validation that all services work identically post-migration

## All Needed Context

### Documentation & References
```yaml
- url: https://docs.docker.com/engine/reference/commandline/inspect/
  why: Extract full container configuration from running containers (ports, env, volumes, networks)
  critical: Use `docker inspect <container>` to get JSON with all runtime config

- url: https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes
  why: Volume backup and migration strategies, essential for data preservation
  critical: Use `docker run --rm --volumes-from <container> -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /data` pattern

- url: https://docs.portainer.io/user/docker/stacks/
  why: How Portainer stacks work, Git integration, environment variable management
  critical: Stacks can auto-sync from Git, but need proper .env setup

- url: https://docs.portainer.io/user/git/stacks-from-git
  why: Deploy stacks directly from GitHub repository
  critical: Requires compose path relative to repo root (e.g., "apps/n8n-stack/docker-compose.yml")

- url: https://www.composerize.com/
  why: Tool to convert docker run commands to docker-compose.yml format
  critical: Helps reverse-engineer manual containers, but verify output carefully

- url: https://docs.docker.com/compose/compose-file/
  why: Complete docker-compose.yml syntax reference
  critical: Version 3.8 is well-supported by Portainer, use for consistency

- url: https://docs.docker.com/storage/bind-mounts/
  why: Understanding bind mounts vs named volumes for data migration planning

- url: https://docs.portainer.io/admin/environments/add/docker
  why: Adding multiple Docker hosts to single Portainer instance
  critical: Use Portainer agent for remote hosts or socket proxy

- file: apps/n8n-stack/docker-compose.yml
  why: Example of multi-service stack with database, shows proper depends_on usage
  pattern: |
    - Named volumes for postgres data
    - Environment variables from .env file
    - Service dependencies (n8n depends on postgres)
    - Restart policies (always/unless-stopped)

- file: data/search-stack/docker-compose.yml
  why: Example of custom network configuration and named volume with specific name
  pattern: |
    - Custom network: elasticsearch-network
    - Named volume with explicit name: prefect_data_getters_es_data
    - Cross-stack network sharing (MCP server connects to this network)

- file: iot/zigbee-stack/docker-compose.yml
  why: Example of device mapping and bind mounts for hardware access
  pattern: |
    - Device mapping via environment variable: ${DONGLE}:/dev/ttyUSB0
    - Bind mounts for persistent config: ./zigbee2mqtt-data:/app/data
    - Special permissions: group_add dialout, user 1001:1001

- file: apps/homepage/docker-compose.yaml
  why: Example of custom Dockerfile build with local context
  pattern: |
    - Build from local Dockerfile
    - Copies config files into image at build time
    - Docker socket mount for container inspection
    - Custom image name: local-homepage-with-configs:latest

- file: infra/mcp/docker-compose.yml
  why: Example of multi-network service connecting to external networks
  pattern: |
    - Connects to multiple networks (mcp-network, elasticsearch-network)
    - External network reference for cross-stack communication

- file: CLAUDE.md
  why: Repository patterns, host distribution, common commands
  critical: |
    - orangepi5b.local runs: Portainer, Zigbee stack
    - wonko.local runs: n8n, Prefect, ES/Kibana, Neo4j, Homepage, MCP
    - Always create .env.example (tracked) and .env (gitignored)
```

### Current Codebase Structure
```bash
/media/dusty/TB2/workspace/dusty/home-docker-stacks/
├── apps/                    # Application services
│   ├── homepage/           # Dashboard (custom Docker build)
│   │   ├── docker-compose.yaml
│   │   ├── Dockerfile
│   │   ├── .env.example
│   │   └── config/
│   ├── n8n-stack/          # Workflow automation
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   ├── prefect-stack/      # Workflow orchestration
│   │   └── docker-compose.yml
│   └── librechat/          # (exists but not configured)
├── data/                    # Data infrastructure
│   ├── neo4j/              # Graph database
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── search-stack/       # Elasticsearch + Kibana
│       ├── docker-compose.yml
│       └── .env.example
├── infra/                   # Infrastructure services
│   ├── mcp/                # Model Context Protocol server
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── portainer/          # Container management UI
│       └── docker-compose.yml
├── iot/                     # IoT services
│   └── zigbee-stack/       # Zigbee2MQTT + Mosquitto
│       ├── docker-compose.yml
│       ├── .env.example
│       └── zigbee2mqtt-data/  # Bind mount for persistent config
├── CLAUDE.md               # Project documentation
├── ReadMe.md              # Overview
└── PRPs/                   # Implementation plans
    ├── inputs/
    ├── templates/
    └── *.md                # Other PRPs

Current Patterns:
- Stack organization by purpose (apps/data/infra/iot)
- docker-compose.yml in each stack directory
- .env for secrets (gitignored), .env.example for templates (tracked)
- Named volumes OR bind mounts for persistence
- Custom networks when cross-stack communication needed
- version: '3.8' for compose files (Portainer compatible)
```

### Desired Codebase Structure After Migration
```bash
# New directories will be created as needed under existing categories:

apps/
├── <new-app-stack>/        # Any newly discovered app containers
│   ├── docker-compose.yml
│   └── .env.example

data/
├── <new-data-service>/     # Any newly discovered data services
│   ├── docker-compose.yml
│   └── .env.example

infra/
├── <new-infra-service>/    # Any newly discovered infrastructure
│   ├── docker-compose.yml
│   └── .env.example

docs/                        # NEW: Migration documentation
├── inventory/
│   ├── orangepi5b-containers.yaml    # Complete inventory per host
│   ├── wonko-containers.yaml
│   └── inventory-combined.yaml       # Master list
├── migration/
│   ├── migration-plan.md             # Overall migration strategy
│   ├── <service-name>-migration.md   # Per-service migration steps
│   └── rollback-procedures.md        # Emergency rollback steps
└── portainer/
    ├── stack-deployment-guide.md     # How to deploy stacks via Portainer
    └── host-mapping.md               # Which stacks run on which hosts

# Each new or existing stack follows pattern:
<category>/<stack-name>/
├── docker-compose.yml       # Service definitions
├── .env.example            # Template with placeholder values
├── .env                    # Actual values (gitignored, created locally)
├── <data-dirs>/            # Bind mounts if needed (gitignored)
└── README.md               # Stack-specific notes (optional)
```

### Known Gotchas & Library Quirks
```yaml
Docker Compose:
  - CRITICAL: Portainer requires version 3.x compose files, avoid version 4.x features
  - GOTCHA: Named volumes with explicit names (e.g., `name: custom_name`) allow cross-stack sharing
  - GOTCHA: Bind mounts are relative to compose file location, use `./` for clarity
  - PATTERN: Always use `restart: unless-stopped` or `always` for production services

Docker Inspect:
  - CRITICAL: `docker inspect` output is JSON, requires jq or python parsing
  - GOTCHA: Volume paths in Mounts section show both Source (host) and Destination (container)
  - GOTCHA: Env vars in Config.Env are in KEY=VALUE format, may contain secrets
  - TIP: Use `docker inspect --format '{{json .Mounts}}' <container> | jq` for clean output

Portainer Stacks:
  - CRITICAL: Stack names must be unique across Portainer instance
  - GOTCHA: Environment variables can be set via Portainer UI OR .env file, UI takes precedence
  - PATTERN: Use Git auto-sync for infrastructure-as-code, manual for testing
  - GOTCHA: Portainer can't build Dockerfiles from Git by default, use pre-built images OR build manually

Data Migration:
  - CRITICAL: Always backup before migration using docker cp or volume export
  - GOTCHA: Named volumes persist even after container removal unless `-v` flag used
  - PATTERN: Test migration on copy of production data first
  - GOTCHA: Volume ownership/permissions may need adjustment after migration (chown)

Device Access (IoT):
  - CRITICAL: Serial devices require dialout group membership
  - GOTCHA: Device paths like /dev/ttyUSB0 change on reboot, use by-id paths instead
  - PATTERN: Pass device path via env var for flexibility: ${DONGLE}:/dev/ttyUSB0

Networks:
  - GOTCHA: Cross-stack communication requires external network definition
  - PATTERN: Define network in one stack, reference as external in others
  - Example: search-stack defines elasticsearch-network, MCP stack uses it as external
```

## Implementation Blueprint

---

# 🔵 PHASE A: PLANNING (SAFE - NO CHANGES)

**AI Agent**: You are now entering the PLANNING phase. You will NOT make any changes to running containers. Your job is to gather information and create plans for human review.

---

### Phase 1: Discovery & Inventory

**Goal**: Document every container running across all hosts with complete configuration

**⚠️ SAFETY**: This phase is READ-ONLY. You will inspect containers but NOT modify them.

#### Task 1: Inventory All Containers on Each Host

```bash
# On each host (orangepi5b.local, wonko.local), run:

# List all containers
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# For each container, extract full configuration
for container in $(docker ps -q); do
  name=$(docker inspect --format '{{.Name}}' $container | sed 's/\///')
  echo "=== $name ==="
  docker inspect $container > "/tmp/inventory-${name}.json"

  # Extract key info in human-readable format
  echo "Image: $(docker inspect --format '{{.Config.Image}}' $container)"
  echo "Ports:"
  docker inspect --format '{{json .NetworkSettings.Ports}}' $container | jq
  echo "Volumes:"
  docker inspect --format '{{json .Mounts}}' $container | jq
  echo "Environment:"
  docker inspect --format '{{json .Config.Env}}' $container | jq
  echo "Networks:"
  docker inspect --format '{{json .NetworkSettings.Networks}}' $container | jq
  echo ""
done

# Save to structured YAML inventory
# See: docs/inventory/<hostname>-containers.yaml
```

**Output**: Create `docs/inventory/orangepi5b-containers.yaml` and `docs/inventory/wonko-containers.yaml`

**Structure**:
```yaml
# Example inventory format
host: orangepi5b.local
date: 2025-12-07
containers:
  - name: portainer
    image: portainer/portainer-ce:latest
    status: running
    ports:
      - "9443:9443"
      - "8000:8000"
    volumes:
      - type: volume
        name: portainer_data
        destination: /data
      - type: bind
        source: /var/run/docker.sock
        destination: /var/run/docker.sock
    environment:
      - TZ=America/Denver
    networks:
      - bridge
    restart_policy: unless-stopped
    labels: {}
    managed_by: docker-compose  # or "manual" if docker run
    compose_location: infra/portainer/docker-compose.yml  # if managed by compose
    migration_status: already_in_git  # or "needs_migration"
    notes: "Already managed via compose, no migration needed"
```

#### Task 2: Categorize Containers for Migration

**For each container**, determine:
1. **Already managed?**: Check if it has compose file in repo
2. **Category**: apps / data / infra / iot
3. **Migration complexity**:
   - Simple (stateless, no volumes)
   - Moderate (named volumes, standard config)
   - Complex (bind mounts, device access, custom builds)
4. **Dependencies**: Does it depend on other containers?
5. **Data criticality**: Can data loss be tolerated? (NO for production)

**Output**: Create `docs/inventory/inventory-combined.yaml` with migration annotations

#### Task 3: Identify Data Locations and Volume Mappings

```bash
# For each container with volumes:

# List all volumes
docker volume ls

# Inspect each volume
docker volume inspect <volume-name>

# Identify bind mounts
docker inspect --format '{{json .Mounts}}' <container> | jq -r '.[] | select(.Type=="bind") | "\(.Source) -> \(.Destination)"'

# Check volume sizes (for backup planning)
docker system df -v
```

**Output**: Add volume mapping section to inventory with:
- Volume type (named vs bind)
- Host path (for bind mounts)
- Container path
- Estimated size
- Backup strategy

### Phase 2: Stack Design & Template Creation

**Goal**: Create docker-compose.yml and .env.example for each container/group needing migration

#### Task 4: Group Containers into Logical Stacks

**Grouping Strategy**:
- Containers that communicate → same stack
- Containers that share volumes → same stack
- Similar purpose containers → same stack
- Independent services → separate stacks

**Example groupings**:
- `apps/media-stack`: Plex, Sonarr, Radarr (if present)
- `infra/monitoring-stack`: Prometheus, Grafana (if present)
- `data/databases-stack`: Any standalone databases (if not already grouped)

#### Task 5: Create Compose Files for Each Stack

**For each stack needing migration**:

```yaml
# Template: <category>/<stack-name>/docker-compose.yml
version: '3.8'

services:
  <service-name>:
    image: <exact-image-from-inventory>
    container_name: <original-name>  # keep same name for compatibility
    restart: unless-stopped  # or 'always' based on original
    ports:
      - "<host-port>:<container-port>"  # from inventory
    environment:
      # Move to .env file, use ${VAR} syntax
      - VAR_NAME=${VAR_NAME}
    volumes:
      # Named volumes (preferred for Docker-managed data)
      - <volume_name>:/container/path
      # OR bind mounts (for config/data you manage)
      - ./<local-dir>:/container/path
    networks:
      - <network-name>  # if custom network needed
    devices:  # only if hardware access needed
      - ${DEVICE_PATH}:/dev/<device>
    # depends_on:  # if multi-service stack
    #   - other-service

volumes:
  <volume_name>:  # define named volumes
    # Use explicit name if cross-stack sharing needed:
    # name: shared_volume_name

networks:
  <network-name>:  # define custom networks
    driver: bridge
    # OR reference external network:
    # external: true
```

**Pattern to follow**: Mirror existing stacks like `apps/n8n-stack/docker-compose.yml`

#### Task 6: Create .env.example Files

**For each stack**:

```bash
# Template: <category>/<stack-name>/.env.example

# Service Configuration
SERVICE_NAME=example
PORT=8080
HOST=wonko.local

# Database (if applicable)
DB_USER=username
DB_PASSWORD=changeme
DB_NAME=database

# Paths (for bind mounts)
DATA_DIR=/path/to/data

# Hardware (for device access)
DEVICE_PATH=/dev/serial/by-id/device-identifier

# Feature Flags
ENABLE_FEATURE=true

# Notes:
# 1. Copy this file to .env before deploying
# 2. Replace placeholder values with actual secrets
# 3. .env is gitignored, never commit secrets
```

**Pattern to follow**: Mirror existing .env.example files like `apps/n8n-stack/.env.example`

### Phase 3: Data Migration Planning

**Goal**: Document exact steps to preserve data for each service during migration

#### Task 7: Create Per-Service Migration Plans

**For each service being migrated**, create `docs/migration/<service-name>-migration.md`:

```markdown
# <Service Name> Migration Plan

## Service Info
- Current host: <hostname>
- Current container: <container-name>
- Category: <apps/data/infra/iot>
- Stack location: <category>/<stack-name>

## Data Inventory
### Volumes
- Volume 1: <volume-name> → <container-path>
  - Type: named / bind
  - Size: <size>
  - Content: <description>
  - Critical: YES / NO

### Configuration Files
- File 1: <host-path> → <container-path>
  - Format: YAML / JSON / ENV / etc
  - Secrets: YES / NO

## Backup Procedure
```bash
# Backup named volume
docker run --rm \
  --volumes-from <container-name> \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/<service>-data-$(date +%Y%m%d).tar.gz /container/path

# Backup bind mount
tar czf backups/<service>-config-$(date +%Y%m%d).tar.gz /host/path/to/data
```

## Migration Steps
1. **Prepare**
   ```bash
   # Create stack directory
   mkdir -p <category>/<stack-name>

   # Copy compose file (already created in Phase 2)
   # Copy .env.example to .env and configure
   cp <category>/<stack-name>/.env.example <category>/<stack-name>/.env
   nano <category>/<stack-name>/.env  # Edit with actual values
   ```

2. **Backup** (NO SKIPPING THIS)
   ```bash
   # Execute backup procedure above
   # Verify backup archive is created and non-zero size
   ls -lh backups/<service>-*
   ```

3. **Stop Old Container**
   ```bash
   docker stop <container-name>
   # Do NOT use `docker rm -v` yet (preserve volumes)
   ```

4. **Data Migration** (choose strategy)

   **Option A: Reuse existing named volume**
   ```yaml
   # In docker-compose.yml, reference existing volume:
   volumes:
     service_data:
       external: true
       name: <existing-volume-name>
   ```

   **Option B: Reuse existing bind mount**
   ```yaml
   # In docker-compose.yml, use same host path:
   volumes:
     - /original/host/path:/container/path
   ```

   **Option C: Copy data to new volume**
   ```bash
   # Create new volume
   docker volume create <new-volume-name>

   # Copy data from old volume
   docker run --rm \
     -v <old-volume>:/source \
     -v <new-volume>:/dest \
     ubuntu bash -c "cp -av /source/. /dest/"

   # Update compose file to use new volume
   ```

5. **Deploy New Stack**
   ```bash
   cd <category>/<stack-name>
   docker compose up -d
   ```

6. **Verify**
   ```bash
   # Check container status
   docker compose ps

   # Check logs for errors
   docker compose logs -f <service-name>

   # Test service functionality
   # - For web services: curl or browser test
   # - For databases: connection test
   # - For hardware: device access test

   # Verify data presence
   docker compose exec <service-name> ls -la /container/path
   # Check that files/databases are present
   ```

7. **Finalize**
   ```bash
   # If all tests pass, remove old container
   docker rm <container-name>

   # Only remove old volume if using Option C (data copied)
   # docker volume rm <old-volume-name>

   # Document completion
   echo "✅ <service-name> migrated successfully on $(date)" >> docs/migration/migration-log.txt
   ```

## Rollback Procedure (if migration fails)
```bash
# Stop new stack
cd <category>/<stack-name>
docker compose down

# Restore from backup
docker run --rm \
  -v <volume-name>:/data \
  -v $(pwd)/backups:/backup \
  ubuntu bash -c "cd /data && tar xzf /backup/<service>-data-*.tar.gz --strip-components=1"

# Restart old container
docker start <container-name>

# Verify old container works
docker logs <container-name>
```

## Validation Checklist
- [ ] Backup created and verified
- [ ] Old container stopped
- [ ] New stack deployed
- [ ] Service accessible (port/URL check)
- [ ] Data present and correct
- [ ] Logs show no errors
- [ ] Application functionality tested
- [ ] Old container removed
- [ ] Documented in migration log

## Notes
<Any service-specific gotchas or considerations>
```

---

# 🛑 MANDATORY STOP POINT - HUMAN REVIEW REQUIRED 🛑

**AI Agent**: You have completed Phase A (Planning). You MUST now:

1. **Present the following deliverables to the user:**
   - Complete inventory files (`docs/inventory/*.yaml`)
   - All docker-compose.yml files created
   - All .env.example files created
   - Per-service migration plans (`docs/migration/*.md`)
   - Overall migration strategy summary

2. **Request human verification of:**
   - Are all containers accounted for in inventory?
   - Are backup procedures sufficient and tested?
   - Are migration plans clear and safe?
   - Are rollback procedures documented?
   - Is there anything mission-critical that needs special handling?

3. **Wait for explicit approval** with the phrase: "APPROVED TO PROCEED WITH PHASE B"

4. **DO NOT PROCEED** with Phase B (actual migration) until you receive explicit approval.

**User**: Before approving Phase B, verify:

```bash
# 1. Review inventory files
cat docs/inventory/*.yaml

# 2. Review migration plans
ls docs/migration/
cat docs/migration/<critical-service>-migration.md

# 3. Test backup procedure on ONE non-critical service
# Follow the backup commands in the migration plan
# Verify backup file is created and non-zero size

# 4. Test restore procedure from that backup
# Verify data can be restored successfully

# 5. Only after successful backup/restore test, approve Phase B
```

**Approval Checklist:**
- [ ] All containers inventoried and categorized
- [ ] Backup procedures tested on at least one service
- [ ] Restore procedures tested successfully
- [ ] Migration plans reviewed and understood
- [ ] Rollback procedures documented
- [ ] Maintenance windows scheduled (if needed)
- [ ] Team notified (if applicable)
- [ ] **I approve proceeding with Phase B: Execution**

---

# 🔴 PHASE B: EXECUTION (MAKES CHANGES - REQUIRES APPROVAL)

**AI Agent**: You may only enter this phase after receiving explicit human approval. This phase will make changes to running containers and data.

---

### Phase 4: Portainer Integration

**Goal**: Configure Portainer to deploy stacks from GitHub

**⚠️ WARNING**: This phase begins making changes. Ensure you have approval from Phase A stop point.

#### Task 8: Test Git Integration with Single Stack

**Setup Git-backed stack in Portainer**:

1. **In Portainer UI**:
   - Stacks → Add Stack → Git Repository
   - Repository URL: `https://github.com/<user>/<repo>`
   - Repository reference: `refs/heads/main` (or branch name)
   - Compose path: `apps/n8n-stack/docker-compose.yml` (relative to repo root)
   - Environment variables: Add from .env.example

2. **Test with existing stack**:
   - Choose a non-critical stack already in Git (e.g., `apps/n8n-stack`)
   - Deploy via Portainer Git integration
   - Verify it works identically to local `docker compose up`

3. **Enable Auto-sync** (optional):
   - Enables automatic stack updates when Git changes detected
   - Use cautiously for production services

#### Task 9: Document Portainer Deployment Process

**Create**: `docs/portainer/stack-deployment-guide.md`

```markdown
# Deploying Stacks via Portainer

## Prerequisites
- Portainer Server running on orangepi5b.local
- Docker hosts added as endpoints in Portainer
- GitHub repository accessible (public or credentials configured)

## Deployment Methods

### Method 1: Git Repository (Recommended)
1. Navigate to Stacks → Add Stack
2. Select "Git Repository"
3. Configure:
   - Name: `<stack-name>`
   - Repository URL: `https://github.com/<user>/<repo>`
   - Repository reference: `refs/heads/<branch>`
   - Compose path: `<category>/<stack-name>/docker-compose.yml`
   - Environment variables: Copy from .env.example
4. Select target endpoint (host)
5. Deploy

**Pros**: Auto-sync, version control, easy rollback
**Cons**: Secrets in Portainer UI (or use Git secret management)

### Method 2: Upload (For Custom Builds)
1. Navigate to Stacks → Add Stack
2. Select "Upload"
3. Upload docker-compose.yml
4. Configure environment variables
5. Select target endpoint
6. Deploy

**Pros**: Works with local builds (like homepage)
**Cons**: Manual sync, no automatic updates

### Method 3: Web Editor (Development Only)
1. Navigate to Stacks → Add Stack
2. Select "Web editor"
3. Paste docker-compose.yml content
4. Configure environment variables
5. Deploy

**Pros**: Quick testing
**Cons**: Not backed by Git, not reproducible

## Environment Variable Management

### Sensitive Values
Store in Portainer UI:
- Database passwords
- API keys
- Tokens

### Non-Sensitive Values
Can use in compose file directly or .env

## Multi-Host Deployment

### Host Mapping (from CLAUDE.md)
- **orangepi5b.local**: Portainer, Zigbee, IoT services
- **wonko.local**: Apps, Data services, Development

### Deploy Stack to Specific Host
1. When creating stack, select target endpoint
2. Or use Portainer agent for remote hosts
3. Stack name should include host for clarity: `<host>-<stack-name>`

## Stack Updates

### Via Git (Auto-sync Enabled)
- Push changes to GitHub
- Portainer auto-detects and updates (if configured)
- Or manually click "Update stack" in Portainer UI

### Via Git (Manual)
1. Push changes to GitHub
2. Open stack in Portainer
3. Click "Pull and redeploy"

### Via Web Editor
1. Open stack in Portainer
2. Click "Editor"
3. Make changes
4. Click "Update the stack"

## Troubleshooting

### Stack Fails to Deploy
- Check logs in Portainer UI
- Verify environment variables are set
- Check network/volume names don't conflict
- Ensure endpoint is reachable

### Can't Pull from Git
- Verify repository URL and branch
- Check Portainer has network access
- For private repos, configure Git credentials in Portainer

### Data Not Persisting
- Check volume definitions in compose file
- Verify volumes exist: `docker volume ls`
- Check volume mappings: `docker inspect <container>`
```

### Phase 5: Migration Execution

**Goal**: Migrate each service with minimal downtime and zero data loss

**⚠️ CRITICAL SAFETY RULE**: Before migrating ANY service:
1. Execute backup for that specific service
2. Verify backup file exists and has reasonable size
3. Only then proceed with migration
4. Keep backup for at least 30 days post-migration

#### Task 10: Execute Test Migration

**⚠️ MANDATORY FIRST STEP**: You MUST test on a non-critical service first.

**Choose a non-critical, simple service** (e.g., a standalone dashboard or dev tool):

1. **STOP**: Ask user which service to use for test migration
2. **Backup first**: Execute backup procedure for chosen service
3. **Verify backup**: Confirm backup file exists and has data
4. **Proceed**: Follow per-service migration plan from Phase 3
5. **Validate**: Verify migrated service works correctly
6. **Test rollback**: Actually execute rollback procedure to verify it works
7. **Re-migrate**: Migrate again after successful rollback test
8. **Document learnings**: Update migration template based on findings
9. **Get approval**: Before migrating any other services, get user approval

**Only after successful test migration should you proceed with other services.**

#### Task 11: Migrate Remaining Services

**⚠️ BEFORE STARTING**: Get user approval to proceed with production services.

**Migration order (follow strictly)**:
1. **Low-risk, low-complexity**: Stateless services, test/dev tools
2. **Medium-risk, medium-complexity**: Services with named volumes, moderate use
3. **High-risk, high-complexity**: Production databases, hardware-dependent services

**For EACH service (no exceptions)**:
- [ ] **Confirm with user**: "Ready to migrate <service-name>?"
- [ ] Review migration plan
- [ ] Schedule maintenance window (if production)
- [ ] **BACKUP FIRST** (mandatory, no skipping)
- [ ] **VERIFY BACKUP** (check file exists and size is reasonable)
- [ ] Ask user: "Backup verified, proceed with migration?"
- [ ] Perform migration
- [ ] Validate
- [ ] Keep container stopped but NOT removed (for 24h as safety buffer)
- [ ] Document completion
- [ ] Wait for user acknowledgment before next service

**Parallel migration**:
- ⚠️ Only migrate independent services in parallel
- Never migrate critical services in parallel
- Dependent services must be migrated together (e.g., app + database)
- Get user approval before parallel migration approach

#### Task 12: Update Documentation

**Update**: `CLAUDE.md` and `ReadMe.md`

Add sections:
- Complete stack list with host mapping
- Data volume locations and backup procedures
- Portainer deployment instructions
- Emergency recovery procedures

## Validation Loop

### Level 1: Pre-Migration Validation
```bash
# Run BEFORE starting any migration

# 1. Verify all containers inventoried
echo "=== Container Inventory Validation ==="
for host in orangepi5b.local wonko.local; do
  echo "Host: $host"
  ssh $host "docker ps --format '{{.Names}}' | wc -l"
done

# Compare with inventory file
echo "Expected containers per inventory: <N>"

# 2. Verify backup directory exists and has space
echo "=== Backup Storage Validation ==="
mkdir -p backups
df -h backups/  # Check available space

# 3. Verify Git repository is clean
echo "=== Git Status ==="
git status
# Should show no uncommitted changes to compose files

# 4. Verify Portainer is accessible
echo "=== Portainer Health ==="
curl -k https://orangepi5b.local:9443/api/status
```

**Expected**: All containers accounted for, sufficient backup space, clean Git state, Portainer accessible

### Level 2: Per-Service Migration Validation
```bash
# Run DURING each service migration (see Task 7 for detailed steps)

# 1. Verify backup created
test -f backups/<service>-data-$(date +%Y%m%d).tar.gz && echo "✅ Backup exists" || echo "❌ Backup missing"

# 2. Verify old container stopped (not removed yet)
docker ps -a | grep <container-name> | grep -q "Exited" && echo "✅ Container stopped" || echo "❌ Container still running"

# 3. Verify new stack deployed
docker compose ps | grep -q "Up" && echo "✅ Stack running" || echo "❌ Stack not running"

# 4. Verify data accessible
docker compose exec <service> ls /container/path | grep -q "expected-file" && echo "✅ Data present" || echo "❌ Data missing"

# 5. Verify service functional (example for web service)
curl -f http://localhost:<port>/health && echo "✅ Service healthy" || echo "❌ Service unhealthy"

# 6. Verify logs have no errors
docker compose logs --tail 50 <service> | grep -i error && echo "⚠️  Errors in logs" || echo "✅ No errors"
```

**Expected**: All checks pass before considering migration successful

### Level 3: Post-Migration Validation
```bash
# Run AFTER all migrations complete

# 1. Verify all services running
echo "=== All Services Status ==="
for host in orangepi5b.local wonko.local; do
  echo "Host: $host"
  ssh $host "docker ps --format 'table {{.Names}}\t{{.Status}}'"
done

# 2. Verify all stacks in Git
echo "=== Git-Backed Stacks ==="
find apps data infra iot -name "docker-compose.yml" -o -name "docker-compose.yaml"

# 3. Verify all .env.example files exist
echo "=== Environment Templates ==="
for compose in $(find . -name "docker-compose.y*ml"); do
  dir=$(dirname $compose)
  if [ ! -f "$dir/.env.example" ]; then
    echo "⚠️  Missing .env.example in $dir"
  fi
done

# 4. Verify Portainer stack list matches Git
echo "=== Portainer Stacks ==="
# List stacks via Portainer API (requires API key)
curl -k -H "X-API-Key: $PORTAINER_API_KEY" \
  https://orangepi5b.local:9443/api/stacks \
  | jq -r '.[] | "\(.Name)\t\(.GitConfig.URL)"'

# 5. Test cross-stack communication (if applicable)
echo "=== Network Connectivity ==="
# Example: Test MCP can reach Elasticsearch
docker exec mcp-server curl -f http://elasticsearch:9200/_cluster/health
```

**Expected**: All services running, all stacks in Git, no missing .env.example, Portainer lists match Git

### Level 4: Disaster Recovery Drill
```bash
# Run AFTER migration complete to validate recovery procedures

echo "=== Disaster Recovery Simulation ==="

# 1. Choose a test service (non-production)
# 2. Stop and remove the stack
cd <category>/<test-stack>
docker compose down -v  # WARNING: Removes volumes

# 3. Restore from backup
docker run --rm \
  -v <volume-name>:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar xzf /backup/<test-service>-*.tar.gz -C /data

# 4. Redeploy from Git
docker compose up -d

# 5. Verify service works
# Test functionality

# 6. Document recovery time
echo "Recovery completed in <X> minutes"
```

**Expected**: Service restored to working state from backup

## Final Validation Checklist

Run through this checklist to confirm migration success:

- [ ] **Inventory Complete**: All containers documented in `docs/inventory/`
- [ ] **Stacks Created**: All services have docker-compose.yml in appropriate category
- [ ] **Env Templates**: All stacks have .env.example files
- [ ] **Data Preserved**: All persistent data verified present and correct
- [ ] **Services Running**: All services accessible and functional
- [ ] **Git Clean**: All compose files committed to Git
- [ ] **Portainer Configured**: All stacks deployable from Portainer UI
- [ ] **Documentation Updated**: CLAUDE.md, ReadMe.md, and migration docs complete
- [ ] **Backups Tested**: At least one restore tested successfully
- [ ] **Rollback Documented**: Clear rollback procedures for each service
- [ ] **Host Mapping Clear**: Documentation shows which stack runs on which host
- [ ] **No Manual Containers**: Zero containers started via docker run (all via compose)

## Success Metrics

Track these metrics to measure migration success:

1. **Coverage**: `<N>/<Total>` containers migrated
2. **Downtime**: Average downtime per service: `<X>` minutes
3. **Data Loss**: Zero data loss events (target: 0)
4. **Rollbacks**: Number of rollbacks required: `<N>`
5. **Time to Deploy**: Time to deploy new service from Git: `<X>` minutes
6. **Documentation**: 100% of stacks have migration docs

## Anti-Patterns to Avoid

- ❌ **CRITICAL: Don't skip Phase A approval**: NEVER proceed to Phase B without human approval
- ❌ **CRITICAL: Don't migrate without backup**: ALWAYS backup AND verify before touching ANY service
- ❌ **CRITICAL: Don't auto-proceed through migrations**: Get user confirmation between each service
- ❌ **Don't skip .env.example**: Future you will forget what variables are needed
- ❌ **Don't use latest tags**: Pin specific versions for reproducibility
- ❌ **Don't ignore bind mount permissions**: Check ownership after migration
- ❌ **Don't force remove volumes**: Use `docker compose down` without `-v` first, keep stopped containers for 24h
- ❌ **Don't hardcode secrets**: Use .env or Portainer environment variables
- ❌ **Don't skip validation**: Run all validation checks, even if "it looks fine"
- ❌ **Don't delete backups**: Keep backups for at least 30 days post-migration
- ❌ **Don't migrate critical services first**: Start with low-risk services, test migration FIRST
- ❌ **Don't assume data location**: Always verify with `docker inspect`
- ❌ **Don't migrate in bulk**: One service at a time, validate each before proceeding

## Timeline Estimate

This is a **process-focused plan**, not a time-based plan. Duration depends on:
- Number of containers to migrate
- Complexity of each service
- Data volume sizes
- Validation thoroughness

**Typical service migration times**:
- Simple (stateless): 15-30 minutes
- Moderate (with volumes): 30-60 minutes
- Complex (hardware, custom builds): 1-3 hours

**Suggested approach**: Migrate 2-3 services per session, validate thoroughly between each.

---

## AI Agent Execution Summary

**When executing this PRP, you must follow this exact sequence:**

1. **START**: Phase A - Planning
   - Run inventory commands (read-only)
   - Create all docker-compose.yml files
   - Create all .env.example files
   - Document migration plans
   - Document backup procedures

2. **STOP**: Present Phase A deliverables to user
   - Show inventory summary
   - List all files created
   - Highlight critical services
   - **ASK**: "Phase A complete. Please review plans and backups. Reply 'APPROVED TO PROCEED WITH PHASE B' when ready."

3. **WAIT**: Do not proceed until user types approval phrase

4. **RESUME**: Phase B - Execution (only after approval)
   - Configure Portainer Git integration (Task 8)
   - Execute test migration on ONE non-critical service (Task 10)
   - **STOP**: Get user approval after test migration
   - Migrate remaining services ONE AT A TIME (Task 11)
   - For each service:
     - Backup → Verify backup → Ask user approval → Migrate → Validate → Wait for acknowledgment

5. **FINISH**: Final validation and documentation

**Remember**: Safety over speed. Every backup matters. Every validation matters. Human approval is mandatory at checkpoints.

---

## PRP Quality Score: 9.5/10

**Confidence Level**: HIGH - Safe two-phase implementation with human oversight

**Strengths**:
✅ Comprehensive context with real examples from codebase
✅ Detailed step-by-step procedures with actual commands
✅ Multiple validation checkpoints with executable tests
✅ Real-world patterns from existing stacks to follow
✅ Explicit rollback procedures for each phase
✅ Data safety prioritized throughout
✅ Anti-patterns clearly documented
✅ **Mandatory human approval checkpoints prevent unsafe automation**
✅ **Two-phase approach: plan first, execute only after verification**
✅ **Backup verification required before every migration**

**Safety Features**:
🛑 Mandatory stop point after planning phase
🛑 Human approval required before execution phase
🛑 Backup verification before each service migration
🛑 Test migration required before production migrations
🛑 User confirmation between each production service
🛑 Rollback procedures tested and documented

**Why 9.5/10**: This PRP provides exceptional context, actionable steps, AND safety guardrails. The two-phase approach with mandatory human approval ensures that no automated agent can accidentally destroy data. An AI agent will plan thoroughly, then wait for human verification before touching any production services. The explicit backup and approval gates make this migration process safe even for critical infrastructure.
