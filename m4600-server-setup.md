# M4600 Home Server Build Plan (2026 Edition)

## TL;DR

> **Quick Summary**: Transform Dell Precision M4600 (i7-2860QM, 8GB RAM, Quadro 1000M) into a Linux home server for learning systems administration and hosting lightweight services (Pi-hole, Navidrome, Syncthing, Uptime Kuma, Docker playground). Phased build alternates learning modules with practical service deployment.
>
> **Deliverables**:
> - EndeavourOS (Arch-based) installed and hardened
> - Static IP, SSH (key-based), UFW firewall configured
> - LVM storage management with Samba/NFS shares
> - Docker CE + modern Docker Compose container runtime
> - Network services: Pi-hole (DNS sinkhole + Unbound recursive resolver)
> - Tailscale Funnel for remote access (Navidrome public at .ts.net)
> - Media: Navidrome (music streaming), Syncthing (file sync)
> - Monitoring: Uptime Kuma dashboard
> - Self-hosted: Gitea (planned), ARM (planned), Pelican (planned)
> - Automation: Ansible config management, automated backups
> - Hardware: Dell SMM fan control, Wake-on-LAN, lid management
>
> **Estimated Effort**: Medium-Large (multi-session, ~15-20 hours total)
> **Parallel Execution**: NO - mostly sequential phases
> **Critical Path**: Storage → OS → Docker → Services → Monitoring → Backups

---

## Context

### Original Request
Turn Dell Precision M4600 (i7-2860QM, 8GB RAM, Quadro 1000M) into a home server. Learn Linux systems administration. Host multiple services. Best utilize this legacy hardware in 2026.

### User Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| OS | EndeavourOS (Arch-based, headless) | Modern kernel, AUR, no snaps |
| GPU | Skipped (Fermi dead in 2026) | Using Intel iGPU VA-API (i965) if needed |
| RAM | 8GB + ZRAM (Max 32GB) | Quad-core CPU unlocks all 4 slots |
| Setup | Headless (Lid ignore) | Configure to stay on with lid closed |
| Media | Navidrome + Syncthing | Music streaming + file sync |
| DNS | Pi-hole + Unbound | DNS sinkhole + recursive resolver |
| Remote Access | Tailscale Funnel | Public URLs via .ts.net |
| Storage | 120GB mSATA + 447GB SATA | Split OS and Data Pool (LVM) |
| Network | Wi-Fi (wlp3s0), static IP 192.168.1.200/24 | Ethernet (eno1) has no cable |
| LVM | vg_data: lv_storage (200G) + data_lv (247G) | Mounted at /mnt/media + /mnt/data |

### Hardware Constraints
- **RAM**: 8GB. **Note**: The i7-2860QM quad-core enables all 4 DIMM slots (Max 32GB).
- **GPU**: Quadro 1000M (Fermi) - skipped entirely. No 2026 driver support.
- **CPU**: i7-2860QM (Sandy Bridge, 4C/8T, 8MB Cache). Excellent for 2-3 1080p transcodes.
- **Storage**: 120GB SAMSUNG mSATA (OS) + 447GB GIGABYTE SATA (LVM Data).
- **Thermals**: Old hardware - cleaning/repasting done, fan control active.
- **Power**: Battery charge thresholds unsupported — monitor for swelling.
- **Ethernet**: eno1 shows NO-CARRIER — Wi-Fi only for now.

---

## Work Objectives

### Core Objective
Build a reliable, well-configured home server on the M4600 that serves as both a practical homelab and a Linux systems administration learning platform using 2026 standards.

### Concrete Deliverables
- [x] EndeavourOS installed with LVM partitioning
- [x] Network configured (static IP, hostname, DNS)
- [x] SSH server with key-based auth
- [x] UFW firewall (SSH + Tailscale allowed)
- [x] Dell SMM fan control + i8kmon temperature management
- [x] Wake-on-LAN + Lid management (headless)
- [x] LVM volumes + Samba shares
- [x] Docker CE + compose.yaml setup + Dockge UI
- [x] Pi-hole (DNS sinkhole) + Unbound (recursive resolver)
- [x] Tailscale Funnel (Navidrome public at .ts.net)
- [x] Navidrome (FLAC streaming, port 4533)
- [x] Syncthing (file sync, port 8384 host networking)
- [x] Uptime Kuma (monitoring dashboard, port 3001)
- [ ] Backup strategy (restic + cron) — **CRITICAL GAP**
- [ ] Gitea Git server (self-hosted git)
- [ ] Automated CD Ripping Station (ARM)
- [ ] Pelican Panel (Minecraft Server Management)
- [ ] Ansible managed config
- [ ] Security hardening (fail2ban)

