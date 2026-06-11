# Phase 8: Media & Self-Hosted Services

**Learning goals**: Service management, Docker compose for stateful apps, health monitoring, Minecraft server management, optical media automation.

---

## 8.1 Jellyfin Media Server

**What to do**:
```bash
mkdir -p ~/docker/jellyfin && cd ~/docker/jellyfin
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    volumes:
      - "./config:/config"
      - "./cache:/cache"
      - "/mnt/media:/media:ro"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Your/Timezone
    # Hardware Acceleration (Sandy Bridge VA-API)
    devices:
      - /dev/dri/renderD128:/dev/dri/renderD128
```
```bash
docker compose up -d
```

**Performance Caveat (2026 Edition)**:
- **Sandy Bridge QSV/VA-API**: Supports **H.264** and **MPEG-2** only.
- **HEVC/H.265 / AV1**: NO hardware support. The i7-2860QM will struggle to decode these via software (software transcoding ≈ 2-3 1080p H.264 streams max).
- **HDR Tone-Mapping**: NOT supported on this hardware.
- **2026 Budget Upgrade**: Consider adding an **Intel Arc A310** ($80-90) if your library has HEVC/AV1. It provides modern QuickSync (AV1 support) and bypasses all Sandy Bridge limits.
- **Quadro 1000M**: Fermi architecture. Limited H.264 support, complex drivers. Stick to Intel VA-API (i965 driver) for now.

**Must NOT do**:
- Don't expect 4K transcoding (impossible on this hardware)
- Don't enable HEVC/VP9/AV1 hardware decoding in Jellyfin settings (will crash)
- Don't expose Jellyfin to internet without reverse proxy + TLS

**Verification**:
- `docker ps` → jellyfin running
- Browser: `http://192.168.1.200:8096` → Jellyfin setup wizard
- Add media folder, scan, play a file
- Dashboard shows playback info (direct vs transcoded)

**Evidence to Capture**:
- [ ] Jellyfin dashboard screenshot
- [ ] Media playback working

---

## 8.2 Pelican Panel (Minecraft Server Management)

**What to do** (2026 successor to Pterodactyl):
Pelican requires a database and a web server. For this lab, we will use a simplified Docker setup.

```bash
mkdir -p ~/docker/pelican && cd ~/docker/pelican
# Download the Pelican compose file (example)
# curl -L https://pelican.dev/download/compose.yaml -o compose.yaml
```

**Learning**: Game server orchestration, panel/daemon (wings) architecture, mod management.

**Verification**:
- Access `http://192.168.1.200:8080` (or configured port).
- Create a Minecraft instance (use **Purpur** for 2860QM optimization).
- Connect from Minecraft client to server IP.

---

## 8.3 Automated CD Ripping Station (ARM)

**What to do**:
Turn your internal ODD into an "insert-and-forget" ripper.

```bash
mkdir -p ~/docker/arm && cd ~/docker/arm
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  arm:
    image: automaticrippingmachine/automatic-ripping-machine:latest
    container_name: arm
    devices:
      - /dev/sr0:/dev/sr0  # Your CD drive
    volumes:
      - "./config:/home/arm/config"
      - "/mnt/media/music:/home/arm/music"
    environment:
      - PUID=1000
      - PGID=1000
    restart: unless-stopped
```
```bash
docker compose up -d
```

**Learning**: Linux device passthrough (`/dev/sr0`), automated workflows, music metadata tagging (MusicBrainz).

**Verification**:
- Insert a music CD.
- Monitor logs: `docker logs -f arm`.
- Check `/mnt/media/music` for new FLAC files after ejection.

---

## 8.4 Gitea Git Server

**What to do**:
```bash
mkdir -p ~/docker/gitea && cd ~/docker/gitea
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    restart: unless-stopped
    ports:
      - "3000:3000"
      - "2222:22"
    volumes:
      - "./data:/data"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__server__DOMAIN=192.168.1.200
      - GITEA__server__SSH_DOMAIN=192.168.1.200
```
```bash
docker compose up -d
```

**Learning**: Git server administration, SSH vs HTTP modes, Gitea vs GitLab

**Verification**:
- `docker ps` → gitea running
- Browser: `http://192.168.1.200:3000` → Gitea UI
- Register first user, create a repo
- `git clone http://192.168.1.200:3000/user/repo.git` → works
- `git push` → succeeds

**Evidence to Capture**:
- [ ] Gitea dashboard screenshot
- [ ] Git clone/push test

---

## 8.5 Navidrome (FLAC Music Streamer)

**What to do**:
Navidrome is an ultra-lightweight, Subsonic-API compatible music server perfect for large FLAC libraries. It pairs perfectly with the ARM CD ripper.

