# M4600 Home Server — Project Knowledge Base

**Generated:** 2026-06-12
**Project:** Dell Precision M4600 → Enterprise-Grade Linux Home Lab Server
**OS:** Ubuntu Server 26.04 LTS
**User:** `danko`
**Network:** 192.168.1.200/24 (Ethernet eno1 primary, Wi-Fi wlp3s0 backup)
**Tailscale:** 100.101.7.123

---

## 1. Hardware Specs

| Component | Spec | Notes |
|-----------|------|-------|
| **CPU** | Intel Core i7-2860QM (4C/8T, Sandy Bridge, 2.5-3.6 GHz) | Unlocks all 4 DIMM slots |
| **RAM** | 24GB DDR3 (4GB+8GB per channel) + ZRAM (3.6G lzo-rle) + 4G swapfile | 4× SO-DIMM slots, max 64GB per dmidecode — upgraded 2026-06-20 (added 2× 8GB Inmos) |
| **GPU** | NVIDIA Quadro 1000M (Fermi) — **skipped** | No driver support in 2026; using Intel HD 3000 iGPU |
| **Storage (OS)** | 120GB SAMSUNG PM871 mSATA → `/` | SATA III |
| **Storage (Data)** | 447GB GIGABYTE SATA → LVM `vg_data` | Split: lv_storage (200G) + data_lv (247G) |
| **Optical** | DVD-RW (9.5mm SATA) | Replaceable with caddy for 3rd drive |
| **Wi-Fi** | Intel Centrino Advanced-N 6200 (half mini-PCIe, 802.11 a/b/g/n) | No AC — upgrade candidate |
| **Ethernet** | Intel 82579LM Gigabit (eno1) | **Active** — Static 192.168.1.200/24, primary interface |
| **Display** | 15.6" 1920×1080 (anti-glare) | Lid closed; consoleblank=60 |
| **Chassis** | Al/Mg alloy, MIL-STD-810G | 2.8kg, durable for 24/7 |

---

## 2. Storage Layout

```
sda (447GB GIGABYTE) → vg_data
  ├── lv_storage (200G) → /mnt/media    (Jellyfin, music, Navidrome)
  └── data_lv   (~247G) → /mnt/data     (backups, sync, Samba)

sdb (120GB Samsung mSATA) → OS only
  ├── sdb1 (1G)   /boot/efi
  ├── sdb2 (2G)   /boot
  └── sdb3 → LVM → / (116G)
```

### Mount Points
| Path | LV | Size | Used For |
|------|----|------|----------|
| `/mnt/media` | lv_storage | 200G | Music, media, Navidrome reads |
| `/mnt/data` | data_lv | 247G | Backups, Samba [data], Syncthing |

---

## 3. Service Inventory

| Service | Port(s) | Docker | Status | Est. RAM | Config Path |
|---------|---------|--------|--------|----------|-------------|
| Pi-hole + Unbound | 53, 8080 | ✅ (host net) | ✅ Working | ~150MB | `~/docker/pihole/` |
| Navidrome | 4533 | ✅ bridge | ✅ Working | ~80MB | `~/docker/navidrome/` |
| Syncthing | 8384 | ✅ host net | ✅ Working | ~100MB | `~/docker/sync/` |
| Caddy | 8081 | ✅ bridge | ❌ Removed | ~30MB | `~/docker/caddy/` |
| Cloudflared (tunnel) | — | ❌ native | ✅ Working | ~30MB | `/etc/cloudflared/` |
| Uptime Kuma | 3001 | ✅ bridge | ✅ Running (no monitors) | ~50MB | `~/docker/uptime-kuma/` |
| Samba (smbd) | 445 | ❌ native | ✅ Working | ~30MB | `/etc/samba/smb.conf` |
| Tailscale | 100.101.7.123 | ❌ native | ✅ Working | ~40MB | `/etc/default/tailscale` |
| Dockge | 5001 | ✅ bridge | ✅ Working | ~30MB | `~/docker/dockge/` |
| Gitea | 3000 | ✅ bridge | ✅ Working | ~80MB | `~/docker/gitea/` |
| Lazydocker | TUI | ❌ native | ✅ Installed | — | — |
| **Total running** | | | | **~500MB** | |

