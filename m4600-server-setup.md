# M4600 Home Server — Master Plan

## TL;DR

> **Goal**: Transform Dell Precision M4600 (i7-2860QM, 8GB RAM) into a 24/7 home server for learning Linux and hosting lightweight services.
>
> **Status**: 22/41 tasks done → see [AGENTS.md](AGENTS.md#5-progress-dashboard) for full tracker.
>
> **OS**: Ubuntu Server 26.04 LTS
> **User**: `danko` (on server)
> **Network**: Static 192.168.1.200/24 (Wi-Fi wlp3s0)
> **Tailscale**: 100.101.7.123
>
> **Running**: Pi-hole+Unbound, Navidrome, Syncthing, Uptime Kuma, Samba, Tailscale Funnel
> **Critical Gap**: No backups → [BK-01](AGENTS.md#unified-task-id-reference)
>
> **Estimated Effort**: ~15-20 hours total (multi-session)
> **Parallel**: Mostly sequential — storage → OS → Docker → Services → Monitoring → Backups

---

## Critical Path

```
Phase 1: Prep (BIOS, thermal) ─┐
Phase 2: OS Install ───────────┤
Phase 3: Linux Fundamentals ───┤ Sequential
Phase 4: Hardware Mgmt ────────┤
Phase 5: Storage (LVM+Samba) ──┘
                                     ┌── Phase 7: Network (Pi-hole)
Phase 6: Docker ─────────────────────┤
                                     └── Phase 8: Services (Navidrome, Syncthing)
Phase 9: Automation + Monitoring ────┘
         Backups (BK-01) ──── Can start any time after Phase 5
```

---

## Phase File Index

| Phase | File | Purpose |
|-------|------|---------|
| 1. Prep & Assessment | [phase-01-prep.md](phase-01-prep.md) | Physical inspection, BIOS A19, thermal repaste |
| 2. OS Install | [phase-02-os-install.md](phase-02-os-install.md) | Ubuntu Server 26.04 LTS install + post-install |
| 3. Linux Fundamentals | [phase-03-linux-fundamentals.md](phase-03-linux-fundamentals.md) | Static IP, SSH hardening, UFW, users, systemd, apt |
| 4. Hardware Management | [phase-04-hardware-management.md](phase-04-hardware-management.md) | SMM fan control, i8kmon, WOL, lid management |
| 5. Storage Management | [phase-05-storage-management.md](phase-05-storage-management.md) | LVM split, Samba shares, backup |
| 6. Containerization | [phase-06-containerization.md](phase-06-containerization.md) | Docker CE, Compose, Dockge, networking |
| 7. Network Services | [phase-07-network-services.md](phase-07-network-services.md) | Pi-hole+Unbound, Tailscale Funnel |
| 8. Media & Self-Hosted | [phase-08-media-selfhosted.md](phase-08-media-selfhosted.md) | Navidrome, Syncthing, Gitea (pending) |
| 9. Automation | [phase-09-automation.md](phase-09-automation.md) | Ansible, backup scripts, Uptime Kuma |

---

## Memory Management (8GB Constraint)

- **Target**: Keep idle RAM < 4GB, leaving ~4GB for workloads + cache
- **ZRAM**: 3.6GB compressed swap in RAM (enabled by default on Ubuntu)
- **Docker**: Use `--memory` limits per container — mandatory, not optional
- **Incremental**: Add services one at a time, monitor `free -h` after each
- **OOM Priority**: Pi-hole > Navidrome > Syncthing > Uptime Kuma > Gitea > everything else

### Estimated Service Footprint

| Service | RAM | Limits |
|---------|-----|--------|
| Pi-hole + Unbound | ~150MB | 256M |
| Navidrome | ~80MB | 256M |
| Syncthing | ~100MB | 256M |
| Uptime Kuma | ~50MB | 128M |
| Docker infra | ~100MB | — |
| Gitea | ~80MB | 256M |
| Fail2ban | ~10MB | native |
| **Total base** | **~570MB** | |

---

## Conventions

- All services: `~/docker/<service>/compose.yaml`
- Compose files: modern format (no `version:` tag)
- No snaps (native apt or Docker only)
- UFW: default deny, allow only needed ports

---

## Success Criteria

### Verification Commands
```bash
# Core
ssh danko@192.168.1.200          # SSH works
sudo ufw status verbose           # Firewall active
free -h                            # Memory within budget

# Services
curl -sI http://localhost:4533 | head -1   # Navidrome
curl -sI http://localhost:8384 | head -1   # Syncthing
curl -sI http://localhost:8080 | head -1   # Pi-hole
curl -sI http://localhost:3001 | head -1   # Uptime Kuma

# DNS
dig @192.168.1.200 google.com             # Pi-hole+Unbound

# Tailscale
sudo tailscale funnel status              # Funnel active

# Hardware
sensors                                     # Fan/temp control
```

### Final Checklist
- [ ] All critical tasks done (backup, monitoring, DNS config)
- [ ] Services survive `sudo reboot`
- [ ] Remote management via Tailscale + SSH
- [ ] Backups configured and restore-tested
- [ ] Every service has a Uptime Kuma monitor

---

> **Full details**: [AGENTS.md](AGENTS.md) — hardware specs, service inventory, progress, purchase guide, roadmap
> **Session context**: [HANDOFF.md](HANDOFF.md) — current state, pending tasks, decision log
