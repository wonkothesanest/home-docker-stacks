# Tailscale Deployment Guide

Complete step-by-step guide for deploying Tailscale on both orangepi5b and wonko hosts.

## Overview

This deployment creates a Tailscale mesh network with:
- **orangepi5b.local**: Subnet router advertising home LAN (192.168.1.0/24)
- **wonko.local**: Client node accepting routes from orangepi5b

## Prerequisites

- Docker and Docker Compose installed on both hosts
- Tailscale account (free tier is sufficient)
- Access to both hosts (SSH or direct)
- Administrator access to Tailscale admin console

## Deployment Steps

### Phase 1: Generate Tailscale Auth Keys

1. **Login to Tailscale Admin Console**
   ```
   https://login.tailscale.com/admin/settings/keys
   ```

2. **Generate Auth Key for orangepi5b**
   - Click "Generate auth key"
   - Description: `orangepi5b.local homelab subnet router`
   - **Enable** "Reusable" (allows reconnection without new key)
   - **Disable** "Ephemeral" (persist node across restarts)
   - Optional: Set expiration (90 days, 1 year, or never)
   - Optional: Add tags: `tag:homelab`, `tag:gateway`
   - Click "Generate key"
   - **COPY THE KEY**: `tskey-auth-xxxxx-xxxxxxxxxxxxxx`
   - Save this securely - you won't see it again

3. **Generate Auth Key for wonko**
   - Click "Generate auth key" again
   - Description: `wonko.local homelab client`
   - **Enable** "Reusable"
   - **Disable** "Ephemeral"
   - Optional: Add tags: `tag:homelab`, `tag:workstation`
   - Click "Generate key"
   - **COPY THE KEY**: `tskey-auth-yyyyy-yyyyyyyyyyyyyy`
   - Save this securely

**IMPORTANT**: Keep these keys secret! Never commit them to git.

### Phase 2: Deploy on orangepi5b (Subnet Router)

1. **SSH into orangepi5b**
   ```bash
   ssh orangepi5b.local
   ```

2. **Navigate to Tailscale directory**
   ```bash
   cd /path/to/home-docker-stacks/infra/tailscale
   ```

3. **Enable IP Forwarding on Host**

   This is CRITICAL for subnet routing to work:
   ```bash
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
   ```

4. **Verify IP Forwarding**
   ```bash
   sysctl net.ipv4.ip_forward
   ```
   Expected output: `net.ipv4.ip_forward = 1`

5. **Create .env File**
   ```bash
   cp .env.orangepi5b.example .env
   nano .env
   ```

6. **Edit .env File**

   Replace placeholders with your values:
   ```bash
   # Use the auth key you generated for orangepi5b
   TS_AUTHKEY=tskey-auth-xxxxx-xxxxxxxxxxxxxx

   # Your home LAN subnet (adjust if different)
   # Common: 192.168.1.0/24, 192.168.0.0/24, 10.0.0.0/24
   LAN_SUBNET=192.168.1.0/24
   ```

   Save and exit (Ctrl+O, Enter, Ctrl+X in nano)

7. **Deploy Tailscale Container**
   ```bash
   docker compose -f docker-compose.orangepi5b.yml up -d
   ```

8. **Check Container Status**
   ```bash
   docker compose -f docker-compose.orangepi5b.yml ps
   ```
   Expected: Container status "Up"

9. **View Logs**
   ```bash
   docker compose -f docker-compose.orangepi5b.yml logs -f
   ```

   Look for:
   - "Logged in as..."
   - "Advertised routes: [192.168.1.0/24]"
   - No errors

   Press Ctrl+C to exit logs

10. **Verify Tailscale Status**
    ```bash
    docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale status
    ```

    Expected output:
    - Hostname: orangepi5b
    - Tailscale IP: 100.x.x.x (note this down)
    - Status: Connected

11. **Get Tailscale IP**
    ```bash
    docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale ip -4
    ```
    **SAVE THIS IP** - you'll need it for testing

### Phase 3: Approve Subnet Routes

1. **Login to Tailscale Admin Console**
   ```
   https://login.tailscale.com/admin/machines
   ```

2. **Find orangepi5b Machine**
   - Look for "orangepi5b" in the machine list
   - Status should be green "Connected"
   - Should have "Subnet" badge