---

## 4. Progress Dashboard

### Phase Summary

| Phase | Tasks | Done | % | Top Pending |
|-------|-------|------|---|-------------|
| 1. Prep & Assessment | 3 | 3 | 100% | — |
| 2. OS Install | 2 | 2 | 100% | — |
| 3. Linux Fundamentals | 7 | 7 | 100% | — |
| 4. Hardware Management | 5 | 5 | 100% | — |
| 5. Storage Management | 6 | 3 | 50% | **BK-01**: Backup strategy |
| 6. Containerization | 3 | 2 | 67% | Networking deep-dive |
| 7. Network Services | 4 | 4 | 100% | — |
| 8. Media & Self-Hosted | 8 | 5 | 63% | **8.1**: Jellyfin (HEVC) |
| 9. Automation | 12 | 9 | 75% | **MT-04**: Docker resource limits |
| **Total** | **50** | **40** | **80%** | |

### Detailed Task List

#### Phase 1 — Prep & Assessment ✅
- [x] 1.1 Physical assessment + repaste
- [x] 1.2 BIOS configuration (A19)
- [x] 1.3 Create Ubuntu Server USB

#### Phase 2 — OS Install ✅
- [x] 2.1 Install Ubuntu Server 26.04 (headless)
- [x] 2.2 Post-install updates (zram, fastfetch)

#### Phase 3 — Linux Fundamentals ✅
- [x] 3.1 Network config (static IP)
- [x] 3.2 SSH hardening (Ed25519 key-only)
- [x] 3.3 UFW firewall
- [x] 3.4 Users & sudo
- [x] 3.5 systemd
- [x] 3.6 Package management (apt/dpkg)
- [x] 3.7 Monitoring (fastfetch, htop)

#### Phase 4 — Hardware Management ✅ (5/5)
- [x] 4.1 Dell SMM fan control
- [x] 4.2 i8kmon daemon
- [x] 4.3 Battery charge — *skipped (hw unsupported)*
- [x] 4.4 Wake-on-LAN
- [x] 4.5 Lid management (headless)

#### Phase 5 — Storage Management (3/6)
- [x] 5.1a LVM setup (vg_data)
- [x] 5.1b LVM split (lv_storage + data_lv)
- [x] 5.2 Samba shares
- [ ] **BK-01**: Backup strategy (restic + cron) ← 🔴
- [ ] **BK-03**: Backup verification + restore testing ← 🟡
- [ ] **BK-04**: Offsite backup (Backblaze B2 / rsync.net) ← 🟢

#### Phase 6 — Containerization (2/3)
- [x] 6.1 Docker CE install
- [x] 6.2 Docker Compose + Dockge UI
- [ ] 6.3 Container networking deep-dive (deferred)

#### Phase 7 — Network Services (3/4)
- [x] 7.1 Pi-hole + Unbound
- [x] **NW-01**: Router DNS config (fix Pixel bypass) ← 🟡
- [x] **NW-03**: Release DHCP lease (keep static 192.168.1.200 only) ← 🟢
- [x] 7.4 Tailscale Funnel (Navidrome public — replaced by Cloudflare tunnel + domain, still available for internal)

#### Phase 8 — Media & Self-Hosted (4/9)
- [ ] 8.1 Jellyfin — *on hold (Sandy Bridge too weak for HEVC)*
- [ ] 8.2 Pelican (Minecraft)
- [ ] 8.3 ARM (CD ripping)
- [x] **SV-01**: Gitea (~80MB RAM) — deployed ✅
- [x] 8.5 Navidrome
- [x] 8.6 Syncthing
- [x] **SV-04**: Caddy reverse proxy — tested, then removed. Replaced by Cloudflare tunnel + domain ← 🟡
- [x] **SV-05**: Swap file (4G already exists) ← 🟢
- [x] **NW-04**: Cloudflare tunnel + domain dankofox.quest (Navidrome public at music.dankofox.quest) ← 🟢

