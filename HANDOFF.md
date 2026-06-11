# Handoff — M4600 Home Server

**Date:** 2026-06-11 (updated)
**Server:** danko@192.168.1.200
**User:** danko (in docker group, no sudo password needed for docker)

---

## LAST SESSION SUMMARY

This session covered:
- **Tailscale Funnel** set up for Navidrome (root at .ts.net)
- **Navidrome** deployed, Docker Compose, admin created, music synced
- **Syncthing** deployed (Docker, host networking), syncs music from PC to /mnt/media/music (Receive Only)
- **Uptime Kuma** deployed at port 3001 (monitors not yet configured)
- **Dockge** path fixed — now correctly scans /home/danko/docker/
- **Tailscale Serve** tried for path-based routing (Navidrome + Pi-hole + Uptime Kuma under one Funnel) but reverted — single-service Funnel simpler for now
- Rsync used to copy music from PC (192.168.1.14) to server
- Git history cleaned: 5 commits with full attribution

### Decisions Made
- Skipped Jellyfin — Sandy Bridge iGPU too weak for HEVC/4K (H.264 only)
- Skipped Cloudflare Tunnel — no domain; Tailscale Funnel fills the need
- Uptime Kuma stays internal (no Funnel) — monitoring dashboard doesn't need public access
- Pi-hole not on Funnel — reverted during serve experiment

---

## CURRENT STATE

### Working
- LVM: vg_data with lv_storage (200G, /mnt/media) + data_lv (247G, /mnt/data)
- Samba: [media] and [data] shares at /mnt/media and /mnt/data
- Docker CE + docker-compose-plugin + containerd.io
- Lazydocker (TUI)
- Dockge at :5001 (compose stacks in ~/docker/)
- Tailscale at 100.101.7.123
- Pi-hole + Unbound (DNS sinkhole + recursive resolver, :8080/admin)
  - `network_mode: host` (both containers share host netns)
  - HaGeZi Pro blocklist loaded (1.6M domains blocked)
  - Unbound on port 5335, Pi-hole forwards to 127.0.0.1#5335
  - Working: queries from LAN PCs resolve, DNS blocks active
  - Pi-hole v6 CLI uses subcommands, not `-a` flags
- UFW: SSH, Tailscale, Samba, Pi-hole (53, 8080) ports open
- Fan management: dell-bios-fan-control + i8kmon
- Navidrome at port 4533 (music streaming, reads /mnt/media/music)
- Syncthing at port 8384 (host networking, syncs music from PC to /mnt/media/music, Receive Only)
- Tailscale Funnel exposing Navidrome at https://danko-m4600.tail81e74b.ts.net/ (--bg persistent on port 4533, root path)
  - Pi-hole Funnel was removed during serve experiment — currently local-only at :8080/admin
- Uptime Kuma at port 3001 (monitoring dashboard)

### Not Working / Issues
- **Phone (Pixel) DNS bypass** — Private DNS (DoT) + IPv6 causes Pixel to bypass Pi-hole. Known issue, needs router-level DNS config or UFW rule to force all DNS through Pi-hole.
- **Viettel router DNS not set** — Router DHCP still uses ISP DNS. Needs ISP DNS turned OFF, Primary DNS set to 192.168.1.200.
- Pi-hole network table still shows stale 172.19.0.x entries from old Docker bridge mode (harmless).

---

## STACKS ON DISK

All in `~/docker/<service>/` with `compose.yaml`:

| Directory | Service |
|-----------|---------|
| `~/docker/pihole/` | Pi-hole + Unbound |
| `~/docker/navidrome/` | Navidrome (port 4533) |
| `~/docker/sync/` | Syncthing (port 8384 host) |
| `~/docker/uptime-kuma/` | Uptime Kuma (port 3001) |

---

## PI-HOLE DETAILS

**Compose:** Uses `network_mode: host`, not bridge.
**Key environment:**
- `FTLCONF_webserver_port: "8080o"` — keeps admin on :8080 despite host networking
- `FTLCONF_dns_upstreams: "127.0.0.1#5335"` — points to Unbound
- `FTLCONF_dns_listeningMode: "all"`

**Unbound config:** `~/docker/pihole/unbound/` mounted to `/etc/unbound/custom.conf.d/` (drop-in style). Listens on port 5335.

**Adding blocklists:** Use dashboard at /admin or API. Old `pihole -a adlist` removed in v6.

---

## PENDING TASKS

### Phase 5
- [ ] 5.3 Backup strategy (rsync + cron) — deferred

