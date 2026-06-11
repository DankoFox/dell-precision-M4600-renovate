# M4600 — Research Findings & Verified Recommendations (2026)

## TL;DR

> **Quick Summary**: Verified research across 6 domains for the Dell Precision M4600 home server (8GB RAM, EndeavourOS). Recommendations changed: **Forgejo** over Gitea, **Caddy** over Nginx Proxy Manager, **Restic** for backup, **Beszel** for monitoring. Pi-hole stays. Arch optimizations documented.
>
> **Key Changes**:
> - Git server: Gitea → **Forgejo** (same RAM, community governance)
> - Reverse proxy: NPM → **Caddy** (5x lighter, auto HTTPS)
> - Monitoring: Uptime Kuma → **Uptime Kuma + Beszel** (system metrics, ~30-50MB)
> - Backup: rsync → **Restic + Backblaze B2** (dedup, encryption, 3-2-1)
> - Keep Pi-hole + Unbound (not worth migrating)
>
> **Estimated Effort**: Medium (multi-session)
> **Parallel Execution**: YES — most services can be deployed independently

---

## Context

This plan documents verified research (June 2026) on alternative software choices and optimizations for the Dell Precision M4600 home server. Each finding includes data sources, comparison tables, and a clear recommendation.

---

## Research Domain 1: DNS Sinkhole

### Pi-hole v6 vs AdGuard Home vs Blocky vs Technitium DNS

**Key Finding**: Pi-hole v6 + Unbound (current) is fine. Not worth migrating.

| Tool | Idle RAM | Docker Image | Web UI | Encrypted DNS | DHCP | Prometheus | Verdict |
|------|----------|-------------|--------|--------------|------|-----------|---------|
| **Pi-hole v6** (current) | ~80-120 MB | ~300 MB | ✅ Rewritten v6 | ❌ Partial (Unbound add-on) | ✅ | ❌ Exporter | KEEP |
| **AdGuard Home** | ~50-80 MB | ~50 MB | ✅ Best-in-class | ✅ DoH/DoT/DoQ | ✅ | ❌ Exporter | BEST alt (save 40MB) |
| **Blocky** | ~25-50 MB | ~15 MB (scratch) | ❌ None (YAML only) | ✅ DoH/DoT | ❌ | ✅ Built-in | Too minimal (no UI) |
| **Technitium DNS** | ~150-300 MB | ~250 MB | ✅ .NET | ✅ All | ✅ | ❌ | Overkill for homelab |

### Recommendation
**STAY with Pi-hole v6 + Unbound.** It's already deployed, working well (1.6M domains blocked). AdGuard Home would save ~40MB RAM and eliminate the Unbound container, but the migration effort isn't worth it. If RAM becomes critical later, switch to AdGuard Home then.

**Sources**:
- selfhosting.sh "Best Self-Hosted Ad Blockers 2026"
- selfhosting.sh "Pi-hole vs AdGuard Home vs Blocky 2026"
- ossalt.com "Pi-hole vs AdGuard Home vs Blocky 2026"

---

## Research Domain 2: Git Server

### Gitea vs Forgejo vs GitLab CE vs Soft Serve

**Key Finding**: Forgejo is the best choice. Same RAM as Gitea, community-governed, future-facing.

| Tool | Idle RAM | Web UI | CI/CD | Container Registry | Governance |
|------|---------|--------|-------|-------------------|-----------|
| **Forgejo** (⭐RECOMMENDED) | ~80-170 MB | ✅ Forgejo | ✅ Forgejo Actions | ✅ OCI | Non-profit (Codeberg e.V.) |
| **Gitea** | ~80-170 MB | ✅ Gitea | ✅ Gitea Actions | ✅ OCI | For-profit (Gitea Ltd.) |
| **OneDev** | ~300 MB | ✅ | ✅ Built-in YAML | ❌ | Single maintainer |
| **GitLab CE** | 4 GB+ (min) | ✅ GitLab | ✅ GitLab CI | ✅ | Open core — **NOT suitable** |
| **Soft Serve** | ~10 MB | ❌ TUI | ❌ | ❌ | CLI-only, no web UI |

### Recommendation
**Use Forgejo.** Gitea and Forgejo are functionally identical — same Go codebase, same ~80-170MB RAM, same API. The difference is governance: Forgejo is run by Codeberg non-profit, Gitea by Gitea Ltd (for-profit). Forgejo also has federation roadmap (ActivityPub/ForgeFed). Migration between them is trivial (same config format).

GitLab CE is NOT suitable — requires 4GB RAM minimum, 8GB recommended. On this server's 8GB budget, GitLab would consume more than half the available RAM.

### Install Notes
- Docker: `codeberg.org/forgejo/forgejo:8`
- Database: SQLite for personal use (no need for PostgreSQL)
- Reverse proxy: Caddy in front of Forgejo

