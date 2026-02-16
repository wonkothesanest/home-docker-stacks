# Duplicati - Automated Backup Solution

Duplicati is a free, open-source backup solution with a web UI that supports encrypted backups to cloud storage.

## Features

- **Web UI**: User-friendly interface for managing backups
- **Encryption**: AES-256 encryption for all backups
- **Deduplication**: Block-level deduplication saves storage space
- **Compression**: Built-in compression reduces backup size
- **Cloud Storage**: Supports 20+ cloud providers (S3, B2, Azure, Google Drive, OneDrive, Dropbox, etc.)
- **Scheduling**: Flexible backup schedules with retention policies
- **Versioning**: Keep multiple versions of files
- **Email Notifications**: Get notified on backup success/failure
- **Bandwidth Throttling**: Control upload/download speeds

## Multi-Host Setup

This repository includes configurations for both hosts:
- **orangepi5b**: `docker-compose.orangepi5b.yml` (port 8200)
- **wonko**: `docker-compose.wonko.yml` (port 8201)

Each host backs up its own Docker volumes to cloud storage.

## Quick Start

### Deploy on orangepi5b

```bash
cd infra/duplicati
cp .env.example .env
nano .env  # Set DUPLICATI_PORT=8200

# Deploy using the orangepi5b compose file
docker compose -f docker-compose.orangepi5b.yml up -d
```

**Access**:
- Direct: http://orangepi5b.local:8200
- Traefik: http://backup-orangepi5b.home

### Deploy on wonko

```bash
cd infra/duplicati
cp .env.example .env
nano .env  # Set DUPLICATI_PORT=8201

# Deploy using the wonko compose file
docker compose -f docker-compose.wonko.yml up -d
```

**Access**:
- Direct: http://wonko.local:8201
- Traefik: http://backup-wonko.home (after adding to Traefik config)

## Initial Setup

### 1. First Access

