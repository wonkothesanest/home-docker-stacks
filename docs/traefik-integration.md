# Adding Services to Traefik Reverse Proxy

This guide explains how to add services to the Traefik reverse proxy running on orangepi5b.local.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Adding wonko.local Services (File Provider)](#adding-wonkolocal-services-file-provider)
3. [Adding orangepi5b Services (Docker Provider)](#adding-orangepi5b-services-docker-provider)
4. [Common Troubleshooting](#common-troubleshooting)

## Architecture Overview

Traefik runs on **orangepi5b.local** as the edge/gateway node and uses two providers:

### Docker Provider (Local Services)
- **Purpose**: Auto-discovers containers running on orangepi5b.local
- **Examples**: Portainer, Zigbee2MQTT, Mosquitto
- **Configuration**: Add labels to docker-compose.yml
- **Network**: Containers must connect to `traefik-network`

### File Provider (Remote Services)
- **Purpose**: Manual routing to services on wonko.local
- **Examples**: Elasticsearch, Kibana, n8n, Prefect, Neo4j
- **Configuration**: Edit `infra/traefik/config/dynamic.yml`
- **Network**: No changes needed to wonko.local services
- **Hot-reload**: Changes to dynamic.yml are detected automatically

## Adding wonko.local Services (File Provider)

Services running on wonko.local are routed via the File Provider. No changes are needed to the service's docker-compose.yml.

### Step 1: Verify Service is Accessible

From orangepi5b.local, test connectivity:

```bash
curl -I http://wonko.local:PORT
```

If this fails, troubleshoot network connectivity before proceeding.

### Step 2: Edit dynamic.yml

Edit `infra/traefik/config/dynamic.yml` and add your service:

```yaml
http:
  routers:
    # Add your router
    myservice:
      rule: "Host(`myservice.home`)"
      entryPoints:
        - "web"
      service: "myservice"

  services:
    # Add your service backend
    myservice:
      loadBalancer:
        servers:
          - url: "http://wonko.local:PORT"
```

### Step 3: Verify Configuration

Traefik will automatically reload the configuration. Check the logs:

```bash
cd /path/to/infra/traefik
docker compose logs traefik | grep "Configuration loaded"
```

### Step 4: Test Access

Add DNS/hosts entry on your client machine:

```
<orangepi5b-IP> myservice.home
```

Test access:

```bash
curl http://myservice.home
```

### Examples of wonko.local Services

#### n8n (Workflow Automation)

```yaml
http:
  routers:
    n8n:
      rule: "Host(`n8n.home`)"
      entryPoints:
        - "web"
      service: "n8n"

  services:
    n8n:
      loadBalancer:
        servers:
          - url: "http://wonko.local:5678"
```

#### Prefect (Workflow Orchestration)

```yaml
http:
  routers:
    prefect:
      rule: "Host(`prefect.home`)"
      entryPoints:
        - "web"
      service: "prefect"

  services:
    prefect:
      loadBalancer:
        servers:
          - url: "http://wonko.local:4200"
```

#### Neo4j (Graph Database)

```yaml
http:
  routers:
    neo4j:
      rule: "Host(`neo4j.home`)"
      entryPoints:
        - "web"
      service: "neo4j"

  services:
    neo4j:
      loadBalancer:
        servers:
          - url: "http://wonko.local:7475"
```

#### Multiple Hostnames

You can route multiple hostnames to the same service:

```yaml
http:
  routers:
    elasticsearch:
      rule: "Host(`es.home`) || Host(`elasticsearch.home`)"
      entryPoints:
        - "web"
      service: "elasticsearch"

  services:
    elasticsearch:
      loadBalancer:
        servers:
          - url: "http://wonko.local:9200"
```

## Adding orangepi5b Services (Docker Provider)

Services running locally on orangepi5b.local can be auto-discovered by the Docker Provider.

### Prerequisites

Ensure the `traefik-network` exists:

```bash
docker network create traefik-network
```

### Step 1: Modify docker-compose.yml

Add the service to the `traefik-network` and add routing labels:

```yaml
services:
  myservice:
    image: myimage:latest
    container_name: myservice
    restart: unless-stopped

    # Add networks
    networks:
      - default           # Keep existing networks
      - traefik-network   # Add for Traefik routing

    # Add Traefik labels
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.home`)"
      - "traefik.http.routers.myservice.entrypoints=web"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"

# Define networks
networks:
  default:
  traefik-network:
    external: true
```

### Step 2: Restart the Service

```bash
cd /path/to/service
docker compose down
docker compose up -d
```

### Step 3: Verify in Dashboard

Visit http://orangepi5b.local:9080/dashboard/ and check:
- **HTTP → Routers**: Should show your router
- **HTTP → Services**: Should show your service

### Step 4: Test Access

Add DNS/hosts entry:

```
<orangepi5b-IP> myservice.home
```

Test:

```bash
curl http://myservice.home
```

### Example: Adding Portainer

```yaml
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
      - default
      - traefik-network

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
```

### Multi-Network Services

If a service connects to multiple networks (e.g., app + database), tell Traefik which network to use:

```yaml
services:
  webapp:
    image: webapp:latest
    networks:
      - app-network       # For database communication
      - traefik-network   # For Traefik routing

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`webapp.home`)"
      - "traefik.http.routers.webapp.entrypoints=web"
      - "traefik.http.services.webapp.loadbalancer.server.port=3000"
      - "traefik.docker.network=traefik-network"  # IMPORTANT: Specify network

  database:
    image: postgres:15
    networks:
      - app-network  # Only internal network, not exposed via Traefik

networks:
  app-network:
  traefik-network:
    external: true
```

## Advanced Routing

### Path-Based Routing

Route based on URL path instead of hostname:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`home`) && PathPrefix(`/api`)"
  - "traefik.http.routers.api.entrypoints=web"
  - "traefik.http.services.api.loadbalancer.server.port=8000"
```

### Strip Path Prefix

If the backend app doesn't expect the path prefix:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`home`) && PathPrefix(`/api`)"
  - "traefik.http.routers.api.entrypoints=web"
  - "traefik.http.services.api.loadbalancer.server.port=8000"
  - "traefik.http.middlewares.api-stripprefix.stripprefix.prefixes=/api"
  - "traefik.http.routers.api.middlewares=api-stripprefix"
```

### WebSocket Support

Traefik v3 handles WebSocket upgrades automatically. No special configuration needed:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.ws-app.rule=Host(`ws.home`)"
  - "traefik.http.routers.ws-app.entrypoints=web"
  - "traefik.http.services.ws-app.loadbalancer.server.port=8080"
```

## Common Troubleshooting

### 404 Not Found

**Symptom**: Accessing service returns 404 error

**Possible Causes**:
1. Router not configured correctly
2. Host rule doesn't match request
3. File provider config not loaded

**Solutions**:
- Check Traefik dashboard: HTTP → Routers (should show your router)
- Verify Host() rule matches your request hostname exactly
- For File provider: Check `docker compose logs traefik | grep "Configuration loaded"`
- Verify DNS/hosts entry matches the Host() rule

### 502 Bad Gateway

**Symptom**: Accessing service returns Bad Gateway error

**Possible Causes**:
1. Backend service is not running
2. Backend service is not accessible from Traefik
3. Wrong port or URL in service configuration

**Solutions**:
- For wonko.local services: Test from orangepi5b: `curl http://wonko.local:PORT`
- For local services: Check container is running: `docker compose ps`
- Verify service URL in configuration (dynamic.yml or labels)
- Check service port is correct

### 503 Service Unavailable

**Symptom**: Accessing service returns Service Unavailable

**Possible Causes**:
1. Service backend not defined
2. No healthy backends available

**Solutions**:
- Check Traefik dashboard: HTTP → Services (should show your service)
- Verify service definition matches router's service name
- Check backend server URL is correct

### Service Not Appearing in Dashboard

**Docker Provider:**
- Verify container is on `traefik-network`: `docker network inspect traefik-network`
- Check `traefik.enable=true` label is present
- Restart Traefik: `docker compose restart traefik`

**File Provider:**
- Check YAML syntax in dynamic.yml
- Check file provider logs: `docker compose logs traefik | grep file`
- Verify file mount: `docker compose exec traefik ls -la /etc/traefik/config/`

### Container Can't Connect to Traefik Network

**Symptom**: Error creating container: network not found

**Solution**:
```bash
docker network create traefik-network
```

The network must exist before starting containers that reference it.

### Traefik Dashboard Not Accessible

**Symptom**: Cannot access http://orangepi5b.local:9080/dashboard/

**Solutions**:
- Verify Traefik is running: `docker compose ps`
- Check port 9080 is not in use: `netstat -tulpn | grep 9080`
- Note the trailing slash: `/dashboard/` (required)
- Check Traefik logs: `docker compose logs traefik`

### Changes to dynamic.yml Not Applied

**Symptom**: Made changes to dynamic.yml but routes don't update

**Solutions**:
- Check watch is enabled in docker-compose.yml: `--providers.file.watch=true`
- Check file provider logs: `docker compose logs traefik | grep "Configuration loaded"`
- Verify file syntax is valid YAML
- Restart Traefik if hot-reload fails: `docker compose restart traefik`

## Checking Traefik Configuration

### View All Routers

```bash
curl http://orangepi5b.local:9080/api/http/routers | jq
```

### View Specific Router

```bash
curl http://orangepi5b.local:9080/api/http/routers | jq '.[] | select(.name=="kibana")'
```

### View All Services

```bash
curl http://orangepi5b.local:9080/api/http/services | jq
```

### View Providers

```bash
curl http://orangepi5b.local:9080/api/overview | jq '.providers'
```

Should show both `docker` and `file` providers.

## Best Practices

1. **Use descriptive names**: Router and service names should be clear and match the actual service
2. **Always specify ports explicitly**: Even if container exposes one port, be explicit
3. **Use environment variables**: Store domain in .env file, reference as ${DOMAIN}
4. **Keep original ports**: wonko.local services should keep their port mappings
5. **Test connectivity first**: Before configuring Traefik, verify backend is accessible
6. **Use trailing slash for dashboard**: http://orangepi5b.local:9080/dashboard/
7. **Check logs regularly**: Traefik logs show configuration errors clearly
8. **Use dashboard for debugging**: Visual inspection is faster than curl/API

## Security Notes

- Dashboard is in insecure mode (no auth) - suitable for development only
- For production, add BasicAuth or ForwardAuth middleware to sensitive services
- Docker socket is mounted read-only (`:ro`) for security
- Consider using Docker Socket Proxy for additional security
- HTTPS/TLS should be configured for production deployments

## Additional Resources

- [Traefik Docker Provider Documentation](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik File Provider Documentation](https://doc.traefik.io/traefik/providers/file/)
- [Traefik Routers Documentation](https://doc.traefik.io/traefik/routing/routers/)
- [Traefik Middleware Documentation](https://doc.traefik.io/traefik/middlewares/http/overview/)
- [infra/traefik/README.md](../infra/traefik/README.md) - Deployment instructions
