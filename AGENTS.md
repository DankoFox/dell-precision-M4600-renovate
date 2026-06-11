# M4600 Home Server — Project Knowledge Base

**Generated:** 2026-06-11
**Project:** Dell Precision M4600 → Enterprise-Grade Linux Home Lab Server

## OVERVIEW

Repurposing a Dell Precision M4600 (i7-2860QM, 8GB RAM, Quadro 1000M) as a 24/7 headless Linux home server running Ubuntu Server LTS 26.04. Phased build covering hardware management, containerization, network services, media/self-hosted apps, and automation.

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

- OS: Ubuntu Server LTS 26.04 (headless, no GUI)
- Docker CE + docker-compose-plugin + containerd.io
- Lazydocker (TUI)
- Dockge (web UI at :5001, compose stacks in ~/docker/)
- Samba (smbd, shares: media + data)
- UFW (SSH + Tailscale allowed, default deny)
- Tailscale (100.101.7.123)
- Pi-hole + Unbound (DNS sinkhole + recursive resolver at :8080/admin, HaGeZi Pro blocklist loaded, 1.6M domains blocked)
- dell-bios-fan-control + i8kmon (fan management)
- smbios-utils (battery charge — unsupported, skipped)

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

## PROGRESS (19/41 tasks completed)

- **Phase 1** (3/3): Physical assessment, BIOS A19, USB created
- **Phase 2** (2/2): Ubuntu 26.04 installed, updates done
- **Phase 3** (7/7): Networking, SSH key-only, UFW, users, systemd, apt, monitoring
- **Phase 4** (4/5): Fan control, i8kmon, WOL, lid management. Battery skipped (unsupported)
- **Phase 5** (3/4): LVM setup + split, Samba. Backup (5.3) — not yet done
- **Phase 6** (2/3): Docker CE, Compose plugin, Dockge. Networking deep-dive skipped for now
- **Phase 7** (3/4): Pi-hole + Unbound (DNS sinkhole + recursive resolver) done. Tailscale pre-installed. WireGuard pending.

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
```

## NOTES

- Quadro 1000M Fermi GPU has no 2026 driver support — skipped entirely
- Battery charge thresholds unsupported by this hardware model — skipped
- Ethernet (eno1) shows NO-CARRIER — server runs on Wi-Fi only
- RAM is the primary bottleneck (8GB) — services must be mindful
- Optical bay caddy is a future upgrade path for more storage