3. **Approve Subnet Routes**
   - Click on the orangepi5b machine
   - Scroll to "Subnets" section
   - You should see: `192.168.1.0/24` with status "Pending approval"
   - Click "Approve" button next to the route
   - Route should now show as "Approved"

4. **Optional: Enable Exit Node**
   - In the same view, scroll to "Exit node" section
   - You should see "Advertised as exit node"
   - Toggle to enable if you want to route internet through home
   - This allows routing all internet traffic through your home network when traveling

5. **Verify Route Approval**

   Back on orangepi5b terminal:
   ```bash
   docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale status
   ```

   Route should now show as approved/accepted

### Phase 4: Deploy on wonko (Client Node)

1. **SSH into wonko** (or if already on wonko, open terminal)
   ```bash
   ssh wonko.local
   ```

2. **Navigate to Tailscale directory**
   ```bash
   cd /path/to/home-docker-stacks/infra/tailscale
   ```

3. **Create .env File**
   ```bash
   cp .env.wonko.example .env
   nano .env
   ```

4. **Edit .env File**

   Replace placeholder with wonko's auth key:
   ```bash
   # Use the auth key you generated for wonko (different from orangepi5b!)
   TS_AUTHKEY=tskey-auth-yyyyy-yyyyyyyyyyyyyy
   ```

   Save and exit

5. **Deploy Tailscale Container**
   ```bash
   docker compose -f docker-compose.wonko.yml up -d
   ```

6. **Check Container Status**
   ```bash
   docker compose -f docker-compose.wonko.yml ps
   ```
   Expected: Container status "Up"

7. **View Logs**
   ```bash
   docker compose -f docker-compose.wonko.yml logs -f
   ```

   Look for:
   - "Logged in as..."
   - "Running"
   - No errors

   Press Ctrl+C to exit

8. **Verify Tailscale Status**
   ```bash
   docker compose -f docker-compose.wonko.yml exec tailscale tailscale status
   ```

   Expected:
   - Hostname: wonko
   - Tailscale IP: 100.y.y.y (note this down)
   - Should see orangepi5b as a peer
   - Should show received routes from orangepi5b

9. **Get Tailscale IP**
   ```bash
   docker compose -f docker-compose.wonko.yml exec tailscale tailscale ip -4
   ```
   **SAVE THIS IP**

10. **Test Connectivity to orangepi5b**
    ```bash
    docker compose -f docker-compose.wonko.yml exec tailscale ping orangepi5b
    ```
    Expected: Successful ping responses

### Phase 5: Verification (From Both Hosts)

1. **Verify Admin Console**
   - Go to https://login.tailscale.com/admin/machines
   - Both "orangepi5b" and "wonko" should be listed
   - Both should show green "Connected" status
   - orangepi5b should have "Subnet" badge
   - Click each machine to verify:
     - Tailscale IPs are assigned
     - orangepi5b shows approved subnet route
     - Last seen is recent

2. **Verify State Persistence**

   On each host, check state directory:
   ```bash
   ls -la infra/tailscale/state/
   ```

   Should contain files like `tailscaled.state`

### Phase 6: Test Remote Access

1. **Install Tailscale on Remote Device**

   On your laptop, phone, or remote device:
   - Download from: https://tailscale.com/download
   - Install and login with same Tailscale account
   - Wait for connection

2. **Check Tailscale Status on Remote Device**
   ```bash
   tailscale status
   ```

   Expected:
   - Should see both "orangepi5b" and "wonko" in peer list
   - Both should show as online

3. **Test Tailscale IP Connectivity**
   ```bash
   ping 100.x.x.x  # orangepi5b's Tailscale IP
   ping 100.y.y.y  # wonko's Tailscale IP
   ```
   Both should respond

4. **Test MagicDNS**
   ```bash
   ping orangepi5b
   ping wonko
   ```
   Both should resolve and respond

5. **Test Subnet Routing (The Real Test!)**
   ```bash
   # Test orangepi5b LAN IP
   ping 192.168.1.101

   # Test wonko LAN IP
   ping 192.168.1.100
   ```

   Both should respond through the subnet router!

6. **Test Service Access**

   Try accessing services via LAN IPs:
   ```bash
   # Portainer on orangepi5b
   curl -Ik https://192.168.1.101:9443

   # Kibana on wonko
   curl -I http://192.168.1.100:5601
   ```

   Both should respond!

7. **Test Traefik Access**
   ```bash
   # Traefik dashboard
   curl -I http://192.168.1.101:9080/dashboard/
   ```

   Should return HTTP 200 OK or redirect