1. Open the web UI (http://hostname:port)
2. You'll be greeted with the setup wizard
3. Choose "No, my machine has only a single account" or set up password protection (recommended)

### 2. Configure Your First Backup

#### Step 1: General Settings
- **Name**: `orangepi5b-volumes` or `wonko-volumes`
- **Description**: Docker volumes backup
- **Encryption**: Choose AES-256 (recommended)
  - Set a strong passphrase and **SAVE IT SECURELY**
  - Without the passphrase, you cannot restore backups!

#### Step 2: Destination (Cloud Storage)

Choose your cloud provider:

**Backblaze B2** (Recommended):
- Type: `B2 Cloud Storage`
- Account ID: Your B2 key ID
- Application Key: Your B2 application key
- Bucket Name: `your-backup-bucket`
- Path: `/orangepi5b/` or `/wonko/`
- Test connection before proceeding

**AWS S3**:
- Type: `S3 Compatible`
- AWS Access Key ID
- AWS Secret Access Key
- Bucket Name
- Bucket Region
- Path prefix: `orangepi5b/` or `wonko/`

**Other Providers**:
- Google Drive
- Microsoft OneDrive
- Dropbox
- Azure Blob Storage
- WebDAV (Nextcloud/ownCloud)
- SFTP/SSH
- Many more...

#### Step 3: Source Data

Select folders/volumes to backup:

**For orangepi5b**:
```
/source/volumes/portainer    (Portainer config)
/source/volumes/pihole       (Pi-hole settings)
/source/volumes/traefik      (Traefik certificates)
```

**For wonko**:
```
/source/volumes/n8n               (n8n workflows)
/source/volumes/n8n-postgres      (n8n database)
/source/volumes/prefect-postgres  (Prefect database)
/source/volumes/elasticsearch     (Elasticsearch data)
/source/volumes/neo4j             (Neo4j graph database)
```

**Tip**: You can also select the entire `/source/docker-volumes/` directory to backup everything.

#### Step 4: Schedule

Set backup frequency:
- **Daily**: 2:00 AM (recommended for most)
- **Every 6 hours**: For frequently changing data
- **Weekly**: Sunday 3:00 AM for less critical data

**Retention**: Keep backups for 30 days (or your preference)

#### Step 5: Options

Recommended settings:
- **Compression**: Auto
- **Block size**: Auto (default)
- **Backup retention**: Delete backups older than 30 days
- **Upload volume size**: 50MB (good for cloud uploads)

**Advanced**:
- Enable throttling if you have slow internet
- Set thread priority to low if backup impacts performance

#### Step 6: Review and Run

Review settings and click "Save".

**Run First Backup**:
- Click "Run now" to test the backup
- Monitor progress in the UI
- Check logs for any errors

## Managing Backups

### View Backup Status

- **Home**: Shows all configured backups
- **Status**: Active backup jobs and recent activity
- **Logs**: Detailed logs for troubleshooting

### Running Manual Backups

1. Click on a backup configuration
2. Click "Run now"
3. Monitor progress in real-time

### Restoring Files

1. Click on backup name
2. Click "Restore files"
3. Choose restore point (date/time)
4. Browse and select files to restore
5. Choose restore location
6. Click "Restore"

**Important**: To restore Docker volumes, you typically restore to a temporary location first, then copy files into volumes manually.

### Email Notifications

1. Click backup name → "Edit" → "Options"
2. Add these advanced options:
   ```
   --send-mail-url=smtp://smtp.gmail.com:587
   --send-mail-username=your-email@gmail.com
   --send-mail-password=your-app-password
   --send-mail-from=your-email@gmail.com
   --send-mail-to=your-email@gmail.com
   --send-mail-level=Success,Warning,Error
   ```

## Cloud Storage Setup Guides

### Backblaze B2 (Recommended)

1. Sign up at [backblaze.com](https://www.backblaze.com/b2/sign-up.html)
2. Create a bucket: `Buckets` → `Create a Bucket`
   - Name: `homelab-backups`
   - Files: Private
3. Create application key: `App Keys` → `Add a New Application Key`
   - Name: `duplicati-backup`
   - Access: Read and Write
   - Bucket: `homelab-backups`
4. Save the **Key ID** and **Application Key**
5. In Duplicati:
   - Storage Type: `B2 Cloud Storage`
   - Account ID: Key ID
   - Application Key: Application Key
   - Bucket: `homelab-backups`
   - Path: `/orangepi5b/` or `/wonko/`

**Cost**: $6/TB/month, 10GB free

### AWS S3

1. Create S3 bucket in AWS Console
2. Create IAM user with S3 permissions
3. Generate access keys
4. In Duplicati:
   - Storage Type: `S3 Compatible`
   - Enter credentials and bucket name

### Google Drive

1. In Duplicati: Select `Google Drive`
2. Click `AuthID` link to authenticate
3. Grant permissions
4. Copy AuthID back to Duplicati
5. Set folder path

### Nextcloud/ownCloud (WebDAV)

1. Get WebDAV URL from Nextcloud
   - Usually: `https://nextcloud.example.com/remote.php/dav/files/username/`
2. In Duplicati:
   - Storage Type: `WebDAV`
   - Server URL: Your WebDAV URL
   - Username and password
   - Path: `/backups/orangepi5b/`

## Adding More Volumes to Backup

### On orangepi5b

1. Edit `docker-compose.orangepi5b.yml`
2. Add volume mount:
   ```yaml
   volumes:
     - new_volume_name:/source/volumes/new-volume:ro

   volumes:
     new_volume_name:
       external: true
   ```
3. Restart Duplicati:
   ```bash
   docker compose -f docker-compose.orangepi5b.yml down
   docker compose -f docker-compose.orangepi5b.yml up -d
   ```
4. Update backup job in Web UI to include new path

### On wonko

Same process using `docker-compose.wonko.yml`

## Database Backups

For consistent database backups, you have two options:

### Option 1: Stop Container During Backup

Less ideal but simple:
1. Stop database container before backup
2. Backup volume
3. Start container after backup

### Option 2: Database Dump + Backup (Recommended)

Create database dumps before backing up:

**PostgreSQL**:
```bash
# Create dump script in ~/backup-scripts/
docker exec postgres_container pg_dumpall -U postgres > /backups/postgres-dump.sql
```

**Elasticsearch**:
Use snapshot API or backup the data directory when indices are not changing.

**Neo4j**:
```bash
docker exec neo4j neo4j-admin dump --database=neo4j --to=/backups/neo4j-backup.dump
```

Then backup the dump files via Duplicati.

## Monitoring and Maintenance

### Check Backup Health

1. Regularly check the Duplicati dashboard
2. Verify recent backups completed successfully
3. Check email notifications (if configured)

### Test Restores

**Critical**: Test your backups quarterly!

1. Pick a random backup
2. Restore a few files to a temp location
3. Verify files are intact and accessible
4. Document your restore process

### Verify Encryption

Try restoring without passphrase to confirm encryption works:
- Should fail without the correct passphrase
- Keep passphrase in a secure location (password manager, safe)

### Check Storage Usage

Monitor cloud storage usage:
- Duplicati shows backup size in dashboard
- Check cloud provider dashboard
- Adjust retention if needed

## Troubleshooting

### Backup Fails with "Connection Timeout"

- **Issue**: Cloud provider unreachable or slow connection
- **Solution**:
  - Check internet connection
  - Increase timeout in Options → Advanced → `http-operation-timeout=600`
  - Enable bandwidth throttling if needed

### "Access Denied" Error

- **Issue**: Invalid credentials or permissions
- **Solution**:
  - Verify credentials in cloud provider dashboard
  - Test connection in Duplicati
  - Check bucket/container permissions

### Backup is Very Slow

- **Solutions**:
  - Reduce `upload-volume-size` (e.g., 25MB)
  - Increase `concurrency-max-threads=4`
  - Enable compression
  - Schedule during off-peak hours

### Cannot Restore - Wrong Passphrase

- **Issue**: Encryption passphrase incorrect or lost
- **Solution**:
  - Check password manager for correct passphrase
  - Try variations (case sensitive!)
  - If lost, backups are unrecoverable ⚠️

### Web UI Won't Load

1. Check container is running:
   ```bash
   docker ps | grep duplicati
   ```

2. Check logs:
   ```bash
   docker logs duplicati
   ```

3. Verify port isn't blocked:
   ```bash
   curl http://localhost:8200
   ```

### Database Corruption

If Duplicati's local database corrupts:

1. Stop Duplicati
2. Delete `./config/Duplicati-server.sqlite`
3. Restart Duplicati
4. Re-configure backup jobs (metadata is in cloud)

## Security Best Practices

1. **Enable Password Protection**: Set password in Settings → Password
2. **Use Strong Encryption**: Always enable AES-256 encryption
3. **Secure Passphrase**: Use 20+ character passphrase
4. **Store Passphrase Safely**: Password manager + written backup
5. **Use HTTPS**: Access Duplicati via Traefik with HTTPS
6. **Limit Access**: Use firewall rules or Traefik auth middleware
7. **Rotate Keys**: Periodically rotate cloud storage access keys

## Performance Tips

1. **Schedule wisely**: Run backups during low-activity hours
2. **Block size**: Larger blocks = faster but less efficient deduplication
3. **Compression**: Enable for text/logs, disable for already-compressed data
4. **Threads**: Increase for faster multi-file uploads
5. **Bandwidth**: Throttle during business hours if needed

## Cost Optimization

1. **Choose the right provider**:
   - Backblaze B2: Best price for cold storage ($6/TB/month)
   - Wasabi: $6.99/TB/month, no egress fees
   - AWS S3: More expensive, but better integration

2. **Retention policy**: Don't keep backups forever
   - 7 days: Development environments
   - 30 days: Most home labs (recommended)
   - 90 days: Critical data

3. **Deduplication**: Enabled by default, saves significant space

4. **Compression**: Can reduce backup size by 50-70%

## Backup Size Estimates

Typical Docker volumes for home lab:

**orangepi5b**:
- Portainer: ~100 MB
- Pi-hole: ~50 MB
- Traefik: ~10 MB
- **Total**: ~160 MB

**wonko**:
- n8n + Postgres: ~500 MB
- Prefect + Postgres: ~300 MB
- Elasticsearch: ~2-5 GB (depends on data)
- Neo4j: ~1-3 GB (depends on graph size)
- **Total**: ~4-9 GB

**With 30-day retention**:
- Daily incremental backups are much smaller (only changes)
- Total storage: 2-3x initial backup size
- orangepi5b: ~500 MB
- wonko: ~15-30 GB

**Monthly cost** (Backblaze B2):
- orangepi5b: FREE (under 10 GB)
- wonko: ~$1.50-3/month

## Additional Resources

- [Duplicati Website](https://www.duplicati.com/)
- [Duplicati Documentation](https://duplicati.readthedocs.io/)
- [Forum](https://forum.duplicati.com/)
- [GitHub](https://github.com/duplicati/duplicati)

## Upgrading Duplicati

```bash
cd infra/duplicati
docker compose -f docker-compose.[hostname].yml pull
docker compose -f docker-compose.[hostname].yml up -d
```

## Uninstalling

To remove Duplicati:

```bash
docker compose -f docker-compose.[hostname].yml down -v
# Optionally remove config and backups
rm -rf config/ backups/
```

**Warning**: This will delete local backup configuration. Cloud backups remain intact.
