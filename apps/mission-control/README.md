# Mission Control

Sibling Docker stack for Builderz Mission Control.

## Notes
- Wired to the existing OpenClaw gateway on the Docker host via `host.docker.internal:18889`
- Mounts OpenClaw state read-only from `/home/dusty/.openclaw` into `/run/openclaw`
- Persistent app data lives in the named volume `mission-control-data`
- Mission Control runs on the upstream image
- A dedicated Tailscale sidecar publishes Mission Control at `https://mission-control.coho-teeth.ts.net/`

## Bring up
```bash
docker compose up -d
```

## Open
- Local/LAN: `http://mission-control.openclaw.home`
- Tailscale HTTPS: `https://mission-control.coho-teeth.ts.net/`
- Local direct port: `http://orangepi5b.local:3011`

## Login
Current credentials are stored in `.env`:
- Username: `dusty`
- Password: `Ninja`

## Tailscale key rotation / reset
The Mission Control Tailscale sidecar reads its auth key from:
- `../../infra/tailscale/.env`

If the key expires or stops working:
1. Generate a new reusable Tailscale auth key in the Tailscale admin console.
2. Update `TS_AUTHKEY` in `home-docker-stacks/infra/tailscale/.env`.
3. Restart the sidecar:
   ```bash
   cd /home/dusty/workspace/home-docker-stacks/apps/mission-control
   docker compose up -d mission-control-tailscale
   ```
4. Check status/logs if needed:
   ```bash
   docker logs --tail=100 mission-control-tailscale
   docker exec mission-control-tailscale tailscale --socket=/tmp/tailscaled.sock status
   docker exec mission-control-tailscale tailscale --socket=/tmp/tailscaled.sock serve status
   ```

If the sidecar ever loses its identity and you want to force a clean re-login, stop it, remove `apps/mission-control/tailscale-state/`, then bring `mission-control-tailscale` back up with a fresh key.

## Important
Change `AUTH_PASS` and `API_KEY` in `.env` after first successful login.
