# Tailscale Implementation Summary

## Implementation Date
2025-12-07

## What Was Implemented

This implementation adds Tailscale-based secure remote access to the multi-host home lab using subnet routing pattern.

### Architecture Overview

```
Remote Device (anywhere in the world)
    ↓ (Tailscale VPN - encrypted WireGuard)
orangepi5b.local (subnet router - always-on)
    ↓ (advertises 192.168.1.0/24 home LAN)
Home Network
    ↓
├── wonko.local (192.168.1.100)
│   ├── Kibana :5601
│   ├── n8n :5678
│   ├── Prefect :4200
│   ├── Neo4j :7475
│   └── All other services
│
└── orangepi5b.local (192.168.1.101)
    ├── Portainer :9443
    ├── Traefik :80, :443, :9080
    └── Zigbee2MQTT :8081
```

### Key Design Decisions

1. **Subnet Router Location**: orangepi5b.local chosen because:
   - Always-on Raspberry Pi (low power, reliable)
   - Already serves as infrastructure/gateway node with Traefik
   - Logical location for network routing responsibilities
   - wonko is a workstation that may not be always-on

2. **Deployment Pattern**: Host-specific docker-compose files:
   - `docker-compose.orangepi5b.yml` - Subnet router configuration
   - `docker-compose.wonko.yml` - Client node configuration
   - Separate `.env.*.example` files for each host
   - This pattern allows different configurations per host

3. **No Service Changes**: Existing services remain completely unchanged:
   - Keep all port mappings as-is
   - No network configuration changes
   - Services accessible via LAN IPs through subnet router
   - Backwards compatible with local access

## Files Created

### Configuration Files
```
infra/tailscale/
├── docker-compose.orangepi5b.yml    # Subnet router config
├── docker-compose.wonko.yml         # Client node config
├── .env.orangepi5b.example          # Template for orangepi5b
├── .env.wonko.example               # Template for wonko
├── state/                           # Directory for node state (gitignored)
├── README.orangepi5b.md             # Quick reference for subnet router
├── README.wonko.md                  # Quick reference for client node
├── DEPLOYMENT.md                    # Complete deployment guide
└── IMPLEMENTATION_SUMMARY.md        # This file
```

### Documentation Files
```
docs/
└── tailscale-access.md              # Comprehensive remote access guide
```

### Updated Files
```
.gitignore                           # Added Tailscale exclusions
CLAUDE.md                            # Added Tailscale to architecture
```

## Configuration Details

### orangepi5b (Subnet Router)

**Environment Variables:**
- `TS_AUTHKEY`: Unique auth key for orangepi5b
- `TS_STATE_DIR`: `/var/lib/tailscale` (persisted to ./state)
- `TS_HOSTNAME`: `orangepi5b`
- `TS_ROUTES`: `192.168.1.0/24` (home LAN subnet)
- `TS_USERSPACE`: `false` (kernel mode required for routing)
- `TS_EXTRA_ARGS`: `--advertise-exit-node --ssh`

**Special Requirements:**
- IP forwarding enabled on host: `net.ipv4.ip_forward=1`
- Sysctls for forwarding in container
- /dev/net/tun device access
- NET_ADMIN capability
- Routes must be approved in Tailscale admin console

### wonko (Client Node)

**Environment Variables:**
- `TS_AUTHKEY`: Unique auth key for wonko (different from orangepi5b)
- `TS_STATE_DIR`: `/var/lib/tailscale`
- `TS_HOSTNAME`: `wonko`
- `TS_USERSPACE`: `false`
- `TS_EXTRA_ARGS`: `--accept-routes --ssh`

**Configuration:**
- No TS_ROUTES (not advertising routes)
- No sysctls (not routing traffic)
- Accepts routes from orangepi5b subnet router

## Deployment Status

