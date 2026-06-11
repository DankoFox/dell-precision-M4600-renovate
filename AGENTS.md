# M4600 Home Server — Project Knowledge Base

**Generated:** 2026-06-11 (updated) — Plan analysis complete, next steps prioritized
**Project:** Dell Precision M4600 → Enterprise-Grade Linux Home Lab Server

## OVERVIEW

Repurposing a Dell Precision M4600 (i7-2860QM, 8GB RAM, Quadro 1000M) as a 24/7 headless Linux home server running EndeavourOS (Arch-based). Phased build covering hardware management, containerization, network services, media/self-hosted apps, and automation.

## CRITICAL GAPS

- **Backup**: Data unprotected (music, configs). Use `restic` + cron. Priority #1.
- **Monitoring**: Uptime Kuma deployed but monitors not configured.
- **Security**: No fail2ban. SSH key-only is good, but defense-in-depth missing.

## HARDWARE

| Component | Spec | Status |
|-----------|------|--------|
| CPU | Intel Core i7-2860QM (4C/8T, Sandy Bridge) | Unlocks 4 DIMM slots (max 32GB) |
| RAM | 8GB DDR3 + ZRAM (3.6G compressed swap) | Upgrade target |
| GPU | Quadro 1000M (Fermi) — skipped | Using Intel iGPU VA-API (i965) instead |
| Storage | 120GB SAMSUNG mSATA (OS) + 447GB GIGABYTE SATA (data) | LVM on both |
| Network | Wi-Fi wlp3s0 (eno1 unplugged) | Static IP: 192.168.1.200/24 |

## STORAGE LAYOUT

```
sda (447GB) → vg_data
  ├── lv_storage (200G) → /mnt/media   (Jellyfin, music, media)
  └── data_lv (~247G)   → /mnt/data    (backups, sync, Samba)

sdb (120GB mSATA) → OS only
  ├── sdb1 (1G)  /boot/efi
  ├── sdb2 (2G)  /boot
  └── sdb3 → ubuntu-vg → ubuntu-lv (116G) → /
```

## SOFTWARE INSTALLED

- OS: EndeavourOS (Arch-based, headless, no GUI)
- Docker CE + docker-compose-plugin + containerd.io
- Lazydocker (TUI)
- Dockge (web UI at :5001, compose stacks in ~/docker/)
- Samba (smbd, shares: media + data)
- UFW (SSH + Tailscale allowed, default deny)
- Tailscale (100.101.7.123)
- Pi-hole + Unbound (DNS sinkhole + recursive resolver at :8080/admin, HaGeZi Pro blocklist loaded, 1.6M domains blocked)
- dell-bios-fan-control + i8kmon (fan management)
- smbios-utils (battery charge — unsupported, skipped)
- Navidrome (port 4533, Docker, music streaming from /mnt/media/music)
- Syncthing (port 8384, Docker, host networking, syncs music from PC)
- Tailscale Funnel (public URLs via .ts.net — Navidrome at root via --bg persistent)
- Uptime Kuma (port 3001, Docker, monitoring dashboard)

## PLAN FILES

| File | Purpose |
|------|---------|
| `m4600-server-setup.md` | Master plan, progress tracker, success criteria |
| `phase-01-prep.md` | Physical assessment, BIOS A19, USB creation |
| `phase-02-os-install.md` | Ubuntu 26.04 install |
| `phase-03-linux-fundamentals.md` | Network, SSH, UFW, users, systemd, apt |
| `phase-04-hardware-management.md` | Fan control, WOL, lid management |
| `phase-05-storage-management.md` | LVM, split, Samba, backup |
| `phase-06-containerization.md` | Docker, Compose, Dockge |
| `phase-07-network-services.md` | Pi-hole, WireGuard, Cloudflare, Tailscale |
| `phase-08-media-selfhosted.md` | Jellyfin, Pelican, ARM, Gitea, Navidrome, Sync |
| `phase-09-automation.md` | Ansible, Docker backup, KSM, Smart Card |
| `plan_research.md` | Deep technical research doc |

## PROGRESS (22/41 tasks completed)

