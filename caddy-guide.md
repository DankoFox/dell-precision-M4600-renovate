# Caddy Reverse Proxy — Deployment Guide

> **For:** M4600 Home Server  
> **Date:** 2026-06-12  
> **Config:** `~/docker/caddy/` (compose.yaml + Caddyfile)

---

## 1. Architecture

```
Internet ──Tailscale Funnel :443──→ Caddy :8081
                                      ├── /            → Navidrome :4533 (public)
                                      ├── /kuma/*      → Uptime Kuma :3001 (internal)
                                      ├── /dockge/*    → Dockge :5001 (internal)
                                      └── Pi-hole at :8080/admin (direct, not through Caddy)
```

**Key decisions:**
- Caddy uses `network_mode: host` — reaches all services via `127.0.0.1:PORT`. No need to modify other compose files.
- Navidrome sits at **root** `/` (no path prefix). Avoids ND_BASEURL, redirect loops, path stripping issues.
- Pi-hole stays **direct** on port 8080 — its admin UI lives at `/admin/` which creates path rewrite complexity through Caddy.

---

## 2. Files

### `compose.yaml`

```yaml
services:
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data:/data
      - ./config:/config
```

### `Caddyfile`

```caddyfile
:8081 {
    # Service A: internal only
    handle_path /service-a/* {
        @blocked {
            not remote_ip 192.168.1.0/24 100.0.0.0/8 127.0.0.0/8
        }
        handle @blocked {
            respond "Internal only" 403
        }
        reverse_proxy 127.0.0.1:3000
    }

    # Catch-all: Navidrome at root (public)
    reverse_proxy 127.0.0.1:4533
}
```

---

## 3. Adding a new service

1. Add a `handle_path /new-service/* { ... }` block BEFORE the catch-all
2. If the service needs to be internal-only, add the `@blocked` IP restriction
3. Reload: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
4. Access at: `https://danko-m4600.tail81e74b.ts.net/new-service/`

### Rules for handle vs handle_path

| Directive | Path sent to backend | Use when |
|-----------|---------------------|----------|
| `handle /prefix/*` | Full path preserved (e.g., `/prefix/resource`) | Backend knows about the prefix |
| `handle_path /prefix/*` | Prefix stripped (e.g., `/resource`) | Backend expects root-relative paths |

**For most services:** use `handle_path /prefix/*` with `reverse_proxy 127.0.0.1:PORT`.
**Exception:** Navidrome uses bare `reverse_proxy` (catch-all) — no prefix needed.

---

## 4. Changing Tailscale Funnel

If you need to point Funnel at a different port:

```bash
# Stop current funnel
tailscale funnel reset

# Start new funnel (foreground for testing)
tailscale funnel 127.0.0.1:8081

# Start new funnel (background for production)
tailscale funnel --bg --set-path=/ 127.0.0.1:8081
```

---

## 5. Pitfalls to avoid

### 5.1 Don't scp to replace Caddyfile — edit in-place

`scp` creates a new file with a different inode. Docker's bind mount follows the **old** inode. Changes won't take effect even after `caddy reload`.

**Do:** Edit the file directly on the server (`nano`, `sed -i`).

**If you must scp:** After copying, run `docker compose -f ~/docker/caddy/compose.yaml restart` (recreates the mount from scratch).

### 5.2 Don't force Navidrome behind a path prefix

Navidrome's SPA handles its own internal routing at `/app/`. If you put it behind a prefix like `/navidrome/`, you'll need:
- `ND_BASEURL=/navidrome` in compose env
- Caddy must NOT strip the prefix (`handle /navidrome/*` not `handle_path`)
- Even then, Navidrome's redirect to `/app/` creates a `/navidrome/app/` path

**Simpler:** Leave Navidrome at root `/`. No special config needed.

### 5.3 Pi-hole doesn't route well through Caddy

Pi-hole's web UI lives at `/admin/`. To route it through Caddy you'd need:
- A `/pihole/*` → `/admin/*` rewrite
- Plus handle blocks for all the paths Pi-hole redirects to (`/admin/`, `/admin/login/`, etc.)
- Or a catch-all that catches Pi-hole's redirect targets

**Simpler:** Access Pi-hole directly at `http://192.168.1.200:8080/admin/` or via Tailscale IP. No Caddy routing needed.

### 5.4 Watch out for Caddy directive ordering

Caddy evaluates handlers in this order:
1. `handle` / `handle_path` blocks (highest priority)
2. `reverse_proxy` (lower priority)

So `handle` blocks match first, and bare `reverse_proxy` acts as catch-all for everything else.  
**Don't rely on file position** for different directive types — Caddy reorders them internally.

### 5.5 Test with GET, not HEAD

`curl -I` sends HEAD requests. Some apps (Navidrome) reject HEAD with 405. Always use `curl` (GET) to test.

---

## 6. Useful commands

```bash
# Reload Caddy config (zero-downtime)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# View logs
docker logs caddy -f --tail 50

# Restart from scratch (new inode for mounted file)
docker compose -f ~/docker/caddy/compose.yaml restart

# Test routing
curl -L http://127.0.0.1:8081/              # Navidrome
curl http://127.0.0.1:8081/kuma/            # Kuma
curl http://127.0.0.1:8081/dockge/          # Dockge
curl -I http://127.0.0.1:8080/admin/        # Pi-hole (direct)

# Check Tailscale funnel status
tailscale funnel status
```
