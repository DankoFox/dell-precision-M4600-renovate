# Handoff — M4600 Home Server

**Date:** 2026-06-11
**Server:** danko@192.168.1.200
**User:** danko (in docker group, no sudo password needed for docker)

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
- Tailscale Funnel exposing Pi-hole at https://danko-m4600.tail81e74b.ts.net/admin and Navidrome at https://danko-m4600.tail81e74b.ts.net/

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

### Phase 7
- [ ] 7.1 Pi-hole: set router DHCP DNS to 192.168.1.200 + fix Pixel IPv6/DoT bypass
- [ ] 7.2 WireGuard VPN — native VPN for remote access
- [ ] 7.3 Cloudflare Tunnel — zero-open-ports remote access
- [x] 7.4 Tailscale Funnel live (Pi-hole at /admin, Navidrome at root via .ts.net)

### Phase 8
- [ ] 8.1 Jellyfin — media server (VA-API via i965 Intel iGPU)
- [ ] 8.2 Pelican (Minecraft) — containerized game server
- [ ] 8.3 ARM — Automatic Ripping Machine (CD ripping)
- [ ] 8.4 Gitea — self-hosted git server
- [x] 8.5 Navidrome — music streaming (Subsonic API, port 4533)
- [x] 8.6 Syncthing — file sync (port 8384 host, syncs music)
- [ ] 8.6b CouchDB — pending
- [ ] 8.7 Health checks + optional services

### Phase 9
- [ ] 9.1 Ansible — configuration management
- [ ] 9.2 Docker backup scripts
- [ ] 9.3 Uptime Kuma or similar monitoring
- [ ] 9.4 KSM (Kernel Same-page Merging)
- [ ] 9.5 Smart Card support

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