- **Phase 1** (3/3): Physical assessment, BIOS A19, USB created
- **Phase 2** (2/2): Ubuntu 26.04 installed, updates done
- **Phase 3** (7/7): Networking, SSH key-only, UFW, users, systemd, apt, monitoring
- **Phase 4** (4/5): Fan control, i8kmon, WOL, lid management. Battery skipped (unsupported)
- **Phase 5** (3/4): LVM setup + split, Samba. Backup (5.3) — not yet done
- **Phase 6** (2/3): Docker CE, Compose plugin, Dockge. Networking deep-dive skipped for now
- **Phase 7** (4/4): Pi-hole + Unbound (DNS sinkhole + recursive resolver) done. Tailscale Funnel live (Navidrome at root via .ts.net, --bg persistent). WireGuard pending.
- **Phase 8** (2/7): Navidrome (port 4533, music streaming) + Syncthing (port 8384 host, syncs music from PC) done. Jellyfin, Pelican, ARM, Gitea, health checks pending.
- **Phase 9** (1/5): Uptime Kuma (port 3001, monitoring dashboard) deployed. Ansible, backup scripts, KSM, Smart Card pending.

## NEXT SESSION PRIORITIES (from plan analysis)

1. **Backup (5.3)** — Data unprotected, use restic + cron, #1 priority
2. **Uptime Kuma monitors (9.3b)** — Configure for all services
3. **Pi-hole router DNS (7.2)** — Fix Pixel bypass, set router DHCP
4. **Gitea (8.4)** — Self-hosted git, ~80MB RAM
5. **Security hardening** — Fail2ban for SSH brute-force protection

## CONVENTIONS

- All commands use `sudo` where needed. User is `danko`.
- Docker Compose files use `compose.yaml` (modern, version tag omitted).
- All service configs stored in `~/docker/<service>/` directory.
- Each service has its own subdirectory with a `compose.yaml`.
- Services added incrementally, monitoring memory (8GB budget).
- No Ubuntu snaps — all packages installed natively.

## KEY COMMANDS

```bash
ssh danko@192.168.1.200
lazydocker                # TUI docker manager
sudo docker compose up -d # Start a compose stack
sudo systemctl status smbd# Check Samba
sudo ufw status verbose   # Check firewall
docker exec pihole pihole -g  # Update gravity (blocklists)
docker exec pihole pihole query <domain>  # Check if domain is blocked
docker exec pihole pihole allow <domain>  # Whitelist a domain
docker exec pihole pihole deny <domain>   # Blacklist a domain
docker exec pihole pihole status          # Check Pi-hole status
docker exec pihole pihole api "stats/summary"  # Query stats
docker exec pihole pihole tail           # Live query log
docker logs navidrome -f      # Tail Navidrome logs
docker compose -f ~/docker/navidrome/compose.yaml up -d  # Start Navidrome
sudo tailscale funnel status  # Check Tailscale Funnel status
sudo tailscale funnel --bg <port>  # Expose a port via Funnel (background)
sudo tailscale serve status   # Check path-based serve routes
sudo tailscale serve --bg --set-path /path http://localhost:PORT # Add path route
docker compose -f ~/docker/uptime-kuma/compose.yaml up -d  # Start Uptime Kuma
docker compose -f ~/docker/sync/compose.yaml up -d  # Start Syncthing
```

## NOTES

- Quadro 1000M Fermi GPU has no 2026 driver support — skipped entirely
- Battery charge thresholds unsupported by this hardware model — skipped
- Ethernet (eno1) shows NO-CARRIER — server runs on Wi-Fi only
- RAM is the primary bottleneck (8GB) — services must be mindful
- Optical bay caddy is a future upgrade path for more storage

## HARDWARE UPGRADES (Recommended)

| Upgrade | Why | Cost | Priority |
|---------|-----|------|----------|
| RAM → 16-32GB | 8GB is bottleneck. DDR3 cheap ($20-40). Enables Ollama, more containers. | $20-40 | HIGH |
| Ethernet cable | eno1 exists but NO-CARRIER. $5 for reliable gigabit. | $5 | HIGH |
| 2.5GbE ExpressCard | ExpressCard/54 slot. ~$25 for 2.5GbE adapter. | $25 | MEDIUM |
| USB UPS | 24/7 server needs power protection. Used UPS with USB monitoring. | $30-50 | MEDIUM |

## SOFTWARE ADDITIONS (Recommended)

| Service | RAM | Why |
|---------|-----|-----|
| Gitea | ~80MB | Self-hosted git server |
| Fail2ban | ~10MB | SSH brute-force protection |
| Homer Dashboard | ~5MB | Single-page dashboard for all services |
| Nginx Proxy Manager | ~50MB | Reverse proxy with auto-SSL |

**Skip for now**: Ollama (needs 16GB+), Immich (needs 8GB+ free), Nextcloud (Syncthing covers sync)
