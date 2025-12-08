# Accessing Home Lab Services via Tailscale

## Overview

Tailscale provides secure remote access to all home lab services using subnet routing.

- **Subnet Router**: orangepi5b.local advertises home LAN (192.168.1.0/24)
- **Client Node**: wonko.local accepts routes from orangepi5b
- **MagicDNS**: Hostnames `orangepi5b` and `wonko` resolve automatically
- **Zero-Trust**: No open ports on your router, encrypted WireGuard VPN connections

## Architecture

```
Remote Device (laptop/phone)
    ↓ (Tailscale VPN)
orangepi5b.local (subnet router)
    ↓ (advertises 192.168.1.0/24)
Home LAN
    ↓
Services on wonko.local (192.168.1.100)
Services on orangepi5b.local (192.168.1.101)
```

## Prerequisites

**On your remote device:**
- Tailscale installed on your device (laptop, phone, etc.)
- Connected to your tailnet (same account as homelab nodes)
- Download from: https://tailscale.com/download

**On orangepi5b and wonko:**
- Tailscale containers deployed and running
- Routes approved in admin console (orangepi5b subnet router)

## Access Patterns

### Via LAN IPs (Recommended)

Access services using their regular LAN IPs through subnet routing:

**wonko.local services:**
- Kibana: http://192.168.1.100:5601
- n8n: http://192.168.1.100:5678
- Prefect UI: http://192.168.1.100:4200
- Neo4j Browser: http://192.168.1.100:7475
- NeoDash: http://192.168.1.100:5005
- Elasticsearch: http://192.168.1.100:9200
- MCP Server: http://192.168.1.100:8000

**orangepi5b.local services:**
- Portainer: https://192.168.1.101:9443
- Traefik Dashboard: http://192.168.1.101:9080/dashboard/
- Zigbee2MQTT: http://192.168.1.101:8081

### Via Tailscale IPs

Access services using Tailscale-assigned IPs (find in admin console):
- orangepi5b: http://100.x.x.x:9443 (Portainer)
- wonko: http://100.y.y.y:5601 (Kibana)

### Via MagicDNS Hostnames

If MagicDNS is enabled (default):
- orangepi5b: http://orangepi5b:9443
- wonko: http://wonko:5601

### Via Traefik (Recommended for HTTP Services)

Access services through Traefik reverse proxy on orangepi5b:
- Traefik routes to services on both hosts via LAN IPs
- No configuration changes needed due to subnet routing
- Use configured Traefik routes with Host headers

## Common Tasks

### Check Tailscale Status

From your remote device:
```bash
tailscale status
```

You should see both `orangepi5b` and `wonko` in the peer list with their Tailscale IPs.

### Test Connectivity

Ping the Tailscale nodes:
```bash
ping orangepi5b
ping wonko
```

Test LAN access through subnet router:
```bash
ping 192.168.1.100  # wonko LAN IP
ping 192.168.1.101  # orangepi5b LAN IP
```

### View Available Routes

From your remote device:
```bash
ip route show table 52
```

### Enable Exit Node (Route Internet Through Home)

Route your internet traffic through your home network:
```bash
tailscale set --exit-node=orangepi5b
```

Verify your IP shows your home public IP:
```bash
curl ifconfig.me
```

### Disable Exit Node

Return to normal internet routing:
```bash
tailscale set --exit-node=
```

## Service-Specific Access

### Kibana (Elasticsearch UI)

```bash
# Via LAN IP through subnet router
curl http://192.168.1.100:5601

# Via Tailscale IP
curl http://100.y.y.y:5601

# Via MagicDNS
curl http://wonko:5601
```

### n8n Workflow Automation

```bash
# Via LAN IP
http://192.168.1.100:5678

# Via Traefik (if configured)
http://192.168.1.101/ (with Host: n8n.local header)
```

### Portainer Container Management

```bash
# Via LAN IP through subnet router
https://192.168.1.101:9443

# Via Tailscale IP
https://100.x.x.x:9443

# Via MagicDNS
https://orangepi5b:9443
```

### Traefik Dashboard

```bash
# Via LAN IP
http://192.168.1.101:9080/dashboard/

# Via Tailscale IP
http://100.x.x.x:9080/dashboard/
```

## Security Considerations

### What Tailscale Protects

- All traffic encrypted with WireGuard
- Zero-trust network access (authenticate before connect)
- No open ports on your home router
- Peer-to-peer connections when possible (no relay)
- MagicDNS for easy hostname resolution

### What You Still Need to Protect

- Services themselves should still use authentication
- HTTPS/TLS for sensitive services (use Traefik for this)
- Keep Tailscale auth keys secure (never commit to git)
- Use Tailscale ACLs to restrict access between nodes if needed

### Recommended ACL Policy