```bash
mkdir -p ~/docker/navidrome && cd ~/docker/navidrome
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    restart: unless-stopped
    ports:
      - "4533:4533"
    volumes:
      - "./data:/data"
      - "/mnt/media/music:/music:ro"
    environment:
      - ND_LOGLEVEL=info
```
```bash
docker compose up -d
```

**Learning**: Subsonic API ecosystem, read-only (`:ro`) volume mapping for media protection.

**Verification**:
- Access `http://192.168.1.200:4533`.
- Create admin user and verify FLAC files are scanning. You can now use apps like **Symfonium** (Android) or **Plexamp**-alternatives to stream.

---

## 8.6 Syncthing & Obsidian LiveSync

**What to do**:
Syncthing provides P2P file sync (great for general files). For true real-time Obsidian syncing, host a CouchDB instance for the `obsidian-livesync` community plugin.

```bash
mkdir -p ~/docker/sync && cd ~/docker/sync
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  syncthing:
    image: syncthing/syncthing:latest
    container_name: syncthing
    restart: unless-stopped
    ports:
      - "8384:8384" # Web UI
      - "22000:22000/tcp" # TCP transfers
      - "22000:22000/udp" # QUIC transfers
      - "21027:21027/udp" # Local discovery
    volumes:
      - "./syncthing-config:/var/syncthing"
      - "/mnt/data/sync:/var/syncthing/Sync"

  couchdb:
    image: couchdb:latest
    container_name: couchdb
    restart: unless-stopped
    ports:
      - "5984:5984"
    environment:
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD=super_secret_password
    volumes:
      - "./couchdb-data:/opt/couchdb/data"
      - "./couchdb-etc:/opt/couchdb/etc/local.d"
```
```bash
docker compose up -d
```

**Learning**: Peer-to-peer sync protocols, NoSQL databases (CouchDB), plugin integration.

**Verification**:
- Access Syncthing at `http://192.168.1.200:8384`.
- Access CouchDB at `http://192.168.1.200:5984/_utils` (Fauxton UI).
- Configure Obsidian LiveSync plugin to point to your CouchDB instance.

---

## 8.7 Optional Lightweight Services

**What to do** (pick based on interest + remaining memory):

| Service | Image | RAM | Purpose |
|---------|-------|-----|---------|
| Uptime Kuma | `louislam/uptime-kuma` | ~100MB | Monitoring dashboard |
| Immich | `ghcr.io/immich-app/immich-server` | ~1GB | Advanced Photo Backup |
| Ollama | `ollama/ollama` | ~1-4GB | Local AI / LLM engine |
| FrogFind | `actionretro/frogfind` | ~50MB | Vintage Web Proxy |
| Vaultwarden | `vaultwarden/server` | ~50MB | Password manager |
| MinIO | `minio/minio` | ~200MB | S3-compatible storage |
| Nginx Proxy Manager | `jc21/nginx-proxy-manager` | ~150MB | Web UI for reverse proxy |
| Watchtower | `containrrr/watchtower` | ~20MB | Auto-update containers |

**Memory budget check before adding**:
```bash
free -h
docker stats --no-stream
```

**Must NOT do**:
- Don't add services without checking available memory first
- Don't run Watchtower if you want manual control over updates

**Verification**:
- Service-specific verification (dashboard accessible, API responds)

---

## 8.8 Service Monitoring + Health Checks

**What to do**:
```bash
# Create a monitoring script
sudo nano /usr/local/bin/health-check.sh
```
**Content**:
```bash
#!/bin/bash
# Check critical services

services=("sshd" "ufw" "docker" "smbd" "nginx")
failures=0

for svc in "${services[@]}"; do
  if ! systemctl is-active --quiet "$svc"; then
    echo "FAIL: $svc is not running"
    ((failures++))
  else
    echo "OK: $svc is running"
  fi
done

# Check Docker containers
for container in pihole portainer jellyfin gitea pelican arm navidrome syncthing couchdb; do
  if ! docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null | grep -q running; then
    echo "FAIL: container $container not running"
    ((failures++))
  else
    echo "OK: container $container running"
  fi
done

exit $failures
```
```bash
sudo chmod +x /usr/local/bin/health-check.sh

# Add to crontab (hourly check, log failures)
echo '0 * * * * /usr/local/bin/health-check.sh >> /var/log/health-check.log 2>&1' | sudo crontab -
```

**Learning**: System monitoring patterns, exit codes, health check implementation

**Verification**:
- Run script: should print all services as OK
- Stop a service: script should detect and report
- Log file created: `/var/log/health-check.log`

**Evidence to Capture**:
- [ ] health-check.sh OK output
- [ ] Crontab entry confirmed
