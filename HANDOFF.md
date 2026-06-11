# Handoff — M4600 Home Server

**Date:** 2026-06-11 (refactored)
**Server:** danko@192.168.1.200
**User:** danko (in docker + sudo groups)
**Refer to:** [AGENTS.md](AGENTS.md) for full KB, [m4600-server-setup.md](m4600-server-setup.md) for plan index

---

## 1. Last Session

**Date:** 2026-06-11
**Summary:** Documentation refactor — unified task IDs, corrected OS to Ubuntu Server 26.04, added Vietnam purchase guide, restructured AGENTS.md/HANDOFF.md/m4600-server-setup.md into non-overlapping roles.

**Decisions:**
- AGENTS.md = single source of truth for KB, progress, roadmap
- m4600-server-setup.md = thin master plan index only
- HANDOFF.md = session context + pending tasks + decision log
- All task references now use unified IDs (BK-01, NW-01, etc.) across all files

---

## 2. Session Log

| Date | Summary | Key Decisions | State Change |
|------|---------|---------------|--------------|
| 2026-06-11 | Docs refactored | AGENTS.md/HANDOFF.md/m4600-setup.md restructured; unified task IDs created | Docs cleaned |
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
- Navidrome at port 4533 (music streaming, reads /mnt/media/music)
- Syncthing at port 8384 (host networking, syncs music from PC to /mnt/media/music, Receive Only)
- Tailscale Funnel exposing Navidrome at https://danko-m4600.tail81e74b.ts.net/ (--bg persistent on port 4533, root path)
  - Pi-hole Funnel was removed during serve experiment — currently local-only at :8080/admin
- Uptime Kuma at port 3001 (monitoring dashboard)

### ❌ Not Working / Issues
- **Phone (Pixel) DNS bypass** — Private DNS (DoT) + IPv6 causes Pixel to bypass Pi-hole. Known issue, needs router-level DNS config or UFW rule to force all DNS through Pi-hole.
- **Viettel router DNS not set** — Router DHCP still uses ISP DNS. Needs ISP DNS turned OFF, Primary DNS set to 192.168.1.200.
- Pi-hole network table still shows stale 172.19.0.x entries from old Docker bridge mode (harmless).

---

## 4. Stack on Disk

All in `~/docker/<service>/` with `compose.yaml`:

| Directory | Service | Port |
|-----------|---------|------|
| `~/docker/pihole/` | Pi-hole + Unbound | 53, 8080 |
| `~/docker/navidrome/` | Navidrome (music) | 4533 |
| `~/docker/sync/` | Syncthing (file sync) | 8384 host |
| `~/docker/uptime-kuma/` | Uptime Kuma (monitoring) | 3001 |

---

## 5. Pending Tasks

| Priority | ID | Description | Phase | Depends On |
|----------|----|-------------|-------|------------|
| 🔴 Critical | **BK-01** | Set up restic + cron backup (data unprotected, #1 priority) | 5.3 | — |
| 🔴 Critical | **BK-02** | Configure Uptime Kuma monitors (Pi-hole, Navidrome, Syncthing, SSH, DNS) | 9.3b | BK-01 |
| 🟡 High | **NW-01** | Set router DHCP DNS to 192.168.1.200 (fix Pixel bypass) | 7.2 | — |
| 🟡 High | **SV-01** | Deploy Gitea (~80MB RAM) | 8.4 | Docker ready |
| 🟡 High | **SC-01** | Install fail2ban for SSH protection (~10MB) | — | — |
| 🟡 High | **MT-01** | Configure SMART monitoring (smartmontools) | — | — |
| 🟡 High | **MT-02** | Set journald size limit (500MB) | — | — |
| 🟡 High | **MT-03** | Enable unattended-upgrades (auto security) | — | — |
| 🟡 High | **MT-04** | Add Docker resource limits to all compose.yaml | — | — |
| 🟢 Medium | **SV-02** | Deploy Homer dashboard (~5MB) | — | BK-01, BK-02 |
| 🟢 Medium | **NW-02** | IPv6 DNS config (fix Pixel DoT) | — | NW-01 |
| 🟢 Medium | **AU-01** | Ansible config management | 9.1 | — |
| 🟢 Medium | **AU-02** | Docker volume backup script | 9.2 | BK-01 |
| 🟢 Medium | **SV-03** | Deploy Diun (Docker update notifier) | — | — |
| ⚪ Hardware | **HW-01** | RAM upgrade 16-32GB | — | Purchase |
| ⚪ Hardware | **HW-02** | Ethernet cable Cat 6 | — | Purchase |
| ⚪ Hardware | **HW-03** | Wi-Fi card Intel AC 7260HMW | — | Purchase |
| ⚪ Deferred | HW-04/HW-05/HW-06 | Thermal paste, caddy, UPS | — | Purchase |

---

## 6. Decision Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-11 | Skipped Jellyfin | Sandy Bridge iGPU too weak for HEVC/4K (H.264 only) | Consider Intel Arc A310 for transcoding |
| 2026-06-11 | Skipped Cloudflare Tunnel | No domain; Tailscale Funnel fills the need | — |
| 2026-06-11 | Uptime Kuma stays internal | Monitoring dashboard doesn't need public access | Could use Tailscale Funnel |
| 2026-06-11 | Pi-hole not on Funnel | Reverted during serve experiment | — |
| 2026-06-11 | Docs: AGENTS.md = KB, HANDOFF.md = session | Non-overlapping roles for clarity | Single giant file (messy) |

---

## 7. Constraints

- 8GB RAM primary bottleneck — add services incrementally
- Quadro 1000M Fermi GPU: no 2026 drivers, skip entirely
- Ethernet (eno1) shows NO-CARRIER — Wi-Fi (wlp3s0) only
- Battery charge thresholds unsupported — skipped, monitor for swelling
- Two IPs on wlp3s0: static 192.168.1.200 + DHCP 192.168.1.7 (DHCP lease can be released)
- No Ubuntu snaps — all packages via apt
- No Ubuntu Pro
- Host runs Ubuntu Server 26.04 LTS (headless)
