# SV-03: Pelican Game Server Panel + Minecraft Server

**Goal**: Deploy Pelican panel, run Minecraft server(s), friends connect without Tailscale.

---

## 1. Architecture

```
Internet ←→ Router (port forward) ←→ M4600
                                     │
                              ┌──────┴──────┐
                              │  Pelican     │
                              │  Panel       │  ← Web UI for you + friends
                              │  (port 9443) │
                              └──────┬──────┘
                                     │ HTTP API
                              ┌──────┴──────┐
                              │  Wings       │  ← Daemon, spawns containers
                              │  (daemon)    │
                              └──────┬──────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
             ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
             │ Minecraft   │ │ Minecraft   │ │ Minecraft   │
             │ Server 1    │ │ Server 2    │ │ Server 3    │
             │ :25565      │ │ :25566      │ │ :25567      │
             └─────────────┘ └─────────────┘ └─────────────┘
```

Friend connects → `mc.dankofox.quest:25565` (or subdomain with SRV record)

---

## 2. Network Connection Plan (CRITICAL — READ THIS FIRST)

### Step 0: DDNS — Keep domain pointing to your IP

Your ISP (FPT) uses dynamic IP. Without this, the domain breaks when IP changes.

**Install cloudflare-ddns**:

Create `~/docker/cloudflare-ddns/compose.yaml`:

```yaml
services:
  ddns:
    image: oznu/cloudflare-ddns:latest
    container_name: cloudflare-ddns
    restart: unless-stopped
    environment:
      - API_KEY=<your-cloudflare-api-token>
      - ZONE=dankofox.quest
      - SUBDOMAIN=mc
      - PROXY=false
      - TTL=120
```

**Get API token**:

1. Cloudflare Dashboard → My Profile → API Tokens → Create Token
2. "Edit zone DNS" template → Zone:DNS:Edit → Specific zone `dankofox.quest`
3. Copy token, set as `API_KEY` in compose

**Deploy**:

```bash
mkdir -p ~/docker/cloudflare-ddns
docker compose -f ~/docker/cloudflare-ddns/compose.yaml up -d
docker logs cloudflare-ddns  # verify: "Updated record mc.dankofox.quest to <ip>"
```

Checks every 5 min, auto-updates if IP changed.

### Step 1: Port Forward + DNS (gray cloud) — how friends connect

| Step | What |
|------|------|
| **1** | Router forwards ports 25565-25570 TCP → `192.168.1.200` |
| **2** | Cloudflare DNS `mc.dankofox.quest` A record → your public IP **(gray cloud, DNS-only)** |
| **3** | DDNS keeps the A record updated (Step 0) |
| **4** | Friends connect via domain: `survival.dankofox.quest` (SRV handles port) |

**Why gray cloud**: Minecraft is raw TCP, not HTTP. Cloudflare proxy only works for HTTP/S. Disable orange cloud icon.

