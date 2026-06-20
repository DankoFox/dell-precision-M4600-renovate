# SV-02: Homepage Dashboard

**Dashboard**: [gethomepage/homepage](https://github.com/gethomepage/homepage) (30k stars, active)
**RAM**: ~50-80MB
**Port**: 3002
**Auto-discovery**: Docker socket → reads container labels

## Steps

### 1. Create directory

```bash
mkdir -p ~/docker/homepage/config
```

### 2. Create compose.yaml

`~/docker/homepage/compose.yaml`:

```yaml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    ports:
      - 3002:3000
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      PUID: 1000
      PGID: 1000
```

### 3. Create settings.yaml

`~/docker/homepage/config/settings.yaml`:

```yaml
providers:
  docker:
    myServer:
      host: unix:///var/run/docker.sock
      enableAutoDiscovery: true

layout:
  Home:
    - Greeting:
        style: row
        columns: 1
    - Docker:
        style: row
        columns: 4
    - Resources:
        style: row
        columns: 3
```

### 4. Start Homepage

```bash
docker compose -f ~/docker/homepage/compose.yaml up -d
```

Wait a few seconds, then visit http://192.168.1.200:3002 — should show greeting + empty Docker widget.

### 5. Add labels to each service

Homepage auto-discovers containers with `homepage.*` labels. Add these blocks under the `services.<name>:` section of each compose file, then restart each service.

#### Navidrome (`~/docker/navidrome/compose.yaml`)

```yaml
    labels:
      - homepage.group=Media
      - homepage.name=Navidrome
      - homepage.icon=music
      - homepage.href=http://192.168.1.200:4533
      - homepage.description=Music streaming
```

#### Gitea (`~/docker/gitea/compose.yaml`)

```yaml
    labels:
      - homepage.group=Dev
      - homepage.name=Gitea
      - homepage.icon=git
      - homepage.href=http://192.168.1.200:3000
      - homepage.description=Git server
```

#### Pi-hole (`~/docker/pihole/compose.yaml`)

```yaml
    labels:
      - homepage.group=Network
      - homepage.name=Pi-hole
      - homepage.icon=dns
      - homepage.href=http://192.168.1.200:8080/admin
      - homepage.description=DNS blocker
```

#### Syncthing (`~/docker/sync/compose.yaml`)

```yaml
    labels:
      - homepage.group=Sync
      - homepage.name=Syncthing
      - homepage.icon=sync
      - homepage.href=http://192.168.1.200:8384
      - homepage.description=File sync
```

#### Dockge (`~/docker/dockge/compose.yaml`)

```yaml
    labels:
      - homepage.group=Admin
      - homepage.name=Dockge
      - homepage.icon=box
      - homepage.href=http://192.168.1.200:5001
      - homepage.description=Docker compose manager
```

#### Uptime Kuma (`~/docker/uptime-kuma/compose.yaml`)

```yaml
    labels:
      - homepage.group=Monitoring
      - homepage.name=Uptime Kuma
      - homepage.icon=uptime
      - homepage.href=http://192.168.1.200:3001
      - homepage.description=Status monitoring
```

#### Restart each after adding labels

```bash
docker compose -f ~/docker/navidrome/compose.yaml up -d
docker compose -f ~/docker/gitea/compose.yaml up -d
docker compose -f ~/docker/pihole/compose.yaml up -d
docker compose -f ~/docker/sync/compose.yaml up -d
docker compose -f ~/docker/dockge/compose.yaml up -d
docker compose -f ~/docker/uptime-kuma/compose.yaml up -d
```

Homepage picks up changes automatically within ~5 seconds.

### 6. Optional — bookmarks.yaml

`~/docker/homepage/config/bookmarks.yaml` (if you want quick links):

```yaml
Developer:
  - Github:
      - icon: github
        href: https://github.com
  - Cloudflare:
      - icon: cloudflare
        href: https://dash.cloudflare.com
```

### 7. Verification

```bash
curl -sI http://localhost:3002 | head -1
# Expected: HTTP/1.1 200 OK
```

Open http://192.168.1.200:3002 in browser.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Empty Docker widget | Labels not set or container not restarted after adding labels |
| 404 on open | Wait 5-10s for Homepage to boot |
| Permission denied on docker.sock | User `danko` needs to be in `docker` group (already set) |

## Cleanup (if switching from Homer)

```bash
docker compose -f ~/docker/homer/compose.yaml down
docker compose -f ~/docker/homer/compose.yaml rm
# Or just leave it — it's on port 8082, no conflict
```