**Sources**:
- selfhosting.sh "Gitea vs Forgejo" (2026-02)
- ossalt.com "Gitea vs Forgejo Lightweight Git 2026"
- selfhosting.sh "Best Self-Hosted Git Platforms 2026"
- serverspan.com "2026 Guide to Self-Hosted Git"
- forgejo.org "Compare with other Forges"

---

## Research Domain 3: Backup Solutions

### Restic vs Borg vs Kopia vs rsync

**Key Finding**: Restic is the best choice. Most versatile, native cloud backends, good dedup for music files.

| Tool | RAM (during backup) | Cloud Backends | Dedup | Encryption | Single-File Restore | Maturity |
|------|-------------------|---------------|-------|-----------|-------------------|---------|
| **Restic** (⭐RECOMMENDED) | ~100-200 MB | 20+ (B2 native, S3, SFTP) | ✅ Content-defined | ✅ AES-256 CTR | ✅ Fast | High |
| **Borg** | ~200-500 MB | ❌ SSH only (rclone for cloud) | ✅ Best-in-class | ✅ AES-256 | ✅ Fast | Very High |
| **Kopia** | ~200-300 MB | Many (B2, S3, SFTP, WebDAV) | ✅ Content-defined | ✅ AES-256-GCM | ✅ Fast | Medium (evolving) |
| **rsync + cron** | Minimal | Any (mount) | ❌ None | ❌ Manual | ✅ | Very High |

### Recommendation
**Use Restic with Backblaze B2.** 

Rationale:
- Native B2 support — no rclone sidecar needed
- ~100-200MB RAM during backup (only while running, not idle)
- Content-defined dedup works well for music (static files, some overlap)
- AES-256 encryption by default
- Cost: ~$1.20/month for 200GB on B2 ($6/TB/mo × 0.2TB)
- Single Go binary — available on AUR as `restic`
- Schedule via systemd timer (preferred over cron on Arch)

### Backup Strategy (3-2-1)
1. **Primary**: Local backup to external drive (rsync or restic) — fast recovery
2. **Offsite**: Restic to Backblaze B2 — disaster recovery
3. **Configs**: Git-backed (Forgejo handles this)
4. **Docker volumes**: Stop containers → backup volume directories → restart

### System Snapshots
- **Snapper** (btrfs) — if OS disk is btrfs. EndeavourOS uses ext4 by default.
- **Timeshift** — rsync-based, good for system state. Install from AUR.
- Schedule: daily snapshots, keep 5-7.

### Schedule
```
# systemd timer: restic-backup.timer
[Unit]
Description=Daily restic backup

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

**Sources**:
- computingforgeeks.com "Borg vs Restic vs Kopia Benchmarks" (March 2026)
- selfhosting.sh "Restic vs Kopia vs BorgBackup: Best Backup Tool" (Jan 2026)
- createinnovateexplore.com "Borg, Restic, Kopia: benchmarks on 500 GB" (Apr 2026)
- selfhosting.sh "Best Self-Hosted Backup Solutions 2026"

---

## Research Domain 4: Monitoring Stack

### Uptime Kuma vs Beszel vs Netdata vs Prometheus+Grafana

**Key Finding**: Keep Uptime Kuma for availability. Add Beszel for system metrics. Combined total < 200MB RAM.

| Tool | Idle RAM | Focus | Alerts | Status Pages | Setup Complexity |
|------|---------|-------|--------|-------------|-----------------|
| **Uptime Kuma** (KEEP) | ~60-100 MB | Service availability (HTTP/TCP/DNS) | 90+ channels | ✅ Yes | Very easy |
| **Beszel** (⭐ADD) | ~30-50 MB hub + ~10MB/agent | System metrics (CPU/RAM/disk/Docker) | Email, webhook, ntfy | ❌ | Very easy |
| **Netdata** | ~150-300 MB | Deep real-time system metrics | 300+ preconfigured | ❌ | Moderate |
| **Prometheus+Grafana** | ~800 MB+ | Full observability | Full stack | ✅ Custom | Complex |

### Comparison: Uptime Kuma + Beszel vs Full Stack

| Metric | Uptime Kuma + Beszel | Prometheus + Grafana | Netdata alone |
|--------|-------------------|---------------------|---------------|
| Total RAM | ~150-180 MB | ~800 MB+ | ~300 MB |
| Setup time | ~30 minutes | ~2-4 hours | ~15 minutes |
| Monitors | Availability + system health | Everything | Everything deep |
| Retention | SQLite + PocketBase | Configurable | Custom DB engine |

### Recommendation
**Keep Uptime Kuma + add Beszel.** Combined overhead is ~150-180MB for a homelab-sized deployment. This gives you:
- Uptime Kuma: "Is the service up?" + 90+ notification channels + status pages
- Beszel: "Why is the server slow?" + per-container Docker stats + historical charts

Skip Netdata (300MB, overkill for one server). Skip Prometheus+Grafana (800MB+, not worth it for homelab).

### Beszel Deployment
```
# Docker Compose
services:
  beszel:
    image: henrygd/beszel:latest
    ports:
      - "9400:9400"
    volumes:
      - ./data:/beszel/data
    restart: unless-stopped
