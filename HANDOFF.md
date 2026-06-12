# Handoff — M4600 Home Server

**Date:** 2026-06-12 (v2)
**Server:** danko@192.168.1.200
**User:** danko (in docker + sudo groups)
**Refer to:** [AGENTS.md](AGENTS.md) for full KB, [m4600-server-setup.md](m4600-server-setup.md) for plan index

---

## 1. Last Session

**Date:** 2026-06-12
**Summary:** Docker UFW bypass fixed via ufw-docker. DHCP lease cleanup (NW-03). Docker log rotation (MT-05). Updated HANDOFF.md to reflect completions.

**Completed this session (morning):**
- SC-02: ufw-docker installed, DOCKER-USER chain rules active, navidrome/uptime-kuma/dockge ports behind UFW, Pi-hole host-network ports managed by UFW directly
- NW-03: Stale DHCP lease (192.168.1.10) removed
- MT-05: Docker daemon.json log rotation (10m max-size, 3 max-file)
- MT-01/02/03/SV-05: Marked done in files (completed in previous session)

---

## 1b. This Session — Caddy Reverse Proxy

**Date:** 2026-06-12 (evening)
**Summary:** Deployed Caddy as reverse proxy behind Tailscale Funnel. Navidrome now served through Caddy at root, with Kuma and Dockge at `/kuma/` and `/dockge/` paths.

**Completed:**
- **SV-04**: Caddy deployed at :8081, `network_mode: host`
  - Navidrome at root `/` (catch-all `reverse_proxy 127.0.0.1:4533`) — no prefix, no ND_BASEURL needed
  - Kuma at `/kuma/*` (internal only)
  - Dockge at `/dockge/*` (internal only)
  - Pi-hole remains direct at `:8080/admin/` (no Caddy routing)
- Tailscale Funnel switched from direct `:4533` → `:8081` (to Caddy)
  - `tailscale funnel reset` then `tailscale funnel --bg --set-path=/ 127.0.0.1:8081`
- **MT-06**: Confirmed done (from morning session, health checks already active)

**Key decisions:**
- Navidrome stays at root (no `/navidrome/` prefix) — avoids ND_BASEURL config, redirect loops, and path rewriting complexity
- Pi-hole not routed through Caddy — stays direct on :8080 (simpler, avoids `/admin/` rewrite issues)
- Caddy config files in `~/docker/caddy/` (compose.yaml + Caddyfile)
- Use host networking for Caddy (can reach all services via 127.0.0.1:PORT, no need to modify other compose files)

---

## 2. Session Log

| Date | Summary | Key Decisions | State Change |
|------|---------|---------------|--------------|
| 2026-06-12 (eve) | Caddy reverse proxy (SV-04) | Caddy on :8081 behind Tailscale Funnel. Navidrome at root, Kuma at /kuma/, Dockge at /dockge/. Pi-hole stays direct. | SV-04 done |
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
- Caddy at port 8081 (reverse proxy, host networking, behind Tailscale Funnel)
- Navidrome at port 4533 (music streaming, reads /mnt/media/music) accessible via Caddy root
- Syncthing at port 8384 (host networking, syncs music from PC to /mnt/media/music, Receive Only)
- Tailscale Funnel exposing Caddy at https://danko-m4600.tail81e74b.ts.net/ (--bg persistent, routes to Caddy :8081)
  - Navidrome at root `/`, Kuma at `/kuma/`, Dockge at `/dockge/`
  - Pi-hole stays direct at :8080/admin (not through Caddy)
- Uptime Kuma at port 3001 (monitoring dashboard, via Caddy at /kuma/)

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
| `~/docker/caddy/` | Caddy (reverse proxy) | 8081 host |
| `~/docker/sync/` | Syncthing (file sync) | 8384 host |
| `~/docker/uptime-kuma/` | Uptime Kuma (monitoring) | 3001 |

---

## 5. Pending Tasks

| Priority | ID | Description | Phase | Depends On |
|----------|----|-------------|-------|------------|
| 🔴 Critical | **BK-01** | Set up restic + cron backup (data unprotected, #1 priority) | 5.3 | — |
| 🔴 Critical | ~~**SC-02**~~ | ~~Fix Docker UFW bypass (container ports exposed past firewall)~~ | — | — | ✅
| 🟡 High | **SV-01** | Deploy Gitea (~80MB RAM) | 8.4 | Docker ready |
| 🟡 High | **MT-04** | Add Docker resource limits to all compose.yaml | — | — |
| 🟡 High | **BK-03** | Backup verification + restore testing (restic check) | 5.4 | BK-01 |
| 🟡 High | ~~**SV-04**~~ | ~~Deploy Caddy reverse proxy (~30MB, auto-HTTPS)~~ | 8.7 | BK-01, BK-02 | ✅
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
| ⚪ Hardware | **HW-01** | RAM upgrade 16-32GB | — | Purchase |
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
| 2026-06-11 | Skipped Cloudflare Tunnel | No domain; Tailscale Funnel fills the need | — |
| 2026-06-11 | Uptime Kuma stays internal | Monitoring dashboard doesn't need public access | Could use Tailscale Funnel |
| 2026-06-11 | Pi-hole not on Funnel | Reverted during serve experiment | — |
| 2026-06-11 | Docs: AGENTS.md = KB, HANDOFF.md = session | Non-overlapping roles for clarity | Single giant file (messy) |
| 2026-06-11 | Gap audit — 9 new task IDs added | Identified: Docker UFW bypass (🔴), missing backups verify, no reverse proxy, no swap, no log rotation, no health checks, no image pinning, no DHCP cleanup | — |
| 2026-06-11 | BK-02 done — Uptime Kuma monitors configured | NW-01 done — Router DNS set to Pi-hole | Out of band (user did directly) |
| 2026-06-11 | Hardware upgrade guide rewritten with market research | Added CPU, GPU, ExpressCard, cooling pad sections. Updated SSD, RAM, Wi-Fi, USB 2.5GbE pricing. Priority matrix included. Sources: Shopee, Chợ Tốt, MemoryZone, GEARVN, Econnect, etc. | — |

---

## 7. Constraints

- 8GB RAM primary bottleneck — add services incrementally
- Quadro 1000M Fermi GPU: no 2026 drivers, skip entirely
- Ethernet (eno1) shows NO-CARRIER — Wi-Fi (wlp3s0) only
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