#### Phase 9 — Automation (2/10)
- [ ] **AU-01**: Ansible config management
- [ ] **AU-02**: Docker backup scripts
- [x] 9.3 Uptime Kuma deployed
- [x] **BK-02**: Configure Uptime Kuma monitors ← 🔴
- [ ] 9.4 KSM — *deferred until RAM upgrade*
- [ ] 9.5 Smart Card — *low value, deferred*
- [x] **SC-01**: Fail2ban SSH protection ← 🟡
- [x] **SC-02**: Docker UFW bypass hardening ← 🔴
- [x] **MT-02**: Journald size limit config ← 🟡
- [x] **MT-03**: unattended-upgrades (auto security) ← 🟡
- [x] **MT-01**: SMART monitoring (smartmontools) ← 🟡
- [x] **MT-05**: Docker log rotation per container ← 🟡
- [x] **MT-06**: Container health checks in compose ← 🟡
- [ ] **MT-07**: Docker image pinning (digest) ← 🟢

---

## 5. Unified Task ID Reference

Cross-ref between AGENTS.md progress, HANDOFF.md pending tasks, and session plans.

| ID | Description | Phase Ref | Priority | Depends On |
|----|-------------|-----------|----------|------------|
| **BK-01** | Backup strategy (restic + cron) | 5.3 | 🔴 Critical | Phase 5 done |
| **BK-02** | Configure Uptime Kuma monitors | 9.3b | 🔴 Critical | Phase 9 started | ✅
| **BK-03** | Backup verification + restore testing | 5.4 | 🟡 High | BK-01 |
| **BK-04** | Offsite backup (Backblaze B2 / rsync.net) | 5.5 | 🟢 Medium | BK-01 |
| **NW-01** | Router DNS → 192.168.1.200 (fix Pixel) | 7.2 | 🟡 High | — | ✅
| **NW-02** | IPv6 DNS config (fix Pixel DoT) | — | 🟢 Medium | NW-01 |
| **NW-03** | Release DHCP lease (static-only IP) | 7.3 | 🟢 Medium | — |
| **SV-01** | Gitea self-hosted git | 8.4 | 🟡 High | Docker ready | ✅
| **SV-02** | Homer dashboard | — | 🟢 Medium | BK-01, BK-02 done |
| **SV-03** | Diun (Docker update notifier) | — | 🟢 Medium | — |
| **SV-04** | Caddy reverse proxy — tested, then removed. Replaced by Cloudflare tunnel + domain | 8.7 | 🟡 High | BK-01, BK-02 | ✅
| **SV-05** | Swap file (4G + ZRAM 3.6G) | 8.8 | 🟢 Medium | — | ✅
| **NW-04** | Cloudflare tunnel + domain dankofox.quest (Navidrome public at music.dankofox.quest) | 8.9 | 🟢 Medium | — | ✅
| **SC-01** | Fail2ban SSH protection | — | 🟡 High | — | ✅
| **SC-02** | Docker UFW bypass hardening | — | 🔴 Critical | — | ✅
| **MT-01** | SMART monitoring (smartmontools) | — | 🟡 High | — | ✅
| **MT-02** | Journald size limit config | — | 🟡 High | — | ✅
| **MT-03** | unattended-upgrades (auto security) | — | 🟡 High | — | ✅
| **MT-04** | Docker resource limits per container | — | 🟡 High | — |
| **MT-05** | Docker log rotation per container | — | 🟡 High | — | ✅
| **MT-06** | Container health checks in compose | — | 🟡 High | — | ✅
| **MT-07** | Docker image pinning (digest) | — | 🟢 Medium | — |
| **AU-01** | Ansible config management | 9.1 | 🟢 Medium | — |
| **AU-02** | Docker volume backup script | 9.2 | 🟢 Medium | BK-01 |
| **HW-01** | RAM upgrade 16-32GB — DONE (24GB: 4+8 per channel) | — | ⚪ Hardware | Purchase | ✅
| **HW-02** | Ethernet cable Cat 6 | — | ⚪ Hardware | Purchase |
| **HW-03** | Wi-Fi card → Intel AC 7260 | — | ⚪ Hardware | Purchase |
| **HW-04** | Thermal repaste (Arctic MX-4) | 1.1 | ⚪ One-time | — |
| **HW-05** | Optical bay caddy + 2nd SSD | — | ⚪ Hardware | Purchase |
| **HW-06** | UPS (APC) | — | ⚪ Hardware | Purchase |