### Next Session Priorities (recommended order)
1. **Backup (5.3)** — music data unprotected, quick rsync cron
2. **Configure Uptime Kuma** — add monitors for all services
3. **Pi-hole router DNS (7.1)** — stop Pixel bypassing DNS, set router DHCP
4. **Gitea (8.4)** — self-hosted git, ~80MB RAM, useful for dotfiles
5. **WireGuard (7.2)** — backup VPN independent of Tailscale

### Phase 5
- [ ] 5.3 Backup strategy (rsync + cron) — music data now on server, no protection

### Phase 7
- [ ] 7.1 Pi-hole: set router DHCP DNS to 192.168.1.200 + fix Pixel IPv6/DoT bypass
- [ ] 7.2 WireGuard VPN — native VPN for remote access
- [ ] 7.3 Cloudflare Tunnel — zero-open-ports remote access (requires domain)
- [x] 7.4 Tailscale Funnel (Navidrome at root via .ts.net, --bg persistent)

### Phase 8
- [ ] 8.1 Jellyfin — on hold (Sandy Bridge too weak for HEVC)
- [ ] 8.2 Pelican (Minecraft) — containerized game server
- [ ] 8.3 ARM — Automatic Ripping Machine (CD ripping)
- [ ] 8.4 Gitea — self-hosted git server
- [x] 8.5 Navidrome — music streaming (Subsonic API, port 4533)
- [x] 8.6 Syncthing — file sync (port 8384 host, syncs music, Receive Only)
- [ ] 8.6b CouchDB — pending
- [ ] 8.7 Health checks + optional services

### Phase 9
- [ ] 9.1 Ansible — configuration management
- [ ] 9.2 Docker backup scripts
- [x] 9.3 Uptime Kuma (port 3001, monitoring dashboard) deployed
- [ ] 9.3b Configure Uptime Kuma monitors (Pi-hole, Navidrome, Syncthing, SSH, DNS)
- [ ] 9.4 KSM (Kernel Same-page Merging)
- [ ] 9.5 Smart Card support

---

## NAVIDROME DETAILS

**Compose:** `~/docker/navidrome/compose.yaml`, bridge networking, `user: 1000:1000`.
**Port:** 4533 → 4533
**Music path:** `/mnt/media/music` mounted as `/music:ro` in container.
**Config:** Environment variables set via compose (no config file). `ND_SCANSCHEDULE` can be added for auto-scan.
**Funnel:** `sudo tailscale funnel --bg 4533` — accessible at `https://danko-m4600.tail81e74b.ts.net/`
**Restart:** `docker restart navidrome` forces a rescan.
**Logs:** `docker logs navidrome -f --tail 30`

---

## SYNCTHING DETAILS

**Compose:** `~/docker/sync/compose.yaml`, `network_mode: host`, `user: 1000:1000`.
**Web UI:** `http://192.168.1.200:8384`
**Music folder:** Container path `/media/music` (host `/mnt/media/music`), set to **Receive Only**.
**Additional folders:** Mount at `/media` for `/mnt/media/*` or `/data` for `/mnt/data/*`.
**Config dir:** `~/docker/sync/data/`
**Across internet:** Works out of the box — global discovery + relay servers, no VPN needed.

---

## TAILSCALE FUNNEL / SERVE NOTES

- `sudo tailscale funnel --bg <port>` — expose a port publicly
- `sudo tailscale funnel status` — check active funnels
- `sudo tailscale serve status` — check path-based routes
- `sudo tailscale serve --bg --set-path /path http://127.0.0.1:PORT` — add path route
- `sudo tailscale serve --https=443 /path off` — remove a path
- `sudo tailscale funnel 8080 off` — remove a funnel
- Funnel is per-port, not per-path. Path-based routing via `serve` (but Funnel makes ALL paths public)
- Multiple `--bg` funnels can run simultaneously on different ports

---

## CONSTRAINTS

- 8GB RAM primary bottleneck — add services incrementally
- Quadro 1000M Fermi GPU: no 2026 drivers, skip entirely
- Ethernet (eno1) shows NO-CARRIER — Wi-Fi (wlp3s0) only
- Battery charge thresholds unsupported — skipped, monitor for swelling
- Two IPs on wlp3s0: static 192.168.1.200 + DHCP 192.168.1.7 (DHCP lease can be released)
- No Ubuntu snaps — all packages via apt
- No Ubuntu Pro
- Host runs EndeavourOS (Arch-based), not Ubuntu Server
