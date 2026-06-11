# M4600 Home Server Build Plan (2026 Edition)

## TL;DR

> **Quick Summary**: Transform Dell Precision M4600 (i7-2860QM, 8GB RAM, Quadro 1000M) into a Linux home server for learning systems administration and hosting lightweight services (Pi-hole, WireGuard, Jellyfin, Gitea, Samba, Docker playground). Phased build alternates learning modules with practical service deployment.
>
> **Deliverables**:
> - Ubuntu Server LTS 26.04 installed and hardened
> - Static IP, SSH (key-based), UFW firewall configured
> - LVM storage management with Samba/NFS shares
> - Docker CE + modern Docker Compose container runtime
> - Network services: Pi-hole (DNS), WireGuard (VPN), Nginx (reverse proxy)
> - Media: Jellyfin with Sandy Bridge VA-API acceleration
> - **Minecraft Server Management (Pelican Panel)**
> - **Automated CD Ripping Station (ARM)**
> - **Smart Card (SC) Identity Management (SSH/mTLS)**
> - **Productivity**: Syncthing, Obsidian LiveSync
> - **Music**: Navidrome (FLAC Streaming)
> - Self-hosted: Gitea, Immich, Ollama (Local AI)
> - Automation: Ansible config management, automated backups
> - Hardware: Dell SMM fan control, battery limits, lid management
>
> **Estimated Effort**: Medium-Large (multi-session, ~15-20 hours total)
> **Parallel Execution**: NO - mostly sequential phases
> **Critical Path**: Storage check → OS install → System foundation → Docker → Services

---

## Context

### Original Request
Turn Dell Precision M4600 (i7-2860QM, 8GB RAM, Quadro 1000M) into a home server. Learn Linux systems administration. Host multiple services. Best utilize this legacy hardware in 2026.

### User Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| OS | Ubuntu Server LTS 26.04 | Stable, modern kernel (7.0), sudo-rs |
| GPU | VA-API (Intel i965) | Sandy Bridge QSV for H.264 transcoding |
| RAM | 8GB + ZRAM (Max 32GB) | Quad-core CPU unlocks all 4 slots |
| Setup | Headless (Lid ignore) | Configure to stay on with lid closed |
| Minecraft | Pelican Panel | 2026 Standard, modern UI, mod management |
| Media | Jellyfin + ARM | Automated ripping for CD collection |
| Security | Smart Card (SC) | Use built-in slot for hardware-backed keys |
| Storage | 120GB mSATA + 447GB SATA | Split OS and Data Pool (LVM) |
| Network | Wi-Fi (wlp3s0), static IP 192.168.1.200/24 | Ethernet (eno1) has no cable; Wi-Fi for now |
| LVM | vg_data: lv_storage (200G) + data_lv (247G) | Split per plan, mounted at /mnt/media + /mnt/data |

### Hardware Constraints
- **RAM**: 8GB. **Note**: The i7-2860QM quad-core enables all 4 DIMM slots (Max 32GB).
- **GPU**: Quadro 1000M (Fermi) - skipped. Use **Intel iGPU** with VA-API for H.264.
- **CPU**: i7-2860QM (Sandy Bridge, 4C/8T, 8MB Cache). Excellent for 2-3 1080p transcodes.
- **Storage**: 120GB SAMSUNG mSATA (OS) + 447GB GIGABYTE SATA (LVM Data).
- **Thermals**: Old hardware - cleaning/repasting and fan control are critical.
- **Power**: Battery charge limits (50-80%) essential for 24/7 safety.

---

## Work Objectives

### Core Objective
Build a reliable, well-configured home server on the M4600 that serves as both a practical homelab and a Linux systems administration learning platform using 2026 standards.

