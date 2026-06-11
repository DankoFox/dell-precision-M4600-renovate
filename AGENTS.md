# M4600 Home Server — Project Knowledge Base

**Generated:** 2026-06-11 (refactored)
**Project:** Dell Precision M4600 → Enterprise-Grade Linux Home Lab Server
**OS:** Ubuntu Server 26.04 LTS
**User:** `danko`
**Network:** 192.168.1.200/24 (Wi-Fi wlp3s0)
**Tailscale:** 100.101.7.123

---

## 1. Hardware Specs

| Component | Spec | Notes |
|-----------|------|-------|
| **CPU** | Intel Core i7-2860QM (4C/8T, Sandy Bridge, 2.5-3.6 GHz) | Unlocks all 4 DIMM slots |
| **RAM** | 8GB DDR3 (2× 4GB?) + ZRAM (3.6G) | 4× SO-DIMM slots, max 32GB |
| **GPU** | NVIDIA Quadro 1000M (Fermi) — **skipped** | No driver support in 2026; using Intel HD 3000 iGPU |
| **Storage (OS)** | 120GB SAMSUNG PM871 mSATA → `/` | SATA III |
| **Storage (Data)** | 447GB GIGABYTE SATA → LVM `vg_data` | Split: lv_storage (200G) + data_lv (247G) |
| **Optical** | DVD-RW (9.5mm SATA) | Replaceable with caddy for 3rd drive |
| **Wi-Fi** | Intel Centrino Advanced-N 6200 (half mini-PCIe, 802.11 a/b/g/n) | No AC — upgrade candidate |
| **Ethernet** | Intel 82579LM Gigabit (eno1) | Shows NO-CARRIER (no cable plugged) |
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
| Uptime Kuma | 3001 | ✅ bridge | ✅ Running (no monitors) | ~50MB | `~/docker/uptime-kuma/` |
| Samba (smbd) | 445 | ❌ native | ✅ Working | ~30MB | `/etc/samba/smb.conf` |
| Tailscale | 100.101.7.123 | ❌ native | ✅ Working | ~40MB | `/etc/default/tailscale` |
| Dockge | 5001 | ✅ bridge | ✅ Working | ~30MB | `~/docker/dockge/` |
| Lazydocker | TUI | ❌ native | ✅ Installed | — | — |
| **Total running** | | | | **~480MB** | |

---

## 4. Progress Dashboard

### Phase Summary

| Phase | Tasks | Done | % | Top Pending |
|-------|-------|------|---|-------------|
| 1. Prep & Assessment | 3 | 3 | 100% | — |
| 2. OS Install | 2 | 2 | 100% | — |
| 3. Linux Fundamentals | 7 | 7 | 100% | — |
| 4. Hardware Management | 5 | 5 | 100% | — |
| 5. Storage Management | 4 | 3 | 75% | **BK-01**: Backup strategy |
| 6. Containerization | 3 | 2 | 67% | Networking deep-dive |
| 7. Network Services | 3 | 2 | 67% | **NW-01**: Router DNS config |
| 8. Media & Self-Hosted | 6 | 2 | 33% | **SV-01**: Gitea |
| 9. Automation | 6 | 1 | 17% | **BK-02**: Uptime Kuma monitors |
| **Total** | **38** | **27** | **71%** | |

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

#### Phase 5 — Storage Management (3/4)
- [x] 5.1a LVM setup (vg_data)
- [x] 5.1b LVM split (lv_storage + data_lv)
- [x] 5.2 Samba shares
- [ ] **BK-01**: Backup strategy (restic + cron) ← 🔴

#### Phase 6 — Containerization (2/3)
- [x] 6.1 Docker CE install
- [x] 6.2 Docker Compose + Dockge UI
- [ ] 6.3 Container networking deep-dive (deferred)

#### Phase 7 — Network Services (2/3)
- [x] 7.1 Pi-hole + Unbound
- [ ] **NW-01**: Router DNS config (fix Pixel bypass) ← 🟡
- [x] 7.4 Tailscale Funnel (Navidrome public)

#### Phase 8 — Media & Self-Hosted (2/6)
- [ ] 8.1 Jellyfin — *on hold (Sandy Bridge too weak for HEVC)*
- [ ] 8.2 Pelican (Minecraft)
- [ ] 8.3 ARM (CD ripping)
- [ ] **SV-01**: Gitea (~80MB RAM) ← 🟡
- [x] 8.5 Navidrome
- [x] 8.6 Syncthing