### Drop/Deferred
- ~~WireGuard VPN~~ — Tailscale already provides mesh VPN
- ~~Smart Card (9.5)~~ — Niche, low value
- ~~KSM (9.4)~~ — Marginal on 8GB, wait for RAM upgrade — 24GB now, could reconsider

---

## 6. Hardware Upgrades

Hardware upgrade research, pricing, sourcing, and buying tips for Vietnam market moved to dedicated file:

> **[hardware-upgrade-guide.md](hardware-upgrade-guide.md)**

Covers: RAM, Storage, Wi-Fi, CPU, GPU, Networking (USB 2.5GbE), Thermal paste, UPS, Mechanical/Misc, Priority Matrix, Buying Tips, Search Keywords.

---

## 7. Software Roadmap

### High Value (fits 8GB budget)

| Service | RAM | ID | Why |
|---------|-----|----|-----|
| **Fail2ban** | ~10MB | SC-01 | SSH brute-force protection |
| **Gitea** | ~80MB | SV-01 | Self-hosted git server |
| **Homer Dashboard** | ~5MB | SV-02 | Single-page service dashboard |
| **Diun** | ~10MB | SV-03 | Docker image update notifications |
| **Caddy** | ~30MB | SV-04 | Reverse proxy with auto-HTTPS |
| **unattended-upgrades** | ~0MB | MT-03 | Auto security updates |
| **SMART monitoring** | ~5MB | MT-01 | SSD/HDD failure prediction |
| **Docker resource limits** | ~0MB | MT-04 | Prevents OOM on 8GB |
| **Journald size limit** | ~0MB | MT-02 | Prevents OS drive fill-up |
| **Docker UFW bypass fix** | ~0MB | SC-02 | Close container port leak through UFW |
| **Docker log rotation** | ~0MB | MT-05 | Prevent container log disk fill |
| **Container health checks** | ~0MB | MT-06 | Auto-restart on unhealthy state |
| **Docker image pinning** | ~0MB | MT-07 | Use pinned tags/digests, not `:latest` |

### Medium Value (if RAM allows)
| Service | RAM | Why |
|---------|-----|-----|
| **Vaultwarden** | ~30MB | Self-hosted Bitwarden password manager |
| **Watchtower** | ~20MB | Auto-update Docker containers |
| **Calibre-web** | ~100MB | Ebook library management |

### Skip for Now
- **Ollama / Open WebUI** — Needs 16GB+ RAM (possible now — 24GB, but still heavy)
- **Immich** — Needs 8GB+ free RAM (possible now — 24GB)
- **Nextcloud** — Syncthing covers sync needs
- **Jellyfin** — Sandy Bridge can't transcode modern codecs
- **Pelican (Minecraft)** — Only if you actively play

---

## 8. Key Commands (Ubuntu)

### System
```bash
ssh danko@192.168.1.200         # SSH
sudo apt update && sudo apt upgrade -y  # Update all packages
sudo reboot                      # Reboot
sudo journalctl -xe              # System log tail
```

### Network
```bash
ip addr show eno1               # Check Ethernet IP
ip addr show wlp3s0             # Check Wi-Fi IP
ip route                        # Check routing table
sudo netplan try                # Test netplan changes (120s timeout)
sudo netplan apply              # Apply netplan changes
sudo nmcli device status        # Check NetworkManager status
```

### Services
```bash
sudo systemctl status smbd       # Samba status
sudo systemctl restart sshd      # Restart SSH after config change
sudo ufw status verbose          # Firewall rules
sudo unattended-upgrades --dry-run  # Check pending security updates
```

### Docker
```bash
lazydocker                       # TUI Docker manager
docker compose -f ~/docker/navidrome/compose.yaml up -d
docker compose -f ~/docker/pihole/compose.yaml logs -f
docker exec pihole pihole status # Pi-hole v6 uses subcommands
docker exec pihole pihole query  # Check if domain is blocked
docker exec pihole pihole allow  # Whitelist domain
docker exec pihole pihole -g     # Update gravity (blocklists)
```

### Tailscale
```bash
sudo tailscale funnel status     # Check active funnels
sudo tailscale funnel reset      # Clear all funnels
tailscale funnel --bg --set-path=/ 127.0.0.1:8081  # Funnel → Caddy
sudo tailscale serve status      # Check path-based routes
sudo tailscale status            # View connected devices
```