### Concrete Deliverables
- [ ] Ubuntu Server LTS 26.04 installed with LVM partitioning
- [ ] Network configured (static IP, hostname, DNS)
- [ ] SSH server with key-based auth (sudo-rs)
- [ ] UFW firewall (allow SSH, deny everything else)
- [ ] Dell SMM fan control + i8kmon temperature management
- [ ] Battery charge thresholds + Lid management
- [ ] LVM volumes + Samba shares
- [ ] Docker CE + compose.yaml setup
- [ ] Pi-hole (DNS), WireGuard (VPN), Nginx (Proxy)
- [ ] Jellyfin media server (VA-API H.264)
- [ ] **Pelican Panel (Minecraft Server Management)**
- [ ] **Automated CD Ripping Station (ARM)**
- [ ] **Smart Card (SC) Identity Management**
- [ ] Gitea Git server
- [ ] Ansible managed config
- [ ] Automated backup scripts

### Definition of Done
- Services accessible and verified (curl/http/telnet)
- SSH remote management working with keys
- Fan control active, temps stable, battery capped
- Server stays active with lid closed
- Docker containers running and restarting on boot

---

## Execution Strategy

### Progress Tracker

<details>
<summary><b>📊 Overall Progress: 18 / 41 tasks done</b></summary>

#### Phase 1 — Prep & Assessment
- [x] Task 1.1: Physical assessment + repaste
- [x] Task 1.2: BIOS configuration (A19)
- [x] Task 1.3: Create Ubuntu Server 26.04 USB
<!-- 3/3 -->

#### Phase 2 — OS Install
- [x] Task 2.1: Install Ubuntu Server 26.04
- [x] Task 2.2: Post-install updates (zram, fastfetch)
<!-- 2/2 -->

#### Phase 3 — Linux Fundamentals
- [x] Task 3.1: Network config (Wi-Fi, static IP 192.168.1.200)
- [x] Task 3.2: SSH hardening (Ed25519 key-only)
- [x] Task 3.3: UFW firewall (SSH + Tailscale allowed)
- [x] Task 3.4: Users & sudo-rs
- [x] Task 3.5: systemd (cgroup v2)
- [x] Task 3.6: Package management (apt/dpkg)
- [x] Task 3.7: Monitoring (fastfetch, htop)
<!-- 7/7 -->

#### Phase 4 — Hardware Management
- [x] Task 4.1: Dell SMM fan control
- [x] Task 4.2: i8kmon daemon
- [x] Task 4.3: Battery charge thresholds — *skipped (hardware unsupported)*
- [x] Task 4.4: Wake-on-LAN
- [x] Task 4.5: Lid Management (headless)
<!-- 4.5/5 -->

#### Phase 5 — Storage Management
- [x] Task 5.1a: LVM setup (vg_data, /mnt/storage)
- [x] Task 5.1b: LVM split (lv_storage 200G + data_lv 247G)
- [x] Task 5.2: Samba file shares
- [🔄] Task 5.3: Backup strategy (rsync + cron) — *coming back to this*
<!-- 3/4 -->

#### Phase 6 — Containerization
- [x] Task 6.1: Docker CE installation
- [x] Task 6.2: Docker Compose (compose.yaml)
- [x] Task 6.3: Dockge UI (instead of Portainer)
- [ ] Task 6.4: Container networking deep-dive
<!-- 2/4 -->

#### Phase 7 — Network Services
- [ ] Task 7.1: Pi-hole (DNS sinkhole)
- [ ] Task 7.2: WireGuard VPN
- [ ] Task 7.3: Cloudflare Tunnel (remote access)
- [x] Task 7.4: Tailscale Funnel (public URLs via .ts.net)
<!-- 1/4 -->

#### Phase 8 — Media & Self-Hosted
- [ ] Task 8.1: Jellyfin (VA-API H.264)
- [ ] Task 8.2: Pelican Panel (Minecraft Server)
- [ ] Task 8.3: Automated CD Ripper (ARM)
- [ ] Task 8.4: Gitea Git server
- [x] Task 8.5: Navidrome (FLAC Streamer, port 4533)
- [x] Task 8.6: Syncthing (syncs music from PC, port 8384 host)
- [ ] Task 8.7: Optional services (Immich, Ollama, etc.)
- [ ] Task 8.8: Health check script
<!-- 2/8 -->

#### Phase 9 — Automation & Advanced
- [ ] Task 9.1: Ansible managed config
- [ ] Task 9.2: Automated Docker backups
- [ ] Task 9.3: Smart Card (SC) Identity
- [x] Task 9.4: Uptime Kuma monitoring (port 3001)
<!-- 1/4 -->