```

**Sources**:
- selfhosting.sh "Uptime Kuma vs Beszel" (Jan 2026)
- selfhosting.sh "Netdata vs Beszel" (Jan 2026)
- ossalt.com "Self-Host Beszel" (Mar 2026)
- virtua.cloud "Self-Host Uptime Kuma & Beszel" (Mar 2026)

---

## Research Domain 5: Reverse Proxy

### Caddy vs Nginx Proxy Manager vs Traefik vs Tailscale Serve

**Key Finding**: Caddy is the best option. 20-40MB RAM, auto HTTPS, 2-line config per service.

| Tool | Idle RAM | Config Style | Auto HTTPS | HTTP/3 | Docker Integration | Learning Curve |
|------|---------|-------------|-----------|--------|-------------------|----------------|
| **Caddy** (⭐RECOMMENDED) | ~20-40 MB | Caddyfile (2 lines/service) | ✅ **Automatic, zero config** | ✅ Built-in | Manual (add to Caddyfile) | Low |
| **Nginx Proxy Manager** | ~100-150 MB | Web UI (point-and-click) | ✅ Per-host toggle | ❌ | Manual (via GUI) | Very low |
| **Traefik** | ~50-80 MB | Docker labels + YAML | ✅ | ✅ Experimental | ✅ Native auto-discovery | Medium-high |
| **Tailscale Serve** (current) | 0 (already running) | CLI commands | ✅ Via Tailscale | ❌ | Manual | Low |

### Caddy vs NPM: RAM Comparison
| Metric | Caddy | Nginx Proxy Manager |
|--------|-------|-------------------|
| Idle RAM | ~20-40 MB | ~100-150 MB |
| Under load | ~50-100 MB | ~200-300 MB |
| Docker image size | ~40 MB | ~400 MB |
| Stack | Single Go binary | Nginx + Node.js + SQLite |

### Recommendation
**Use Caddy.** It's 5x lighter than Nginx Proxy Manager (20-40MB vs 100-150MB), has automatic HTTPS with zero configuration, HTTP/3 built-in, and the Caddyfile can be version-controlled in git.

Example Caddyfile:
```
pihole.${DOMAIN} {
    reverse_proxy localhost:8080
}

music.${DOMAIN} {
    reverse_proxy localhost:4533
}

kuma.${DOMAIN} {
    reverse_proxy localhost:3001
}
```

That's it — Caddy auto-provisions Let's Encrypt certs, handles renewal, redirects HTTP to HTTPS.

**When to NOT use Caddy**: If you prefer a web UI over config files (use NPM). If you spin up containers constantly (use Traefik).

**Sources**:
- selfhosting.sh "Nginx Proxy Manager vs Caddy" (Jan 2026)
- homelabstarter.com "Reverse Proxy Comparison: Traefik vs Caddy vs NPM" (Feb 2026)
- budgethomelab.com "NPM vs Caddy vs Traefik" (May 2026)
- selfhostsetup.com "Best Reverse Proxy for Beginners" (Feb 2026)

---

## Research Domain 6: Arch Optimizations

### Memory Optimizations

**ZRAM Tuning** (for 8GB system):
```
# /etc/sysctl.d/99-zram.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

These values are what Pop!_OS uses for zram systems. High swappiness is correct for in-memory swap (zram is orders of magnitude faster than disk swap).

**ZRAM Generator config**:
```
# /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
```

**systemd-oomd**:
```bash
sudo systemctl enable --now systemd-oomd.service
```
Uses cgroups-v2 and PSI to automatically kill the worst-offending process before the system OOMs. Essential for an 8GB system running Docker.

### CPU Optimizations

**Scaling governor**:
```bash
sudo pacman -S cpupower
sudo cpupower frequency-set -g schedutil
sudo systemctl enable cpupower.service
```
`schedutil` is the modern default — it uses scheduler utilization data for fast frequency scaling. For a 24/7 server, this balances performance and power.

**Disable unnecessary kernel modules** (headless server):
```
# /etc/modprobe.d/blacklist.conf
blacklist bluetooth
blacklist btusb
blacklist snd_hda_intel  # audio (headless)
blacklist uvcvideo       # webcam (not present)
```

### Storage Optimizations

**Mount options**:
```
# /etc/fstab — SSD (OS)
/dev/sdb3 / ext4 defaults,noatime,discard 0 1

# /etc/fstab — HDD (data)
/dev/vg_data/lv_storage /mnt/media ext4 defaults,noatime 0 0
/dev/vg_data/data_lv /mnt/data ext4 defaults,noatime 0 0
```

