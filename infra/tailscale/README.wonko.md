# Tailscale Client Node (wonko)

This node accepts routes from the subnet router (orangepi5b).

## Setup

1. Copy .env.wonko.example to .env
   ```bash
   cp .env.wonko.example .env
   ```

2. Edit .env with your Tailscale auth key (different from orangepi5b's key)
   ```bash
   nano .env
   ```

3. Deploy the stack
   ```bash
   docker compose -f docker-compose.wonko.yml up -d
   ```

4. Check the logs
   ```bash
   docker compose -f docker-compose.wonko.yml logs -f
   ```

## Common Commands

### Check status
```bash
docker compose -f docker-compose.wonko.yml exec tailscale tailscale status
```

### View logs
```bash
docker compose -f docker-compose.wonko.yml logs -f
```

### Restart
```bash
docker compose -f docker-compose.wonko.yml restart
```

### Check received routes
```bash
docker compose -f docker-compose.wonko.yml exec tailscale ip route show table 52
```

### Get Tailscale IP
```bash
docker compose -f docker-compose.wonko.yml exec tailscale tailscale ip -4
```

### Test connectivity to orangepi5b
```bash
docker compose -f docker-compose.wonko.yml exec tailscale ping orangepi5b
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

### Can't see orangepi5b as peer
- Verify orangepi5b Tailscale is running and connected
- Check both nodes are using same Tailscale account
- Check admin console at https://login.tailscale.com/admin/machines