### Definition of Done
- Services accessible and verified (curl/http/telnet)
- SSH remote management working with keys
- Fan control active, temps stable
- Server stays active with lid closed
- Docker containers running and restarting on boot
- Backups configured and tested
- Monitoring for all critical services

---

## Execution Strategy

### Progress Tracker

<details>
<summary><b>📊 Overall Progress: 22 / 41 tasks done</b></summary>

#### Phase 1 — Prep & Assessment ✅
- [x] Task 1.1: Physical assessment + repaste
- [x] Task 1.2: BIOS configuration (A19)
- [x] Task 1.3: Create EndeavourOS USB
<!-- 3/3 -->

#### Phase 2 — OS Install ✅
- [x] Task 2.1: Install EndeavourOS (Arch-based, headless)
- [x] Task 2.2: Post-install updates (zram, fastfetch)
<!-- 2/2 -->

#### Phase 3 — Linux Fundamentals ✅
- [x] Task 3.1: Network config (Wi-Fi, static IP 192.168.1.200)
- [x] Task 3.2: SSH hardening (Ed25519 key-only)
- [x] Task 3.3: UFW firewall (SSH + Tailscale allowed)
- [x] Task 3.4: Users & sudo
- [x] Task 3.5: systemd (cgroup v2)
- [x] Task 3.6: Package management (pacman/yay)
- [x] Task 3.7: Monitoring (fastfetch, htop)
<!-- 7/7 -->

#### Phase 4 — Hardware Management ✅ (4/5)
- [x] Task 4.1: Dell SMM fan control
- [x] Task 4.2: i8kmon daemon
- [x] Task 4.3: Battery charge thresholds — *skipped (hardware unsupported)*
- [x] Task 4.4: Wake-on-LAN
- [x] Task 4.5: Lid Management (headless)
<!-- 4.5/5 -->

#### Phase 5 — Storage Management (3/4)
- [x] Task 5.1a: LVM setup (vg_data, /mnt/media)
- [x] Task 5.1b: LVM split (lv_storage 200G + data_lv 247G)
- [x] Task 5.2: Samba file shares
- [ ] Task 5.3: Backup strategy (restic + cron) — **NEXT SESSION PRIORITY**
<!-- 3/4 -->

#### Phase 6 — Containerization (2/3)
- [x] Task 6.1: Docker CE installation
- [x] Task 6.2: Docker Compose (compose.yaml) + Dockge UI
- [ ] Task 6.3: Container networking deep-dive (deferred)
<!-- 2/3 -->

#### Phase 7 — Network Services (3/4)
- [x] Task 7.1: Pi-hole + Unbound (DNS sinkhole + recursive resolver)
- [ ] Task 7.2: Pi-hole router DNS config (fix Pixel bypass)
- [ ] Task 7.3: WireGuard VPN (backup VPN, optional)
- [x] Task 7.4: Tailscale Funnel (Navidrome public at .ts.net)
<!-- 2.5/4 -->

#### Phase 8 — Media & Self-Hosted (2/7)
- [ ] Task 8.1: Jellyfin — *on hold (Sandy Bridge too weak for HEVC)*
- [ ] Task 8.2: Pelican Panel (Minecraft Server)
- [ ] Task 8.3: Automated CD Ripper (ARM)
- [ ] Task 8.4: Gitea Git server (~80MB RAM)
- [x] Task 8.5: Navidrome (FLAC Streamer, port 4533)
- [x] Task 8.6: Syncthing (syncs music from PC, port 8384 host)
<!-- 2/7 -->

#### Phase 9 — Automation & Advanced (1/5)
- [ ] Task 9.1: Ansible managed config
- [ ] Task 9.2: Docker backup scripts
- [x] Task 9.3: Uptime Kuma monitoring (port 3001)
- [ ] Task 9.3b: Configure Uptime Kuma monitors (Pi-hole, Navidrome, Syncthing, SSH)
- [ ] Task 9.4: KSM (Kernel Same-page Merging) — deferred until RAM upgrade
<!-- 1/5 -->

</details>

### Memory Management Strategy (8GB Constraint)
- Services NOT started simultaneously. Added incrementally, memory monitored.
- Target: keep idle RAM usage < 4GB, leaving ~4GB for workloads + cache
- Use ZRAM (3.6G compressed swap) for fast compressed swap in RAM
- Docker containers: Use `--memory` limits per container
- If OOM occurs: prioritize which services to disable
- **Deferred**: KSM (Kernel Same-page Merging) — wait for RAM upgrade