### Gitea
```bash
docker compose -f ~/docker/gitea/compose.yaml logs -f  # Gitea logs
docker exec gitea gitea admin user list                 # List users
```

### Cloudflare Tunnel
```bash
sudo systemctl status cloudflared# Check tunnel status
sudo journalctl -u cloudflared   # Tunnel logs
sudo systemctl start cloudflared # Start tunnel
sudo systemctl stop cloudflared  # Stop tunnel
cloudflared tunnel list          # List tunnels
cloudflared tunnel info navidrome-tunnel  # Tunnel details
```

### Storage
```bash
df -h | grep mnt                 # Mount usage
sudo lvs                         # LVM logical volumes
sudo vgs                         # LVM volume groups
sudo pvs                         # LVM physical volumes
```

### Monitoring
```bash
free -h                           # Memory
htop                              # Process viewer
fastfetch                         # System info
sensors                           # CPU temps + fan speed
sudo smartctl -H /dev/sda         # Disk health
```

---

## 9. Constraints & Conventions

- **User**: `danko` (in sudo + docker groups). No passwordless sudo.
- **Compose files**: All in `~/docker/<service>/compose.yaml` — modern format (no `version:` tag).
- **No snaps**: All packages via `apt` or Docker.
- **No Ubuntu Pro** (free tier available but not used).
- **RAM budget**: 24GB total — each new service should still be verified with `free -h`.
- **Ethernet primary**: eno1 active with static 192.168.1.200/24, Wi-Fi wlp3s0 as automatic failover (metric 600).
- **Static IP only**: 192.168.1.200/24 — DHCP lease released (NW-03).
- **Netplan config**: `/etc/netplan/01-netcfg.yaml` — reference copy in project root (`netplan-01-netcfg.yaml`).
- **Static IP only**: 192.168.1.200/24 — DHCP lease released (NW-03).
- **Pi-hole**: Uses `network_mode: host`. Unbound on 5335, Pi-hole forwards to `127.0.0.1#5335`.
- **Tailscale Funnel**: → Caddy :8081 (not direct to service). Navidrome at root, no auth. Kuma via `/kuma/`, Dockge via `/dockge/`. Pi-hole direct at `:8080/admin/`. Note: Caddy now removed, services on direct ports. Navidrome public via Cloudflare tunnel.
- **Cloudflare tunnel**: Navidrome at https://music.dankofox.quest (→ :4533), Gitea at https://git.dankofox.quest (→ :3000) via cloudflared tunnel. Domain dankofox.quest managed at Cloudflare.
- **Quadro 1000M**: Skipped — no 2026 driver. Using Intel HD 3000 iGPU where needed.
- **Battery**: Charge thresholds unsupported by this model. Monitor for swelling visually.

---

## 10. Plan Files Reference

| File | Purpose |
|------|---------|
| `m4600-server-setup.md` | Thin master plan — TL;DR, phase index, conventions |
| `AGENTS.md` | **← You are here** — KB, specs, inventory, todos, roadmap |
| `HANDOFF.md` | Session handoff — current state, pending, decision log |
| `hardware-upgrade-guide.md` | Vietnam purchase guide with pricing, sources, keywords |
| `netplan-01-netcfg.yaml` | Network config reference (Ethernet primary + Wi-Fi backup) |
| `phase-*.md` (9 files) | Procedural guides per phase |
| `plan_research.md` | Deep research — thermal, LVM, hardware mods |

---

## 11. Future Possibilities (2026)

| Idea | Requires | Coolness |
|------|----------|----------|
| Local AI (Ollama) | 16GB+ RAM | 🤖 |
| Immich (photo backup) | 8GB+ free RAM | 📸 |
| Prometheus + Grafana stack | ~200MB | 📊 |
| 2.5GbE networking | ExpressCard or USB adapter | 🚀 |
| Frigate + Coral TPU | ExpressCard→mini-PCIe adapter | 🎥 |
| Stratum 1 time server | GPS module + PPS | 🕐 |
| Vintage web gateway (FrogFind) | ~50MB | 🦕 |