#### Phase 9 — Automation (1/6)
- [ ] **AU-01**: Ansible config management
- [ ] **AU-02**: Docker backup scripts
- [x] 9.3 Uptime Kuma deployed
- [ ] **BK-02**: Configure Uptime Kuma monitors ← 🔴
- [ ] 9.4 KSM — *deferred until RAM upgrade*
- [ ] 9.5 Smart Card — *low value, deferred*

---

## 5. Unified Task ID Reference

Cross-ref between AGENTS.md progress, HANDOFF.md pending tasks, and session plans.

| ID | Description | Phase Ref | Priority | Depends On |
|----|-------------|-----------|----------|------------|
| **BK-01** | Backup strategy (restic + cron) | 5.3 | 🔴 Critical | Phase 5 done |
| **BK-02** | Configure Uptime Kuma monitors | 9.3b | 🔴 Critical | Phase 9 started |
| **NW-01** | Router DNS → 192.168.1.200 (fix Pixel) | 7.2 | 🟡 High | — |
| **SV-01** | Gitea self-hosted git | 8.4 | 🟡 High | Docker ready |
| **SC-01** | Fail2ban SSH protection | — | 🟡 High | — |
| **MT-01** | SMART monitoring (smartmontools) | — | 🟡 High | — |
| **MT-02** | Journald size limit config | — | 🟡 High | — |
| **MT-03** | unattended-upgrades (auto security) | — | 🟡 High | — |
| **MT-04** | Docker resource limits per container | — | 🟡 High | — |
| **SV-02** | Homer dashboard | — | 🟢 Medium | BK-01, BK-02 done |
| **NW-02** | IPv6 DNS config (fix Pixel DoT) | — | 🟢 Medium | NW-01 |
| **AU-01** | Ansible config management | 9.1 | 🟢 Medium | — |
| **AU-02** | Docker volume backup script | 9.2 | 🟢 Medium | BK-01 |
| **SV-03** | Diun (Docker update notifier) | — | 🟢 Medium | — |
| **HW-01** | RAM upgrade 16-32GB | — | ⚪ Hardware | Purchase |
| **HW-02** | Ethernet cable Cat 6 | — | ⚪ Hardware | Purchase |
| **HW-03** | Wi-Fi card → Intel AC 7260 | — | ⚪ Hardware | Purchase |
| **HW-04** | Thermal repaste (Arctic MX-4) | 1.1 | ⚪ One-time | — |
| **HW-05** | Optical bay caddy + 2nd SSD | — | ⚪ Hardware | Purchase |
| **HW-06** | UPS (APC) | — | ⚪ Hardware | Purchase |

### Drop/Deferred
- ~~WireGuard VPN~~ — Tailscale already provides mesh VPN
- ~~Cloudflare Tunnel~~ — Tailscale Funnel fills the need
- ~~Smart Card (9.5)~~ — Niche, low value
- ~~KSM (9.4)~~ — Marginal on 8GB, wait for RAM upgrade

---

## 6. Hardware Upgrades — Vietnam Purchase Guide

| Item | Model | Est. VND | Where to Buy | Priority |
|------|-------|----------|-------------|----------|
| **Thermal paste** | Arctic MX-4 (4g) — non-conductive, 8.5 W/mK | ~80k-120k | TPassion.vn, Shopee, Lazada | ⚪ One-time |
| **Ethernet cable** | Cat 6 UTP 5m (AMP, KingSpec) | ~30k-60k | Any electronics shop, Shopee | 🔴 HIGH |
| **Wi-Fi card** | Intel AC 7260HMW (half mini-PCIe, AC+BT4.0) | ~150k-250k | Siêu Thị Điện Máy Xanh, Shopee | 🟡 MEDIUM |
| **RAM 8GB DDR3L** | Crucial CT102464BF160B or Kingston KVR16S11/8 | ~350k-500k/stick | MemoryZone.vn, Phong Vũ, Shopee, Lazada | 🔴 HIGH |
| **RAM kit 16GB** | Crucial CT2KIT102464BF160B (2×8GB DDR3L-1600) | ~700k-1M | Crucial disti, Shopee, Lazada | 🔴 HIGH |
| **RAM 32GB (4×8GB)** | 4× Crucial 8GB DDR3L-1600 | ~1.4M-2M | Mix from sellers above | 🟡 MEDIUM |
| **Optical bay caddy** | Universal 9.5mm SATA caddy for Dell Precision M4600 | ~80k-200k | Shopee, Lazada | 🟢 LOW |
| **2.5" SATA SSD 500GB** | Crucial BX500 / Samsung 870 EVO | ~500k-800k | Phong Vũ, An Phát | 🟢 LOW |
| **UPS** | APC BVX1200LI-MS (1200VA/720W, AVR) | ~2.2M-2.8M | Hàng Chính Hiệu, An Phát | 🟡 MEDIUM |
| **UPS (budget)** | APC BX650LI-MS (650VA/325W) | ~1.2M-1.5M | Phong Vũ, An Phát | 🟢 LOW |
| **2.5GbE USB** | USB 3.0 → 2.5GbE (Realtek RTL8156) | ~400k-700k | Lazada, Shopee | ⚪ Deferred |