</details>

### Memory Management Strategy (8GB Constraint)
- Services NOT started simultaneously. Added incrementally, memory monitored.
- Target: keep idle RAM usage < 4GB, leaving ~4GB for workloads + cache
- Use `zram-config` for fast compressed swap in RAM
- Docker containers: Use `--memory` limits per container
- If OOM occurs: prioritize which services to disable

---

## Phase Files

| Phase | File | Tasks |
|-------|------|-------|
| 1. Prep & Assess | [phase-01-prep.md](phase-01-prep.md) | BIOS A19, Thermal repaste |
| 2. OS Install | [phase-02-os-install.md](phase-02-os-install.md) | Ubuntu 26.04, TPM, ZRAM |
| 3. Linux Fundamentals | [phase-03-linux-fundamentals.md](phase-03-linux-fundamentals.md) | sudo-rs, cgroup v2, fastfetch |
| 4. Hardware Management | [phase-04-hardware-management.md](phase-04-hardware-management.md) | Lid management, i8kmon |
| 5. Storage Management | [phase-05-storage-management.md](phase-05-storage-management.md) | LVM, restic mention |
| 6. Containerization | [phase-06-containerization.md](phase-06-containerization.md) | compose.yaml, Watch |
| 7. Network Services | [phase-07-network-services.md](phase-07-network-services.md) | Pi-hole v6, Cloudflare Tunnels, Tailscale |
| 8. Media & Self-Hosted | [phase-08-media-selfhosted.md](phase-08-media-selfhosted.md) | Jellyfin, Pelican, ARM, Navidrome, Sync |
| 9. Automation | [phase-09-automation.md](phase-09-automation.md) | Ansible, SC Slot, Uptime Kuma |

---

## Future Possibilities (2026 "Cool Things")

- **RAM upgrade to 32GB**: Since you have the i7-2860QM, you can fill all 4 slots. This is the single biggest "cool" upgrade.
- **Local AI (Ollama + Open WebUI)**: Run your own private Llama 3 (or 2026 equivalent) LLM. The 2860QM's 8MB cache handles CPU-based inference surprisingly well.
- **Immich**: The 2026 standard for self-hosted photo backup (Google Photos replacement).
- **2.5GbE Networking**: Use the ExpressCard/54 slot with a modern 2.5GbE adapter to break the Gigabit bottleneck.
- **Advanced Monitoring**: Deploy the full Prometheus/Grafana stack with custom dashboards for your hardware.
- **Frigate AI + Coral TPU**: Use an **ExpressCard-to-MiniPCIe** adapter to add a Coral TPU for AI object detection on your cameras.
- **Vintage Web Gateway**: Run **FrogFind** or **WRP** to allow retro computers (90s era) to browse the modern web through your server.
- **Stratum 1 Time Server**: Use a GPS module + PPS to make your M4600 the authoritative time source for your entire network.
- **Kernel Samepage Merging (KSM)**: Enable `ksmtuned` to deduplicate RAM across your many Docker containers, saving 10-20% of your 8GB memory.

---

## Success Criteria

### Verification Commands
```bash
# Core system
ssh user@192.168.1.200      # SSH works
sudo ufw status              # Firewall active
systemctl is-active sshd     # SSH active
systemctl is-active docker   # Docker active

# Services
curl -sI http://localhost:8096 | head -1    # Jellyfin responds
curl -sI http://localhost:3000 | head -1    # Gitea responds
curl -sI http://localhost:9000 | head -1    # Portainer responds
curl -sI http://localhost:8080 | head -1    # Pi-hole responds
ping 10.0.0.1                               # WireGuard works

# Hardware
sensors                                     # Fan/temp control works
sudo smbios-battery-ctl --get-charging-mode # Battery safe
```

### Final Checklist
- [ ] All Must Have items verified
- [ ] All Must NOT Have items absent
- [ ] Services restart after reboot (test with `sudo reboot`)
- [ ] Remote management fully functional
- [ ] User feels they learned the intended skills