---

## Phase Files

| Phase | File | Tasks |
|-------|------|-------|
| 1. Prep & Assess | [phase-01-prep.md](phase-01-prep.md) | BIOS A19, Thermal repaste |
| 2. OS Install | [phase-02-os-install.md](phase-02-os-install.md) | EndeavourOS, ZRAM |
| 3. Linux Fundamentals | [phase-03-linux-fundamentals.md](phase-03-linux-fundamentals.md) | sudo, cgroup v2, fastfetch |
| 4. Hardware Management | [phase-04-hardware-management.md](phase-04-hardware-management.md) | Lid management, i8kmon, WOL |
| 5. Storage Management | [phase-05-storage-management.md](phase-05-storage-management.md) | LVM, Samba, backup |
| 6. Containerization | [phase-06-containerization.md](phase-06-containerization.md) | Docker, Compose, Dockge |
| 7. Network Services | [phase-07-network-services.md](phase-07-network-services.md) | Pi-hole, Unbound, Tailscale |
| 8. Media & Self-Hosted | [phase-08-media-selfhosted.md](phase-08-media-selfhosted.md) | Navidrome, Syncthing, Gitea |
| 9. Automation | [phase-09-automation.md](phase-09-automation.md) | Ansible, Uptime Kuma |

---

## Current Session State

### Working Services
- LVM: vg_data with lv_storage (200G, /mnt/media) + data_lv (247G, /mnt/data)
- Samba: [media] and [data] shares at /mnt/media and /mnt/data
- Docker CE + docker-compose-plugin + containerd.io
- Lazydocker (TUI)
- Dockge at :5001 (compose stacks in ~/docker/)
- Tailscale at 100.101.7.123
- Pi-hole + Unbound (DNS sinkhole + recursive resolver, :8080/admin)
  - network_mode: host (both containers share host netns)
  - HaGeZi Pro blocklist loaded (1.6M domains blocked)
  - Unbound on port 5335, Pi-hole forwards to 127.0.0.1#5335
- UFW: SSH, Tailscale, Samba, Pi-hole (53, 8080) ports open
- Fan management: dell-bios-fan-control + i8kmon
- Navidrome at port 4533 (music streaming, reads /mnt/media/music)
- Syncthing at port 8384 (host networking, syncs music from PC to /mnt/media/music)
- Tailscale Funnel exposing Navidrome at https://danko-m4600.tail81e74b.ts.net/
- Uptime Kuma at port 3001 (monitoring dashboard, monitors not yet configured)

### Known Issues
- **Phone (Pixel) DNS bypass** — Private DNS (DoT) + IPv6 causes Pixel to bypass Pi-hole
- **Viettel router DNS not set** — Router DHCP still uses ISP DNS
- **Ethernet (eno1) NO-CARRIER** — Server runs on Wi-Fi only

### Stacks on Disk
| Directory | Service | Port |
|-----------|---------|------|
| ~/docker/pihole/ | Pi-hole + Unbound | 53, 8080 |
| ~/docker/navidrome/ | Navidrome | 4533 |
| ~/docker/sync/ | Syncthing | 8384 |
| ~/docker/uptime-kuma/ | Uptime Kuma | 3001 |

---

## Prioritized Next Steps (Recommended Order)

### 🔴 CRITICAL — Do First
1. **Backup (5.3)** — Data is unprotected. Use `restic` for dedup + encryption. Cron job to external drive or second disk.
2. **Configure Uptime Kuma (9.3b)** — Add monitors for Pi-hole, Navidrome, Syncthing, SSH, DNS health.

### 🟡 HIGH PRIORITY — Next Sessions
3. **Pi-hole Router DNS (7.2)** — Set router DHCP DNS to 192.168.1.200, fix Pixel IPv6/DoT bypass.
4. **Gitea (8.4)** — Self-hosted git server (~80MB RAM). Host dotfiles, configs, project repos.
5. **Security Hardening** — Fail2ban for SSH brute-force protection (~10MB RAM).

### 🟢 MEDIUM PRIORITY — When Ready
6. **Homer Dashboard** — Single-page dashboard for all services (~5MB RAM).
7. **ARM (8.3)** — Automated CD ripping if you have a CD collection.
8. **Pelican (8.2)** — Minecraft server if you play.

### ⚪ DEFERRED — Hardware Upgrade Required
9. **RAM Upgrade to 16-32GB** — DDR3 is cheap ($20-40). Enables Ollama, Immich, more containers.
10. **Ethernet Cable** — $5 for reliable gigabit. Wi-Fi is flaky for a server.
11. **2.5GbE ExpressCard** — ~$25 for network speed boost via ExpressCard/54 slot.

