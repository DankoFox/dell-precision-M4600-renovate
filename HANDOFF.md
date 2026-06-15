# Handoff — M4600 Home Server

**Date:** 2026-06-12 (v2)
**Server:** danko@192.168.1.200
**User:** danko (in docker + sudo groups)
**Refer to:** [AGENTS.md](AGENTS.md) for full KB, [m4600-server-setup.md](m4600-server-setup.md) for plan index

---

## 1. Last Session

**Date:** 2026-06-15
**Summary:** Ethernet (eno1) connected and configured as primary interface. Netplan dual-interface setup with metric-based failover.

**Completed this session:**
- Connected Ethernet cable to eno1
- Configured netplan: eno1 (static 192.168.1.200/24, metric 100) + wlp3s0 (DHCP backup, metric 600)
- Resolved conflicting default route error using `dhcp4-overrides: route-metric`
- Diagnosed SSH delay (was router issue, not SSH config)
- Updated AGENTS.md with Ethernet status

**Key decisions:**
- Ethernet = primary (metric 100), Wi-Fi = automatic failover (metric 600)
- Both interfaces active simultaneously for seamless failover
- No manual intervention needed if Ethernet cable unplugged — traffic fails over to Wi-Fi

**Previous session (2026-06-12):**

**Completed this session (morning):**
- SC-02: ufw-docker installed, DOCKER-USER chain rules active, navidrome/uptime-kuma/dockge ports behind UFW, Pi-hole host-network ports managed by UFW directly
- NW-03: Stale DHCP lease (192.168.1.10) removed
- MT-05: Docker daemon.json log rotation (10m max-size, 3 max-file)
- MT-01/02/03/SV-05: Marked done in files (completed in previous session)

---

## 1b. This Session — RAM Upgrade (24GB)

**Date:** 2026-06-20
**Summary:** Added 2× 8GB Inmos DDR3-1600 SODIMMs. Total RAM: 8GB → 24GB (4+8 per channel). Unlocked earlier deferred services (Ollama, Immich, KSM now feasible).

**Completed:**
- Installed Inmos BRAN51288G16C1600 (8GB) in ChannelA-DIMM1 + Inmos BRAN51288G16C1600L (8GB) in ChannelB-DIMM1
- Verified via dmidecode + lshw — all 4 slots populated, 24GB total, 1600 MT/s
- Updated AGENTS.md + HANDOFF.md with new specs

**Key decisions:**
- Mixed config (4+8 per channel) works — dual-channel still active since matching pairs per channel
- HW-01 RAM upgrade now DONE
- Medium-value services (Vaultwarden, Watchtower, Calibre-web) now feasible
- Ollama/Immich reconsideration possible — still heavy but no longer blocked by RAM

---

## 1c. This Session — Gitea Deployed

**Date:** 2026-06-14
**Summary:** SV-01: Gitea deployed and running at :3000, accessible at https://git.dankofox.quest via Cloudflare tunnel. SQLite backend, resource limits (256M/128M reservation/0.5 CPU), health check configured. CF tunnel multi-ingress extended to route git.dankofox.quest → localhost:3000.

**Completed:**
- Researched Gitea Docker: SQLite best for single-user on 8GB (~80MB RAM vs 150MB+ with PostgreSQL)
- Researched Cloudflare tunnel multi-ingress: single tunnel supports multiple hostnames in config.yml
- Wrote `sv-01-gitea-setup.sh` — complete deploy script (compose, start, tunnel update, DNS, verification)
- Deployed Gitea container at ~/docker/gitea/ with compose.yaml
- Updated cloudflared config.yml for multi-hostname ingress (git.dankofox.quest → :3000)
- DNS A/AAAA records (grey cloud) for git.dankofox.quest → 192.168.1.200
- Verified: Gitea accessible at https://git.dankofox.quest, ~80MB RAM, container healthy

**Key decisions:**
- SQLite over PostgreSQL — saves ~100MB RAM, simpler deployment, sufficient for single-user
- HTTPS-only (no SSH passthrough) — avoids SSH port-forwarding complexity on Wi-Fi-only server
- Port 3000 bound to localhost only — not exposed to LAN; tunnel-only access
- Reuses existing CF tunnel (navidrome-tunnel) with new ingress rule — single tunnel, one systemd service

