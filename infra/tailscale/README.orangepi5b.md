# Tailscale Subnet Router (orangepi5b)

This node acts as a subnet router, advertising the home LAN to the Tailscale network.

## Prerequisites

Before deploying, you must enable IP forwarding on the orangepi5b host:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Verify IP forwarding is enabled:
```bash
sysctl net.ipv4.ip_forward
# Expected output: net.ipv4.ip_forward = 1
```

## Setup

1. Copy .env.orangepi5b.example to .env
   ```bash
   cp .env.orangepi5b.example .env
   ```

2. Edit .env with your Tailscale auth key and LAN subnet
   ```bash
   nano .env
   ```

3. Deploy the stack
   ```bash
   docker compose -f docker-compose.orangepi5b.yml up -d
   ```

4. Check the logs
   ```bash
   docker compose -f docker-compose.orangepi5b.yml logs -f
   ```

5. Approve routes in Tailscale admin console
   - Go to: https://login.tailscale.com/admin/machines
   - Find orangepi5b
   - Approve the advertised subnet route (192.168.1.0/24)
   - Optionally enable as exit node

## Common Commands

### Check status
```bash
docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale status
```

### View logs
```bash
docker compose -f docker-compose.orangepi5b.yml logs -f
```

### Restart
```bash
docker compose -f docker-compose.orangepi5b.yml restart
```

### Check advertised routes
```bash
docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale status --json | jq '.Self.AdvertisedRoutes'
```

### Get Tailscale IP
```bash
docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale ip -4
```

## Troubleshooting

### Authentication failed
- Check that TS_AUTHKEY in .env is valid and not expired
- Generate a new auth key at https://login.tailscale.com/admin/settings/keys

### Permission denied /dev/net/tun
- Check that device mount is correct in docker-compose.yml
- Verify /dev/net/tun exists on host

### Operation not permitted
- Check NET_ADMIN capability is set in docker-compose.yml

### Subnet routing not working
- Verify IP forwarding is enabled on host (see Prerequisites)
- Check routes are approved in admin console
- Verify sysctls are set in docker-compose.yml