### ⚪ DROP/DEFER — Redundant or Low Value
- **WireGuard (7.2)** — Tailscale already provides mesh VPN
- **Cloudflare Tunnel (7.3)** — Tailscale Funnel fills the need
- **Smart Card (9.5)** — Niche, low practical value for home server
- **KSM (9.4)** — Marginal benefit on 8GB, wait for RAM upgrade

---

## Hardware Upgrades (Recommended)

| Upgrade | Why | Cost | Difficulty | Priority |
|---------|-----|------|------------|----------|
| **RAM → 16-32GB** | 8GB is bottleneck. 4 DIMM slots, DDR3 cheap. Enables Ollama, more containers, better caching. | $20-40 | Easy | HIGH |
| **Ethernet cable** | eno1 exists but NO-CARRIER. $5 for reliable gigabit. Wi-Fi flaky for server. | $5 | Trivial | HIGH |
| **2.5GbE ExpressCard** | ExpressCard/54 slot. ~$25 for 2.5GbE adapter. Breaks gigabit bottleneck. | $25 | Easy | MEDIUM |
| **USB UPS** | 24/7 server without power protection = eventual data loss. Used UPS with USB monitoring. | $30-50 | Medium | MEDIUM |

---

## Software Additions (Recommended)

### High Value (fits 8GB budget)
| Service | RAM | Why |
|---------|-----|-----|
| **Gitea** | ~80MB | Self-hosted git. Host repos, dotfiles, configs. |
| **Fail2ban** | ~10MB | SSH brute-force protection. Defense-in-depth. |
| **Nginx Proxy Manager** | ~50MB | Reverse proxy with auto-SSL. Clean URLs for services. |
| **Homer Dashboard** | ~5MB | Single-page dashboard for all services. |
| **Lidarr + Prowlarr** | ~300MB | Music library management if ripping CDs. |

### Medium Value (if RAM allows)
| Service | RAM | Why |
|---------|-----|-----|
| **Vaultwarden** | ~30MB | Self-hosted Bitwarden password manager. |
| **Paperless-ngx** | ~300MB | Document management. Digitize receipts, manuals. |
| **Calibre-web** | ~100MB | Ebook library management. |

### Skip for Now
- **Ollama/Open WebUI** — Needs 16GB+ RAM
- **Immich** — Needs 8GB+ free RAM, wait for upgrade
- **Nextcloud** — Syncthing covers sync needs

---

## Future Possibilities (2026 "Cool Things")

- **RAM upgrade to 32GB**: Single biggest upgrade. Enables all planned services.
- **Local AI (Ollama + Open WebUI)**: Private LLM. Needs RAM upgrade first.
- **Immich**: Self-hosted photo backup (Google Photos replacement). Needs RAM.
- **2.5GbE Networking**: ExpressCard/54 adapter breaks gigabit bottleneck.
- **Advanced Monitoring**: Prometheus/Grafana stack with custom dashboards.
- **Frigate AI + Coral TPU**: ExpressCard-to-MiniPCIe adapter for AI object detection.
- **Vintage Web Gateway**: FrogFind or WRP for retro computers to browse modern web.
- **Stratum 1 Time Server**: GPS module + PPS for authoritative network time.

---

## Success Criteria

### Verification Commands
```bash
# Core system
ssh danko@192.168.1.200        # SSH works
sudo ufw status verbose        # Firewall active
systemctl is-active sshd       # SSH active
systemctl is-active docker     # Docker active

# Services
curl -sI http://localhost:4533 | head -1    # Navidrome responds
curl -sI http://localhost:8384 | head -1    # Syncthing responds
curl -sI http://localhost:8080 | head -1    # Pi-hole responds
curl -sI http://localhost:3001 | head -1    # Uptime Kuma responds

# DNS
dig @192.168.1.200 google.com              # Pi-hole + Unbound working
docker exec pihole pihole status           # Pi-hole status

# Tailscale
sudo tailscale funnel status               # Funnel active
curl -sI https://danko-m4600.tail81e74b.ts.net/ | head -1  # Navidrome public

# Hardware
sensors                                     # Fan/temp control works
```

### Final Checklist
- [ ] All critical tasks completed (backup, monitoring, DNS config)
- [ ] Services restart after reboot (test with `sudo reboot`)
- [ ] Remote management fully functional (Tailscale + SSH)
- [ ] Backups configured and tested (restore test)
- [ ] User feels they learned the intended skills