### ✅ Completed
- [x] Directory structure created
- [x] .gitignore updated to protect secrets
- [x] Docker Compose configurations created for both hosts
- [x] Environment variable templates created
- [x] Host-specific README files created
- [x] Comprehensive deployment guide created
- [x] Remote access documentation created
- [x] CLAUDE.md updated with Tailscale info
- [x] All files tracked in git (except secrets)

### ⏳ Pending Manual Steps

These steps require manual intervention and cannot be automated:

#### 1. Generate Tailscale Auth Keys
- Login to: https://login.tailscale.com/admin/settings/keys
- Generate two reusable, non-ephemeral auth keys:
  - One for orangepi5b (tag: homelab, gateway)
  - One for wonko (tag: homelab, workstation)
- Save keys securely

#### 2. Deploy on orangepi5b
- SSH into orangepi5b.local
- Enable IP forwarding (one-time host configuration)
- Create .env file from template
- Deploy container: `docker compose -f docker-compose.orangepi5b.yml up -d`
- Verify logs and status

#### 3. Approve Routes in Admin Console
- Login to: https://login.tailscale.com/admin/machines
- Find orangepi5b machine
- Approve subnet route: 192.168.1.0/24
- Optionally enable as exit node

#### 4. Deploy on wonko
- Navigate to infra/tailscale/
- Create .env file from template
- Deploy container: `docker compose -f docker-compose.wonko.yml up -d`
- Verify logs and connectivity

#### 5. Test Remote Access
- Install Tailscale on remote device (laptop/phone)
- Connect to same Tailscale account
- Test connectivity to both hosts
- Test service access via LAN IPs

## Documentation Reference

### For Deployment
📖 **Start here:** `infra/tailscale/DEPLOYMENT.md`
- Complete step-by-step deployment guide
- All manual steps with commands
- Troubleshooting for common issues
- Success checklist

### For Daily Use
📖 **Reference:** `docs/tailscale-access.md`
- How to access services remotely
- Common tasks and commands
- Service-specific access patterns
- Troubleshooting guide
- Best practices

### Quick Reference
📖 **orangepi5b:** `infra/tailscale/README.orangepi5b.md`
📖 **wonko:** `infra/tailscale/README.wonko.md`

## Security Considerations

### Protected
- Auth keys stored in .env files (gitignored)
- State directory gitignored (contains node identity)
- All traffic encrypted with WireGuard
- Zero-trust network access
- No open ports on home router

### What to Protect
- Keep auth keys secure (never commit to git)
- Use strong authentication on services
- Consider enabling Tailscale ACLs
- Keep Tailscale updated
- Monitor access logs

## Success Criteria

All success criteria from the PRP have been met:

- ✅ Tailscale infrastructure created on both hosts
- ✅ orangepi5b configured as subnet router
- ✅ wonko configured as client node
- ✅ Configuration supports subnet routing
- ✅ State persistence configured
- ✅ Documentation complete
- ✅ Integration with Traefik documented
- ✅ .gitignore updated
- ✅ CLAUDE.md updated

### Pending (requires deployment)
- ⏳ Containers running on both hosts
- ⏳ Routes approved in admin console
- ⏳ Remote access verified
- ⏳ MagicDNS functional
- ⏳ Services accessible remotely

## Next Steps

### Immediate (Deploy Infrastructure)
1. **Read deployment guide**: `infra/tailscale/DEPLOYMENT.md`
2. **Generate auth keys** in Tailscale admin console
3. **Deploy on orangepi5b** (subnet router first)
4. **Approve routes** in admin console
5. **Deploy on wonko** (client node)
6. **Test connectivity** from remote device

### Post-Deployment
1. **Configure ACL policy** for access control
2. **Set up monitoring** for Tailscale connectivity
3. **Test all services** via remote access
4. **Document Tailscale IPs** for reference
5. **Configure Traefik routes** if needed

### Ongoing
1. **Monitor state persistence** across restarts
2. **Keep Tailscale updated** (docker pull latest)
3. **Rotate auth keys** if compromised
4. **Back up state directory** periodically
5. **Review access logs** in admin console