---

## 1c. This Session — Reverse Proxy Experiments + Cloudflare Tunnel

**Date:** 2026-06-12 (evening — extended)
**Summary:** Diagnosed Caddy path rewriting limitations. Tested Traefik v3 (same issue). Tried Nginx with proxy_redirect + sub_filter (config bugs). Abandoned all reverse proxies. Bought domain dankofox.quest, set up Cloudflare tunnel for Navidrome public access. Services back on direct ports.

**Diagnosis:**
- Root cause: Caddy `handle_path` strips request prefix but doesn't rewrite response `Location` headers or HTML body paths. SPA apps like Kuma/Dockge break because their internal routes don't know about the subpath prefix.
- Traefik `stripPrefix` middleware — confirmed same limitation (no response body rewriting)
- Nginx `proxy_redirect` + `sub_filter` — correct approach, but had config bugs (ND_BASEURL missing leading slash, Kuma missing sub_filter directive)

**Completed:**
- Diagnosed reverse proxy path-rewriting issue across Caddy, Traefik, Nginx
- Traefik v3 tested with stripPrefix — confirmed insufficient for subpath-based SPA routing
- Nginx configured with proxy_redirect + sub_filter — abandoned due to config bugs
- Bought domain **dankofox.quest** at Cloudflare
- Created Cloudflare tunnel (`navidrome-tunnel`): music.dankofox.quest → http://localhost:4533
- Cloudflared installed as systemd service, running
- Navidrome public at https://music.dankofox.quest
- All reverse proxies stopped and removed; services on direct ports

**Key decisions:**
- Cloudflare tunnel chosen over port forwarding — no router config needed, DDoS protection, free HTTPS
- Domain dankofox.quest managed at Cloudflare DNS (orange cloud for tunnel, grey cloud for direct DNS records to 192.168.1.200)
- No reverse proxy currently — Kuma and Dockge accessible only via LAN on direct ports (:3001, :5001)
- Caddy/Traefik/Nginx all abandoned for now. Path-based SPA proxying needs both response header + body rewriting, which adds complexity
- Key lesson: subpath-unaware SPA apps need proxy_redirect (headers) + sub_filter (body). Caddy and Traefik lack body rewriting

---

## 2. Session Log

| Date | Summary | Key Decisions | State Change |
|------|---------|---------------|--------------|
| 2026-06-20 | RAM upgrade: 8→24GB (2× Inmos 8GB added) | 4+8 per channel, dual-channel active. Ollama/Immich now feasible. HW-01 done. | 24GB — RAM bottleneck resolved |
| 2026-06-14 | Gitea deployed (SV-01) | Deployed Gitea at :3000, SQLite, health checks, resource limits. CF tunnel multi-ingress: git.dankofox.quest → :3000. Running. | SV-01 done |
| 2026-06-14 | Gitea deployment plan (SV-01) | Researched Gitea Docker + SQLite. Wrote `sv-01-gitea-setup.sh` with compose, CF tunnel multi-hostname config, resource limits. Deploy-ready. | SV-01 plan done |
| 2026-06-12 | Docker UFW bypass fixed | ufw-docker installed; container ports now behind UFW | SC-02 done |
| 2026-06-12 | Container health checks (MT-06) | Navidrome, Syncthing, Unbound got explicit healthchecks. Pi-hole + Uptime Kuma use built-in. All 6 containers healthy. | MT-06 done |
| 2026-06-11 | Security hardening + docs | fail2ban, journald, unattended-upgrades, SMART, swap confirmed; HW research | 5 tasks done |
| 2026-06-11 | Documentation refactor | AGENTS.md/HANDOFF.md/m4600-setup.md restructured; unified task IDs created | Docs cleaned |
| 2026-06-11 (earlier) | Uptime Kuma deployed at :3001 | Kept internal (no Funnel) | New service: Uptime Kuma |
| 2026-06-11 (earlier) | Syncthing deployed, host networking | Receive Only for music sync from PC | New service: Syncthing |
| 2026-06-11 (earlier) | Navidrome deployed at :4533 | Funnel at root path via `--bg` | New service: Navidrome |
| 2026-06-11 (earlier) | Tailscale Funnel set up | Root path for Navidrome, no auth | Public access |
| 2026-06-11 (earlier) | Dockge path fixed | Scans ~/docker/ correctly | Fix |