**I/O schedulers**:
```bash
# SSD (sdb — mSATA): use mq-deadline (good for NAND)
echo mq-deadline | sudo tee /sys/block/sdb/queue/scheduler

# HDD (sda — rotating): use bfq (good for mechanical)
echo bfq | sudo tee /sys/block/sda/queue/scheduler
```

Make permanent via udev rule:
```
# /etc/udev/rules.d/60-iosched.rules
ACTION=="add|change", KERNEL=="sdb", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sda", ATTR{queue/scheduler}="bfq"
```

**TRIM**: Enable periodic trim for SSD:
```bash
sudo systemctl enable fstrim.timer
```

**Journald limits**:
```
# /etc/systemd/journald.conf
SystemMaxUse=500M
MaxFileSec=1week
```

### Network Optimizations

**Wi-Fi power save**: Critical for server reliability
```bash
# Create systemd service
# /etc/systemd/system/wifi-power-save.service
[Unit]
Description=Disable Wi-Fi power saving
After=network.target

[Service]
Type=oneshot
ExecStart=iw dev wlp3s0 set power_save off
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**TCP tuning**:
```
# /etc/sysctl.d/99-network.conf
net.core.somaxconn = 1024
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
```

### Maintenance

**pacman cache cleanup**:
```bash
sudo systemctl enable paccache.timer
# Cleans old package versions daily, keeps last 2
```

**AUR helper**: `paru` (Rust-based) over `yay` (Go-based)
```bash
sudo pacman -S paru
# paru is faster, better security design, actively maintained
```

**Docker resource limits**:
```
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-runtime": "runc"
}
```

**Sources**:
- ArchWiki: Improving Performance, Zram, CPU frequency scaling
- ArchWiki: systemd-oomd, zram-generator
- Arch man pages: systemd-oomd(8), zram-generator.conf(5)
- dev.to "Stop Hitting Swap Too Late: Practical zram" (Apr 2026)

---

## Execution Plan

### Wave 1 (Immediate — System Optimizations)
1. Apply ZRAM tuning sysctl values
2. Enable systemd-oomd.service
3. Apply storage optimizations (mount options, I/O scheduler, TRIM, journald)
4. Disable Wi-Fi power saving
5. Enable paccache.timer
6. Set up Docker daemon log limits

### Wave 2 (Backup — Critical)
7. Install restic (pacman)
8. Create Backblaze B2 bucket + app key
9. Create restic init + backup script
10. Create systemd timer for daily backup
11. Test restore

### Wave 3 (Monitoring)
12. Configure Uptime Kuma monitors (Pi-hole, Navidrome, Syncthing, SSH, DNS)
13. Deploy Beszel (Docker Compose)

### Wave 4 (Self-Hosted Services)
14. Deploy Forgejo (Docker Compose)
15. Deploy Caddy (Docker Compose as reverse proxy)
16. Deploy Homer Dashboard (Docker)
17. Install fail2ban (pacman)

### Wave 5 (Optional — When Ready)
18. Deploy Vaultwarden (Docker)
19. Deploy Lidarr + Prowlarr (Docker)
20. Deploy Calibre-web (Docker)

### Estimated RAM Budget After All Waves
| Service | RAM |
|---------|-----|
| OS + system services | ~500 MB |
| Docker engine | ~200 MB |
| Pi-hole + Unbound | ~120 MB |
| Navidrome | ~100 MB |
| Syncthing | ~100 MB |
| Uptime Kuma | ~80 MB |
| Beszel | ~40 MB |
| Caddy | ~30 MB |
| Forgejo | ~150 MB |
| Homer | ~10 MB |
| fail2ban | ~10 MB |
| **Total estimated** | **~1.3-1.5 GB** |
| **Remaining for cache/workloads** | **~6.5 GB** |

---

## Success Criteria

- [ ] All ZRAM + sysctl optimizations applied and verified (`zramctl`, `sysctl vm.swappiness`)
- [ ] systemd-oomd running (`systemctl status systemd-oomd`)
- [ ] Storage optimized (noatime mount, correct I/O scheduler, TRIM timer)
- [ ] Wi-Fi power save disabled (`iw dev wlp3s0 get power_save` → off)
- [ ] pacman cache auto-cleaning active (`systemctl status paccache.timer`)
- [ ] Restic backup working: local + B2 (`restic snapshots`)
- [ ] Restore tested: single file restore works
- [ ] Uptime Kuma monitors configured and sending alerts
- [ ] Beszel showing system metrics for all monitored hosts
- [ ] Forgejo accessible via Caddy reverse proxy with valid HTTPS
- [ ] fail2ban active and monitoring SSH
- [ ] All services restart after reboot (`sudo reboot` test)