In the Tailscale admin console (https://login.tailscale.com/admin/acls), you can configure access control:

```json
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
```

## Troubleshooting

### Can't Access LAN IPs

**Symptoms:** Tailscale IPs work, but LAN IPs (192.168.1.x) don't respond

**Solutions:**
1. Check routes are approved in admin console:
   - Go to https://login.tailscale.com/admin/machines
   - Click on orangepi5b
   - Verify subnet route is approved (not pending)

2. Verify orangepi5b subnet router is online:
   ```bash
   tailscale status | grep orangepi5b
   ```

3. Check IP forwarding on orangepi5b host:
   ```bash
   ssh orangepi5b
   sysctl net.ipv4.ip_forward
   # Should return: net.ipv4.ip_forward = 1
   ```

### MagicDNS Not Resolving

**Symptoms:** `ping orangepi5b` fails with "unknown host"

**Solutions:**
1. Verify MagicDNS is enabled:
   - Go to https://login.tailscale.com/admin/dns
   - Ensure "MagicDNS" is enabled

2. Check your resolv.conf has Tailscale nameserver:
   ```bash
   cat /etc/resolv.conf | grep 100.100.100.100
   ```

3. Try the full FQDN:
   ```bash
   ping orangepi5b.tail-xxxx.ts.net
   ```

### Service Not Responding

**Symptoms:** Can ping host but service doesn't respond

**Solutions:**
1. Verify service is running on host:
   ```bash
   ssh wonko
   docker ps | grep kibana
   ```

2. Test from LAN first to isolate issue:
   ```bash
   # From another device on your home network
   curl http://192.168.1.100:5601
   ```

3. Check firewall rules on host:
   ```bash
   sudo iptables -L -n
   ```

### Tailscale Container Won't Start

**Symptoms:** Container exits immediately or fails to start

**Solutions:**
1. Check logs:
   ```bash
   docker compose -f docker-compose.wonko.yml logs
   ```

2. Verify auth key is valid:
   - Check TS_AUTHKEY in .env file
   - Generate new key at https://login.tailscale.com/admin/settings/keys

3. Verify /dev/net/tun exists:
   ```bash
   ls -la /dev/net/tun
   ```

4. Check NET_ADMIN capability:
   ```bash
   docker compose -f docker-compose.wonko.yml config
   # Verify cap_add section includes NET_ADMIN
   ```

### Slow Performance

**Symptoms:** Services are slow to respond via Tailscale

**Solutions:**
1. Check if using direct connection (not relay):
   ```bash
   tailscale status
   # Look for "direct" vs "relay" in connection status
   ```

2. Enable direct connections by checking NAT traversal:
   - Tailscale uses STUN/DERP for NAT traversal
   - Most connections should be direct peer-to-peer

3. Consider using exit node only when needed:
   - Exit node routes all traffic through home
   - Disable when not needed for better performance

## Maintenance

### Updating Tailscale

Pull the latest stable image:
```bash
docker compose -f docker-compose.wonko.yml pull
docker compose -f docker-compose.wonko.yml up -d
```

State is preserved in `./state` directory, so updates are seamless.

### Rotating Auth Keys

If an auth key expires or is compromised:
1. Generate new auth key in admin console
2. Update .env file with new key
3. Restart container:
   ```bash
   docker compose -f docker-compose.wonko.yml restart
   ```

### Checking State Persistence

Verify state directory exists and has content:
```bash
ls -la infra/tailscale/state/
```

State directory should contain:
- `tailscaled.state` - Node identity and configuration

### Monitoring Tailscale Status

Set up monitoring to alert if Tailscale goes offline:
```bash
# Add to cron or monitoring system
tailscale status --json | jq -r '.BackendState'
# Should return: "Running"
```

## Best Practices

1. **Always-On Subnet Router**: Keep orangepi5b running 24/7 for continuous remote access
2. **Backup State**: Back up `infra/tailscale/state/` directory to preserve node identity
3. **Use Reusable Keys**: Generate reusable, non-ephemeral auth keys for persistent nodes
4. **Monitor Routes**: Regularly check that subnet routes are active in admin console
5. **Test Regularly**: Periodically test remote access to ensure everything works
6. **Document IPs**: Keep a record of Tailscale IPs for each node
7. **Use Traefik**: Route HTTP services through Traefik for SSL/TLS and better management
8. **Enable MagicDNS**: Use hostnames instead of IPs for easier access
9. **Configure ACLs**: Set up access control policies for defense in depth
10. **Keep Updated**: Regularly update Tailscale containers to latest stable

## Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Subnet Router Setup](https://tailscale.com/kb/1019/subnets)
- [Exit Nodes](https://tailscale.com/kb/1103/exit-nodes)
- [MagicDNS](https://tailscale.com/kb/1081/magicdns)
- [ACL Policy](https://tailscale.com/kb/1018/acls)
- [Docker Integration](https://tailscale.com/kb/1282/docker)

## Quick Reference Card

| Task | Command |
|------|---------|
| Check status | `tailscale status` |
| Get Tailscale IP | `tailscale ip -4` |
| Ping node | `ping orangepi5b` |
| Enable exit node | `tailscale set --exit-node=orangepi5b` |
| Disable exit node | `tailscale set --exit-node=` |
| View routes | `ip route show table 52` |
| Admin console | https://login.tailscale.com/admin |
| Generate auth key | https://login.tailscale.com/admin/settings/keys |

---

For deployment instructions, see:
- `infra/tailscale/README.orangepi5b.md` - Subnet router setup
- `infra/tailscale/README.wonko.md` - Client node setup