---

## 3. Current State

### ✅ Working
- Ethernet (eno1) active: static 192.168.1.200/24, primary interface
- Wi-Fi (wlp3s0) backup: DHCP with metric 600, automatic failover
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
- UFW: SSH, Tailscale, Samba, Pi-hole (53, 8080), Kuma (3001), Dockge (5001), Navidrome (4533) ports open
- Fan management: dell-bios-fan-control + i8kmon
- Caddy removed (reverse proxy experiment concluded — handle_path limitation)
- Navidrome at port 4533 (music streaming, reads /mnt/media/music) — direct port, no reverse proxy
  - Public via Cloudflare tunnel at https://music.dankofox.quest (cloudflared → localhost:4533)
  - Tunnel ID: 06851969-a611-44bb-a271-b7387cb7f957, name: navidrome-tunnel
  - Cloudflared runs as systemd service
- Syncthing at port 8384 (host networking, syncs music from PC to /mnt/media/music, Receive Only)
- Tailscale Funnel still available for internal access (but currently unused since Caddy removed)
- Uptime Kuma at port 3001 (direct port, LAN only) — accessible at http://192.168.1.200:3001
- Dockge at port 5001 (direct port, LAN only)
- Gitea deployed at `~/docker/gitea/` (running on :3000, accessible at https://git.dankofox.quest via CF tunnel)
- Domain dankofox.quest managed at Cloudflare DNS (orange cloud for CF tunnel, grey cloud for direct DNS)

### ❌ Not Working / Issues
- **Phone (Pixel) DNS bypass** — Router DNS set to Pi-hole, but Pixel Private DNS (DoT) may still bypass. Verify and test.
- Pi-hole network table still shows stale 172.19.0.x entries from old Docker bridge mode (harmless).

---

## 4. Stack on Disk

All in `~/docker/<service>/` with `compose.yaml`:

| Directory | Service | Port |
|-----------|---------|------|
| `~/docker/pihole/` | Pi-hole + Unbound | 53, 8080 |
| `~/docker/navidrome/` | Navidrome (music) | 4533 |
| `~/docker/caddy/` | Caddy — removed | — |
| `~/docker/sync/` | Syncthing (file sync) | 8384 host |
| `~/docker/uptime-kuma/` | Uptime Kuma (monitoring) | 3001 |
| `~/docker/gitea/` | Gitea (git server) | 3000 (deploy-ready) |

**System configs:**
| File | Service |
|------|---------|
| `/etc/netplan/01-netcfg.yaml` | Network (Ethernet primary + Wi-Fi backup) |
| `/etc/samba/smb.conf` | Samba shares |
| `/etc/cloudflared/` | Cloudflare tunnel |

---

## 5. Pending Tasks

| Priority | ID | Description | Phase | Depends On |
|----------|----|-------------|-------|------------|
| 🔴 Critical | **BK-01** | Set up restic + cron backup (data unprotected, #1 priority) | 5.3 | — |
| 🔴 Critical | ~~**SC-02**~~ | ~~Fix Docker UFW bypass (container ports exposed past firewall)~~ | — | — | ✅
| 🟡 High | ~~**SV-01**~~ | ~~Deploy Gitea (~80MB RAM) — deployed at :3000, git.dankofox.quest~~ | 8.4 | Docker ready | ✅
| 🟡 High | **MT-04** | Add Docker resource limits to all compose.yaml | — | — |
| 🟡 High | **BK-03** | Backup verification + restore testing (restic check) | 5.4 | BK-01 |
| 🟡 High | ~~**SV-04**~~ | ~~Caddy reverse proxy — tested, then removed. Replaced by Cloudflare tunnel + domain~~ | 8.7 | BK-01, BK-02 | ✅
| 🟢 Medium | **NW-04** | Cloudflare tunnel + domain dankofox.quest (Navidrome public at music.dankofox.quest) | 8.9 | — | ✅
| 🟡 High | ~~**MT-05**~~ | ~~Docker log rotation per container~~ | — | — | ✅
| 🟡 High | ~~**MT-06**~~ | ~~Container health checks in compose~~ | — | — | ✅
| 🟢 Medium | **SV-02** | Deploy Homer dashboard (~5MB) | — | BK-01, BK-02 |
| 🟢 Medium | **NW-02** | IPv6 DNS config (fix Pixel DoT) | — | NW-01 |
| 🟢 Medium | **AU-01** | Ansible config management | 9.1 | — |
| 🟢 Medium | **AU-02** | Docker volume backup script | 9.2 | BK-01 |
| 🟢 Medium | **SV-03** | Deploy Diun (Docker update notifier) | — | — |
| 🟢 Medium | **BK-04** | Offsite backup (Backblaze B2 / rsync.net) | 5.5 | BK-01 |
| 🟢 Medium | ~~**NW-03**~~ | ~~Release DHCP lease (keep static IP only)~~ | 7.3 | — | ✅
| 🟢 Medium | **MT-07** | Docker image pinning (digest) | — | — |
| ⚪ Hardware | ~~**HW-01**~~ | ~~RAM upgrade 16-32GB~~ — DONE (24GB: 4+8 per channel) | — | Purchase | ✅
| ⚪ Hardware | **HW-02** | Ethernet cable Cat 6 | — | Purchase |
| ⚪ Hardware | **HW-03** | Wi-Fi card Intel AC 7260HMW | — | Purchase |
| ⚪ Deferred | HW-04 | Thermal paste (Arctic MX-4) | — | Purchase |
| ⚪ Deferred | HW-05 | Optical bay caddy + 1TB SSD (see §8 Storage Reorg Backlog) | — | Purchase |
| ⚪ Deferred | HW-06 | UPS (APC) | — | Purchase |

---

## 6. Decision Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-11 | Skipped Jellyfin | Sandy Bridge iGPU too weak for HEVC/4K (H.264 only) | Consider Intel Arc A310 for transcoding |
| 2026-06-11 | Skipped Cloudflare Tunnel (initial) | No domain at the time; Tailscale Funnel used instead | Replaced by CF tunnel after domain purchase |
| 2026-06-12 | Bought domain dankofox.quest | Needed public HTTPS URLs without port numbers | Tailscale Funnel, port forwarding |
| 2026-06-12 | Cloudflare tunnel for Navidrome public access | No router config needed, DDoS protection, free HTTPS, custom domain | Direct port forwarding, Tailscale Funnel |
| 2026-06-12 | Abandoned reverse proxy (Caddy/Traefik/Nginx) | SPA apps need response header + body rewriting for subpath routing. Caddy handle_path no body rewrite. Traefik same. Nginx sub_filter viable but configs had bugs. | Keep reverse proxy with fixed config |
| 2026-06-14 | Gitea SQLite over PostgreSQL | Saves ~100MB RAM, simpler deployment, sufficient for single-user git on 8GB server | PostgreSQL (conventional) |
| 2026-06-14 | Gitea HTTPS-only via CF tunnel (no SSH passthrough) | Avoids SSH port-forwarding complexity on Wi-Fi-only server; git clone works over HTTPS with PAT | SSH passthrough on port 2222 |
| 2026-06-14 | Reuse existing navidrome-tunnel for Gitea ingress | Single cloudflared systemd service handles multiple hostnames; fewer tunnels = less complexity | Separate tunnel per service |
| 2026-06-15 | Ethernet as primary interface | eno1 now active with static 192.168.1.200/24; Wi-Fi wlp3s0 as automatic failover (metric 600) | Keep Wi-Fi only, use both with same metric |
| 2026-06-11 | Uptime Kuma stays internal | Monitoring dashboard doesn't need public access | Could use Tailscale Funnel |
| 2026-06-11 | Pi-hole not on Funnel | Reverted during serve experiment | — |
| 2026-06-11 | Docs: AGENTS.md = KB, HANDOFF.md = session | Non-overlapping roles for clarity | Single giant file (messy) |
| 2026-06-11 | Gap audit — 9 new task IDs added | Identified: Docker UFW bypass (🔴), missing backups verify, no reverse proxy, no swap, no log rotation, no health checks, no image pinning, no DHCP cleanup | — |
| 2026-06-11 | BK-02 done — Uptime Kuma monitors configured | NW-01 done — Router DNS set to Pi-hole | Out of band (user did directly) |
| 2026-06-11 | Hardware upgrade guide rewritten with market research | Added CPU, GPU, ExpressCard, cooling pad sections. Updated SSD, RAM, Wi-Fi, USB 2.5GbE pricing. Priority matrix included. Sources: Shopee, Chợ Tốt, MemoryZone, GEARVN, Econnect, etc. | — |

---

## 7. Constraints

- 24GB RAM (upgraded 2026-06-20: 4GB+8GB per channel, Inmos DDR3-1600) — RAM bottleneck mostly resolved
- Quadro 1000M Fermi GPU: no 2026 drivers, skip entirely
- Ethernet (eno1) **ACTIVE** — primary interface, static 192.168.1.200/24
- Wi-Fi (wlp3s0) — backup/failover only, DHCP with metric 600
- Battery charge thresholds unsupported — skipped, monitor for swelling
- Static IP only: 192.168.1.200/24 (DHCP lease released)
- No Ubuntu snaps — all packages via apt
- No Ubuntu Pro
- Host runs Ubuntu Server 26.04 LTS (headless)

---

## 8. Storage Reorg Backlog — Caddy + SSD (+ HDD repurpose)

**Trigger**: Buy optical bay caddy + 2nd SSD (HW-05). Once hardware in hand.

**End goal (Option C)**:
- Install SSD in optical bay (`/dev/sdc`)
- Migrate all data from sda HDD → sdc SSD
- Remove HDD from vg_data
- Repurpose HDD as backup disk (restic target)

### Step-by-step (when ready)

1. **Buy**: 9.5mm SATA caddy (~80-200k VND) + 1TB SATA SSD (Crucial BX500 ~1.5M VND best value)
   - SATA 2 speed limit (3Gbps ~300MB/s) — SSD still 5-10x faster than HDD for random I/O
2. **Install**: Swap optical drive for caddy, screw SSD into caddy, transfer bezel + bracket
3. **Initial setup**: `lsblk` to confirm `/dev/sdc`, `sudo fdisk -l` to verify
4. **Partition + format**: GPT partition table, ext4 filesystem
5. **Add to LVM**: `sudo pvcreate /dev/sdc1`, `sudo vgextend vg_data /dev/sdc1`
6. **Migrate HDD data to SSD**:
   - `sudo pvmove /dev/sda` — moves all extents off sda to sdc
   - `sudo vgreduce vg_data /dev/sda`
   - `sudo pvremove /dev/sda`
7. **Repurpose HDD as backup drive**:
   - Format as ext4, mount as `/mnt/backup` (fstab)
   - Init restic repo: `restic init --repo /mnt/backup/restic-repo`
   - Daily cron: `restic backup /mnt/data /mnt/media --exclude="music/"`
8. **Verify**: `sudo lvs`, `df -h`, restic check, test restore

### Notes
- SATA 2 caps sequential at ~300MB/s — fine for overnight backup, migrate can run while sleeping
- If HDD has SMART reallocated sectors > 10, skip repurpose, buy fresh drive
- Alternatives: Option A (dedicated backup disk), Option B (extend vg_data mixed HDD+SSD) documented in session log

---

## 9. Network Configuration Reference

### Netplan Config (for reference)
Saved at: `netplan-01-netcfg.yaml` in project root

**Applied on server at:** `/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: NetworkManager

  ethernets:
    eno1:
      optional: true
      dhcp4: no
      addresses:
        - 192.168.1.200/24
      routes:
        - to: default
          via: 192.168.1.1
          metric: 100          # Lower = higher priority
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8

  wifis:
    wlp3s0:
      optional: true
      dhcp4: yes
      dhcp4-overrides:
        route-metric: 600      # Higher = lower priority (backup only)
      access-points:
        "Bin":
          password: "12345678"
```

**Key points:**
- `metric: 100` on eno1 = Ethernet always preferred
- `route-metric: 600` on wlp3s0 = Wi-Fi only used if Ethernet fails
- Both interfaces active simultaneously for seamless failover
- `dhcp4-overrides: route-metric` is the official netplan way to set DHCP route priority