### Buying Tips for Vietnam
- **RAM**: Buy DDR3L (1.35V) — runs cooler, works in all slots. Verify with seller before ordering.
- **Wi-Fi card**: Ensure **half-height** bracket (model ends in `HMW`). The M4600 does NOT fit full-height.
- **Arctic MX-4**: Check QR code on box — counterfeits exist on Shopee. Buy from TPassion or major resellers.
- **Caddy**: Search `"khay ổ cứng 9.5mm Dell Precision M4600"`. The universal Dell caddy works; snap your original bezel onto it.
- **UPS**: Models with **AVR** (Automatic Voltage Regulation) are strongly recommended for Vietnam's fluctuating power. The BVX1200 has AVR; the BX650 does not.

---

## 7. Software Roadmap

### High Value (fits 8GB budget)

| Service | RAM | ID | Why |
|---------|-----|----|-----|
| **Fail2ban** | ~10MB | SC-01 | SSH brute-force protection |
| **Gitea** | ~80MB | SV-01 | Self-hosted git server |
| **Homer Dashboard** | ~5MB | SV-02 | Single-page service dashboard |
| **Diun** | ~10MB | SV-03 | Docker image update notifications |
| **unattended-upgrades** | ~0MB | MT-03 | Auto security updates |
| **SMART monitoring** | ~5MB | MT-01 | SSD/HDD failure prediction |
| **Docker resource limits** | ~0MB | MT-04 | Prevents OOM on 8GB |
| **Journald size limit** | ~0MB | MT-02 | Prevents OS drive fill-up |

### Medium Value (if RAM allows)
| Service | RAM | Why |
|---------|-----|-----|
| **Nginx Proxy Manager** | ~50MB | Reverse proxy with auto-SSL |
| **Vaultwarden** | ~30MB | Self-hosted Bitwarden password manager |
| **Watchtower** | ~20MB | Auto-update Docker containers |
| **Calibre-web** | ~100MB | Ebook library management |

### Skip for Now
- **Ollama / Open WebUI** — Needs 16GB+ RAM
- **Immich** — Needs 8GB+ free RAM
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
sudo tailscale funnel --bg 4533  # Expose port via Funnel
sudo tailscale serve status      # Check path-based routes
sudo tailscale status            # View connected devices
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
- **RAM budget**: 8GB total — each new service must be verified with `free -h`.
- **Wi-Fi only**: eno1 has NO-CARRIER unless ethernet cable is plugged.
- **Dual IP**: Static 192.168.1.200 + DHCP lease 192.168.1.7 — can release DHCP.
- **Pi-hole**: Uses `network_mode: host`. Unbound on 5335, Pi-hole forwards to `127.0.0.1#5335`.
- **Tailscale Funnel**: Navidrome at root, no auth. Pi-hole and Uptime Kuma internal-only.
- **Quadro 1000M**: Skipped — no 2026 driver. Using Intel HD 3000 iGPU where needed.
- **Battery**: Charge thresholds unsupported by this model. Monitor for swelling visually.

---

## 10. Plan Files Reference

| File | Purpose |
|------|---------|
| `m4600-server-setup.md` | Thin master plan — TL;DR, phase index, conventions |
| `AGENTS.md` | **← You are here** — KB, specs, inventory, todos, roadmap |
| `HANDOFF.md` | Session handoff — current state, pending, decision log |
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