**SRV records for multiple servers** (so friends don't type port numbers):

| Type | Name | Target | Value |
|------|------|--------|-------|
| A | `mc` | `171.235.43.0` (your public IP) | — |
| SRV | `_minecraft._tcp.survival` | `mc.dankofox.quest` | 0 5 25565 |
| SRV | `_minecraft._tcp.modded` | `mc.dankofox.quest` | 0 5 25566 |
| SRV | `_minecraft._tcp.creative` | `mc.dankofox.quest` | 0 5 25567 |

Friends type `survival.dankofox.quest` in Minecraft — SRV maps port automatically (Minecraft Java supports it natively).

### Step 2: Direct IP (fallback — no DNS needed)

Friends type `171.235.43.0:25565` in Minecraft. Works immediately after port forwarding. Ugly but zero setup.

### Skip: Cloudflare Spectrum

$1/port/month. Proxies TCP through Cloudflare. Not needed.

---

## 3. Prerequisites

- Docker + Docker Compose (✅ already installed)
- Domain `dankofox.quest` on Cloudflare (✅ already set up)
- Ports forwarded on router: 25565-25570 TCP
- Public IP (see Section 2)
- ~30 minutes for setup

---

## 4. Install Pelican Panel (Docker)

### 4.1 Create directory & compose

```bash
mkdir -p ~/docker/pelican
```

`~/docker/pelican/compose.yaml`:

```yaml
services:
  panel:
    image: ghcr.io/pelican-dev/panel:latest
    container_name: pelican-panel
    restart: unless-stopped
    ports:
      - "9443:443"
    volumes:
      - ./app:/app
      - ./config:/config
    environment:
      APP_URL: "https://pelican.dankofox.quest"
      APP_ENV: "production"
      APP_TIMEZONE: "Asia/Ho_Chi_Minh"
      DB_CONNECTION: sqlite
      CACHE_DRIVER: file
      SESSION_DRIVER: file
      QUEUE_CONNECTION: sync
      TRUSTED_PROXIES: "*"
      # Remove if NOT behind Cloudflare proxy:
      BEHIND_PROXY: "true"
```

### 4.2 Start Panel

```bash
docker compose -f ~/docker/pelican/compose.yaml pull
docker compose -f ~/docker/pelican/compose.yaml up -d
```

### 4.3 Run installer

Open `https://pelican.dankofox.quest` (via Cloudflare tunnel) or `http://192.168.1.200:9443`.

Or run installer from command line:

```bash
docker exec pelican-panel php artisan pelican:setup
```

Follow prompts:
1. Database: SQLite (option 2 — simplest)
2. Email: skip or use mailhog for testing
3. Create admin account
   - Username: `danko`
   - Email: `danko@dankofox.quest`
   - Password: choose a strong one (store in Bitwarden)

### 4.4 Verify

```bash
curl -sI http://192.168.1.200:9443 | head -3
# Expected: HTTP/1.1 200 OK
```

---

## 5. Cloudflare Tunnel for Panel UI (optional)

If you want `https://pelican.dankofox.quest` instead of local IP, add to Cloudflare tunnel config:

```bash
sudo nano /etc/cloudflared/config.yml
```

Add before the catch-all (404):
```yaml
  - hostname: pelican.dankofox.quest
    service: http://localhost:9443
```

Restart tunnel:
```bash
sudo systemctl restart cloudflared
```

Add DNS CNAME in Cloudflare:
- Name: `pelican`
- Target: `<tunnel-id>.cfargotunnel.com`
- Proxy: Orange cloud (proxied)

---

## 6. Install Wings (Game Server Daemon)

Wings runs **on the host** (not in Docker) — it needs to control Docker directly.

```bash
# Create Wings directory
sudo mkdir -p /etc/pelican

# Download Wings binary
curl -L -o /tmp/wings.tar.gz "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_amd64.tar.gz"
sudo tar -xzf /tmp/wings.tar.gz -C /usr/local/bin/
sudo chmod +x /usr/local/bin/wings
rm /tmp/wings.tar.gz

# Verify
wings --version
# Expected: wings v1.0.0-betaXX
```

### 6.1 Create Wings systemd service

`/etc/systemd/system/wings.service`:

```ini
[Unit]
Description=Pelican Wings Daemon
After=docker.service
Requires=docker.service
BindsTo=docker.service

[Service]
User=root
Group=root
WorkingDirectory=/etc/pelican
ExecStart=/usr/local/bin/wings
Restart=on-failure
RestartSec=5s
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
```

### 6.2 Configure Node in Panel (before starting Wings)

1. Log into Pelican Panel as admin
2. Go to **Admin → Nodes → Create New**
3. Fill:

| Field | Value |
|-------|-------|
| Name | `M4600` |
| Description | `Main server` |
| FQDN | `192.168.1.200` |
| Communication | `HTTPS` |
| Behind proxy | `No` |
| Daemon Listen Port | `8080` |
| Daemon SFTP Port | `2022` |
| RAM (MB) | `20000` (leave 4GB for OS + Panel) |
| Disk (MB) | `200000` |
| Daemon Base Path | `/var/lib/pelican` |

4. Click **Create**
5. Go to **Configuration** tab → copy the YAML content

### 6.3 Apply Wings config

```bash
sudo nano /etc/pelican/config.yml
# Paste the YAML from Panel
```

### 6.4 Start Wings

```bash
sudo systemctl enable wings
sudo systemctl start wings
sudo systemctl status wings
# Expected: active (running)
```

Go back to Panel → Node page → should show green "Connected" within 30s.

### 6.5 Create Allocation (port pool)

In Panel → Node `M4600` → Allocations tab:
- IP: `0.0.0.0`
- Ports: `25565-25570`

These are the ports Wings will assign to new servers.

---

## 7. Create First Minecraft Server

### 7.1 In Panel UI

1. **Servers → Create New**
2. Fill:

| Field | Value |
|-------|-------|
| Name | `Survival` |
| Owner | Select `danko` (or your admin) |
| Node | `M4600` |
| Egg | `Paper` (best performance for vanilla-like play) |
| Docker Image | Leave default |
| Version | `latest` |
| Allocation | `0.0.0.0:25565` |
| RAM | `4096` MB |
| CPU | `200` (2 cores) |
| Disk | `10000` MB |
| Port count | `1` |

### 7.2 Start server

1. Click **Install** → Wings downloads Paper JAR automatically (takes 1-2 min)
2. Once installed, click **Start**
3. Watch console output:
   ```
   [14:23:01] Starting...
   [14:23:04] Done! (5.211s)
   ```
4. Accept EULA if needed (Pelican usually does this automatically)

### 7.3 Verify connectivity

From another machine (or a friend's):
```
Minecraft → Multiplayer → Add Server → 192.168.1.200:25565
```
Should connect. If using DNS:
```
Server address: survival.dankofox.quest
```
(assuming SRV record points `_minecraft._tcp.survival.dankofox.quest` → `25565`)

---

## 8. Adding Friends

### 8.1 Create user accounts

In Panel → **Admin → Users → Create**:

| Field | Value |
|-------|-------|
| Name | Friend's name |
| Email | Their email |
| Password | Generate one, they can change it |
| Language | English |

Or enable **registration** in Admin → Settings → Registrations → Enable.

### 8.2 Assign server access

Go to server's **Users** tab → Add user → Select friend → Permissions:

Minimal permissions for friends:
- [x] View server
- [x] Console → Send commands
- [x] Console → View console
- [x] Start/Stop/Restart
- [x] Files → Read, Write, Upload

### 8.3 Friend experience

Friend logs in at `https://pelican.dankofox.quest`:
- Sees the server card
- Clicks **Start**
- Watches console
- Opens Minecraft → connects to `survival.dankofox.quest`
- Done.

---

## 9. Adding Mods

### For Fabric/Forge Server

First create the server with the correct egg:
- Egg: `Fabric` or `Forge Minecraft`
- Version: pick the specific version (e.g. `1.20.1`)

### Upload Mods

1. Go to server → **File Manager**
2. Navigate to `/mods` (Fabric) or `/mods` (Forge)
3. Click **Upload** → select `.jar` files
4. Or drag + drop multiple files
5. Restart server

### Install a Modpack (CurseForge ZIP)

1. Download the modpack ZIP from CurseForge
2. Upload to server root via File Manager
3. Right-click → **Unarchive**
4. Restart server (if modpack has `server_pack` structure with `mods/`)

**Alternative**: Use Pelican's **CurseForge egg** if you want automatic modpack install.

---

## 10. Creating Additional Servers

Repeat Section 7 with different settings:

| Server | Egg | RAM | Port |
|--------|-----|-----|------|
| Survival | Paper | 4GB | 25565 |
| Modded Adventures | Forge | 6GB | 25566 |
| Creative Build | Paper | 2GB | 25567 |

Each server:
- Runs in its own Docker container
- Has its own console, files, backups
- Friends can see/manage only the servers you assign
- Can be started/stopped independently

---

## 11. Router Setup (Port Forwarding)

Log into your router admin panel. Forward these ports:

| External Port | Internal IP | Internal Port | Protocol |
|---------------|-------------|---------------|----------|
| 25565 | 192.168.1.200 | 25565 | TCP |
| 25566 | 192.168.1.200 | 25566 | TCP |
| 25567 | 192.168.1.200 | 25567 | TCP |

**If router asks for service name**: `Minecraft` or `Custom`

**Verify port forwarding**:
```bash
# From outside your network (phone hotspot, friend's machine)
nc -zv <your-public-ip> 25565
# Expected: Connection to ... port 25565 [tcp/*] succeeded!
```

---

## 12. DNS Records (Cloudflare)

Go to Cloudflare Dashboard → `dankofox.quest` → DNS:

### Step 1: A record (unproxied)
| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `mc` | `<your-public-ip>` | **Gray cloud** (DNS only) |

### Step 2: SRV records (for clean subdomain per server)
| Type | Name | Service | Protocol | TTL | Priority | Weight | Port | Target |
|------|------|---------|----------|-----|----------|--------|------|--------|
| SRV | `survival` | `_minecraft` | `_tcp` | Auto | 0 | 5 | 25565 | `mc.dankofox.quest` |
| SRV | `modded` | `_minecraft` | `_tcp` | Auto | 0 | 5 | 25566 | `mc.dankofox.quest` |
| SRV | `creative` | `_minecraft` | `_tcp` | Auto | 0 | 5 | 25567 | `mc.dankofox.quest` |

However, SRV records with subdomains like `survival.dankofox.quest` require an A/AAAA record for `survival` OR the SRV target to resolve. The setup above uses `mc.dankofox.quest` as the target, and the SRV name is the subdomain.

**Alternative simpler approach** for Cloudflare DNS (SRV can be finicky):

Just use direct ports:
- `mc.dankofox.quest:25565` → Survival
- `mc.dankofox.quest:25566` → Modded
- `mc.dankofox.quest:25567` → Creative

Minecraft remembers the port after first connect. Friends only type the port once.

---

## 13. Maintenance

### Update Panel
```bash
docker compose -f ~/docker/pelican/compose.yaml pull
docker compose -f ~/docker/pelican/compose.yaml up -d --remove-orphans
docker exec pelican-panel php artisan migrate --force
```

### Update Wings
```bash
# Download new binary
curl -L -o /tmp/wings.tar.gz "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_amd64.tar.gz"
sudo tar -xzf /tmp/wings.tar.gz -C /usr/local/bin/
rm /tmp/wings.tar.gz
sudo systemctl restart wings
```

### Update Minecraft Server
In Pelican Panel → Server → **Reinstall** → picks latest version for that egg.

### Backup
Pelican has built-in backup in the server UI. Or backup the whole panel:
```bash
docker exec pelican-panel php artisan pelican:backup
```

---

## 14. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Wings won't connect to Panel | Check `config.yml` FQDN/IP matches, port 8080 not firewalled |
| Friends can't connect | Is port 25565 forwarded? Can you connect locally? |
| Cloudflare "Bad Gateway" | The gray cloud issue — Minecraft domain must be DNS-only |
| Server stuck on "Installing" | Wings needs internet to download server JARs; check `docker compose logs wings` |
| Panel shows "Node offline" | Run `sudo systemctl status wings` — likely Wings not running |
| Can't upload large mods | PHP upload limits — increase in Panel settings or use SFTP instead |
| Pelican update broke something | Check `/config` for backup, restore from backup |

---

## 15. Estimated Resource Usage

| Component | RAM | Notes |
|-----------|-----|-------|
| Pelican Panel | ~300MB | PHP app, mostly idle |
| Wings daemon | ~100MB | Go binary |
| Docker base | ~200MB | Already running |
| Minecraft (Paper, 4GB limit) | ~2-4GB | Actual usage varies |
| Minecraft (Forge, 6GB limit) | ~4-6GB | Heavier with mods |
| **Total with 1 server** | **~3-5GB** | Plenty of headroom on 24GB |
| **Total with 3 servers** | **~7-12GB** | Still fine |

---

## Verification Checklist

- [ ] Panel accessible at `http://192.168.1.200:9443`
- [ ] Wings connected (green indicator)
- [ ] First server installed and running
- [ ] Minecraft connects locally: `192.168.1.200:25565`
- [ ] Port forwarded on router
- [ ] DNS records created (gray cloud)
- [ ] Friend can connect from outside: `survival.dankofox.quest`
- [ ] Friend can start/stop server from Pelican UI
- [ ] Mods can be uploaded via File Manager
- [ ] Second server created on different port