8. **Optional: Test Exit Node**

   On remote device:
   ```bash
   # Check current public IP
   curl ifconfig.me
   # Note the IP

   # Enable exit node
   tailscale set --exit-node=orangepi5b

   # Check public IP again
   curl ifconfig.me
   # Should now show your home public IP!

   # Disable exit node
   tailscale set --exit-node=
   ```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker compose -f docker-compose.orangepi5b.yml logs
```

**Common issues:**
- Invalid auth key: Generate new key in admin console
- Missing /dev/net/tun: Check device exists: `ls -la /dev/net/tun`
- Permission denied: Check NET_ADMIN capability in docker-compose.yml

### Can't Access LAN IPs

**Verify routes approved:**
- Check admin console
- Routes must be approved, not just advertised

**Check IP forwarding on orangepi5b:**
```bash
sysctl net.ipv4.ip_forward
```
Should return 1

**Verify orangepi5b is online:**
```bash
tailscale status | grep orangepi5b
```

### MagicDNS Not Working

**Check MagicDNS enabled:**
- Go to https://login.tailscale.com/admin/dns
- Verify "MagicDNS" is enabled

**Try full FQDN:**
```bash
ping orangepi5b.tail-xxxx.ts.net
```

### Services Not Responding

**Test from LAN first:**
```bash
# From another device on home network
curl http://192.168.1.100:5601
```

If works on LAN but not via Tailscale, problem is with Tailscale routing.
If doesn't work on LAN, problem is with the service itself.

## Post-Deployment Tasks

### 1. Configure ACL Policy (Optional but Recommended)

Go to https://login.tailscale.com/admin/acls

Add ACL policy:
```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:homelab"],
      "dst": ["tag:homelab:*"]
    },
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

This enables:
- Auto-approval of subnet routes from tagged nodes
- Access control between nodes

### 2. Document Your Setup

Create a note with:
- Tailscale IPs for each host
- LAN IPs for services
- Auth key expiration dates
- Any special configuration

### 3. Set Up Monitoring (Optional)

Add to your monitoring system:
```bash
# Check Tailscale status
docker compose -f docker-compose.wonko.yml exec tailscale tailscale status
```

### 4. Commit Changes to Git

```bash
git add infra/tailscale/docker-compose.*.yml
git add infra/tailscale/.env.*.example
git add infra/tailscale/README.*.md
git add docs/tailscale-access.md
git add CLAUDE.md
git add .gitignore
git commit -m "Add Tailscale subnet router configuration

- orangepi5b: Subnet router advertising home LAN
- wonko: Client node accepting routes
- Comprehensive documentation for remote access"
```

**DO NOT commit:**
- `.env` files (contain auth keys)
- `state/` directory (contains node identity)

These are already in .gitignore.

## Success Checklist

- [ ] Auth keys generated for both hosts
- [ ] IP forwarding enabled on orangepi5b host
- [ ] Tailscale containers running on both hosts
- [ ] Both nodes show "Connected" in admin console
- [ ] Subnet routes approved for orangepi5b
- [ ] Can ping Tailscale IPs from remote device
- [ ] Can ping LAN IPs from remote device
- [ ] MagicDNS resolves hostnames
- [ ] Services accessible via LAN IPs from remote
- [ ] Traefik dashboard accessible remotely
- [ ] State directories exist and contain data
- [ ] .env files not committed to git
- [ ] Documentation reviewed and understood
- [ ] Exit node tested (optional)

## Next Steps

After successful deployment:

1. **Read the access guide**: `docs/tailscale-access.md`
2. **Test all your services**: Verify each service works remotely
3. **Configure Traefik routes**: If using Traefik for routing
4. **Set up monitoring**: Monitor Tailscale connectivity
5. **Share access**: Add other devices to your tailnet

## Support Resources

- Tailscale Documentation: https://tailscale.com/kb/
- Admin Console: https://login.tailscale.com/admin
- Community Forum: https://forum.tailscale.com/
- GitHub Issues: https://github.com/tailscale/tailscale/issues

For issues specific to this deployment:
- Check `docs/tailscale-access.md` troubleshooting section
- Review host-specific READMEs in `infra/tailscale/`
- Verify Docker and networking basics

---

**Deployment Complete!** You now have secure remote access to your entire home lab via Tailscale.