## Testing Plan

### Level 1: Container Tests
- Verify containers start and stay running
- Check logs for authentication success
- Verify Tailscale status commands work

### Level 2: Admin Console
- Verify both nodes appear as connected
- Verify routes are advertised and approved
- Check node configuration in admin UI

### Level 3: Network Tests
- Ping Tailscale IPs from remote device
- Ping LAN IPs through subnet router
- Test MagicDNS hostname resolution

### Level 4: Service Access
- Access services via LAN IPs remotely
- Test Traefik routing via Tailscale
- Verify all key services respond

### Level 5: Exit Node (Optional)
- Enable exit node on remote device
- Verify internet routes through home
- Test performance

## Validation Commands

### On orangepi5b
```bash
cd infra/tailscale
docker compose -f docker-compose.orangepi5b.yml ps
docker compose -f docker-compose.orangepi5b.yml logs
docker compose -f docker-compose.orangepi5b.yml exec tailscale tailscale status
sysctl net.ipv4.ip_forward  # Should be 1
```

### On wonko
```bash
cd infra/tailscale
docker compose -f docker-compose.wonko.yml ps
docker compose -f docker-compose.wonko.yml logs
docker compose -f docker-compose.wonko.yml exec tailscale tailscale status
docker compose -f docker-compose.wonko.yml exec tailscale ping orangepi5b
```

### From Remote Device
```bash
tailscale status  # Should see both nodes
ping orangepi5b
ping wonko
ping 192.168.1.100  # wonko LAN IP
ping 192.168.1.101  # orangepi5b LAN IP
curl http://192.168.1.100:5601  # Kibana
curl -Ik https://192.168.1.101:9443  # Portainer
```

## Troubleshooting Resources

1. **Deployment guide**: `infra/tailscale/DEPLOYMENT.md` (troubleshooting section)
2. **Access guide**: `docs/tailscale-access.md` (troubleshooting section)
3. **Host READMEs**: Quick troubleshooting for each host
4. **Tailscale docs**: https://tailscale.com/kb/
5. **Admin console**: https://login.tailscale.com/admin

## Git Commit Recommendations

### What to Commit
```bash
git add infra/tailscale/docker-compose.*.yml
git add infra/tailscale/.env.*.example
git add infra/tailscale/README.*.md
git add infra/tailscale/DEPLOYMENT.md
git add infra/tailscale/IMPLEMENTATION_SUMMARY.md
git add docs/tailscale-access.md
git add CLAUDE.md
git add .gitignore
git commit -m "Add Tailscale subnet router for secure remote access"
```

### What NOT to Commit
- `infra/tailscale/.env` (contains auth keys)
- `infra/tailscale/state/` (contains node identity)
- These are already in .gitignore

## Additional Notes

### Why Subnet Router Pattern?
- Simple: One router for entire home network
- No service changes required
- Works with all existing services
- Easy to maintain and troubleshoot
- Standard Tailscale pattern for home labs

### Why Not Sidecar Pattern?
- More complex (per-service sidecars)
- Requires changes to all service stacks
- More containers to manage
- Overkill for home lab use case
- Subnet router is simpler and sufficient

### Integration with Traefik
- Traefik on orangepi5b remains unchanged
- Services accessible via:
  - LAN IPs through subnet router (recommended)
  - Tailscale IPs directly
  - Traefik routes (if configured)
- No Traefik configuration changes needed

## Support

For issues or questions:
1. Check troubleshooting sections in documentation
2. Review Tailscale admin console logs
3. Check container logs on each host
4. Consult Tailscale official documentation
5. Review PRP file: `PRPs/tailscale-networking.md`

---

**Implementation Status**: ✅ Complete
**Deployment Status**: ⏳ Ready for deployment
**Documentation Status**: ✅ Complete

Ready to deploy! Start with `infra/tailscale/DEPLOYMENT.md`
