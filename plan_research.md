# M4600 — Deep Technical Research

Research notes on repurposing the Dell Precision M4600 as a 24/7 Linux home server.

---

## 1. Thermal Control — SMM Fan Management

### Problem
Dell BIOS firmware uses System Management Mode (SMM) fan curves optimized for quiet laptop use, not sustained server workloads. Under continuous CPU load, the BIOS keeps fans too low → CPU throttles at 85-90°C → performance drops.

### Solution
Override BIOS fan control and use a user-space daemon.

```bash
# Build the BIOS bypass tool
git clone https://github.com/TomFreudenberg/dell-bios-fan-control.git
cd dell-bios-fan-control
make
sudo cp dell-bios-fan-control /usr/local/bin/

# Disable BIOS control
sudo dell-bios-fan-control 0
```

**Risk**: If no monitoring tool is running, fans stay off and CPU can overheat. Always pair with `i8kmon`.

### Fan Curve (i8kmon)

| State | Fan Speed | Temp Down | Temp Up | Behavior |
|-------|-----------|-----------|---------|----------|
| 0 | Off | — | 50°C | Silent below 50°C |
| 1 | Low | 42°C | 68°C | Normal operation band |
| 2 | High | 60°C | 128°C | Max cooling above 68°C |

Tcl config in `/etc/i8kutils/i8kmon.conf`:
```
set config(0)  {{0 0}  -1  50  -1  50}
set config(1)  {{1 1}  42  68  42  68}
set config(2)  {{2 2}  60 128  60 128}
```

### Kernel Module
```bash
# /etc/modules-load.d/dell-smm-hwmon.conf
dell_smm_hwmon

# /etc/modprobe.d/dell-smm-hwmon.conf
options dell_smm_hwmon ignore_dmi=1 restricted=1 power_status=1
```

### Reference
- T. Freudenberg. *dell-bios-fan-control*. GitHub. [https://github.com/TomFreudenberg/dell-bios-fan-control](https://github.com/TomFreudenberg/dell-bios-fan-control)
- Coreboot for Sandy Bridge: limited M4600 support; alternative for full SMM control.

---

## 2. Memory Architecture — Dell Precision M4600

### RAM Slot Configuration

| CPU Type | DIMM Slots | Max RAM |
|----------|-----------|---------|
| Dual-core (i5-2520M, i7-2620M) | 2 slots | 16GB |
| **Quad-core (i7-2720QM/2760QM/2820QM/2860QM)** | **4 slots** | **32GB** |

Your i7-2860QM = **all 4 DIMM slots unlocked**.

### Compatible Memory
| Spec | Value |
|------|-------|
| Form factor | 204-pin SO-DIMM |
| Type | DDR3 / DDR3L |
| Speed | 1333MHz or 1600MHz |
| Max per slot | 8GB (2Rx8) |
| Voltage | 1.35V (DDR3L) or 1.5V (DDR3) |
| ECC | Non-ECC only |

**DDR3L (1.35V) recommended** — runs cooler, critical for 24/7 operation.

### Upgrade Paths
| Config | Slots Used | Total | Cost (VN) |
|--------|-----------|-------|-----------|
| Keep current | 2×4GB | 8GB | Free |
| Budget | 2×8GB | 16GB | ~700k-1M |
| Max | 4×8GB | 32GB | ~1.4M-2M |

### ZRAM Configuration
Ubuntu Server 26.04 enables ZRAM by default (3.6GB compressed swap in RAM). Verify:
```bash
zramctl
```
Tuning: edit `/etc/default/zramswap` or `/usr/lib/systemd/zram-generator.conf`.

**Compression ratio** depends on data type:
- Text/JSON: 3:1–5:1
- Binary: 1.5:1–2:1
- Already-compressed (mp3, jpg, zip): 1:1 or worse

For server workloads, ZRAM is effective because config files and logs compress very well.

---

## 3. Storage Architecture — LVM Research

### Layout Decision

```mermaid
graph TD
    A[sda 447GB GIGABYTE] --> B[vg_data]
    B --> C[lv_storage 200G]
    B --> D[data_lv 247G]
    C --> E[/mnt/media]
    D --> F[/mnt/data]
```

### Why LVM Split
| Use Case | Volume | Mount |
|----------|--------|-------|
| Media (music, Jellyfin) | lv_storage | /mnt/media |
| Data (backups, Samba) | data_lv | /mnt/data |

Benefits:
- Independent snapshots: snapshot `/mnt/data` before risky backup, don't snapshot `/mnt/media`
- No space competition: a backup filling `/mnt/data` won't crash Navidrome on `/mnt/media`
- Different mount options: `/mnt/media` can be `noexec,nodev` later

### Practice: Extend a Volume
```bash
# If you add storage later:
# Extend vg_data PV
sudo pvcreate /dev/sdb
sudo vgextend vg_data /dev/sdb

# Extend lv_storage
sudo lvextend -L +100G /dev/vg_data/lv_storage
sudo resize2fs /dev/vg_data/lv_storage  # online resize, no unmount needed
```

### Optical Bay Caddy (9.5mm SATA)
The DVD-RW connects via SATA III. Replace with a caddy:
- Search: "khay ổ cứng 9.5mm Dell Precision M4600"
- Accepts any 2.5" SATA drive (SSD or HDD)
- Retains the original faceplate/bezel
- Hot-swap: not supported (electrical, but don't)

### mSATA Slot
The mSATA slot accepts half-size or full-size mSATA cards.
- Current: 120GB SAMSUNG PM871 (SATA III)
- Upgrade: up to 1TB if needed, but the 120GB is sufficient for OS only

---

## 4. GPU Research — Quadro 1000M (Fermi)

### Conclusion: Skip entirely
- **Latest driver**: NVIDIA 390xx legacy branch (EOL 2022)
- **CUDA**: 9.x only (modern workloads need CUDA 11+)
- **NVENC**: H.264 only (no HEVC/H.265, no AV1)
- **Linux kernel**: 390xx fails to compile on kernels > 6.2 (Ubuntu 26.04 runs 6.8+)
- **Wayland**: No support (Ubuntu 26.04 defaults to Wayland)
- **No 2026 driver support** — confirmed by NVIDIA's legacy driver page

### Use Intel HD 3000 iGPU Instead
| Feature | Intel HD 3000 | Quadro 1000M |
|---------|---------------|--------------|
| VA-API | ✅ Yes | ❌ No |
| Kernel driver | Built-in (i915) | Legacy 390xx (EOL) |
| Headless | ✅ Works | ❌ Requires X11 |
| Power drain | ~2W | ~25W |
| Hardware decode | H.264, MPEG-2 | H.264 only |

The Intel HD 3000 is used for VA-API transcoding in Docker (Jellyfin/Plex). Even though Sandy Bridge can only decode H.264, this is sufficient for a direct-play-first strategy.

---

## 5. Network — Wi-Fi vs Ethernet

### eno1 (Ethernet)
| Status | Details |
|--------|---------|
| Interface | Intel 82579LM Gigabit |
| Current | NO-CARRIER (no cable) |
| WOL | Configured via systemd service |
| Cable | Cat 6 UTP, any length needed |

Wi-Fi is the current bottleneck. The Intel Centrino N-6200 is limited to 300Mbps theoretical (real-world ~150Mbps). Upgrade options:

| Option | Cost (VN) | Speed | Notes |
|--------|-----------|-------|-------|
| Cat 6 cable (£5) | ~50k | 1Gbps | Best, simplest |
| Intel AC 7260HMW | ~200k | 867Mbps AC | Better Wi-Fi, adds BT 4.0 |
| USB 2.5GbE adapter | ~500k | 2.5Gbps | Works via USB 3.0 |

### Wi-Fi Card Upgrade
The M4600 uses **half mini-PCIe** for Wi-Fi. The replacement card **must** be half-height (model suffix `HMW`).

- Stock: Intel Centrino Advanced-N 6200 (a/b/g/n only)
- Upgrade: Intel Dual Band Wireless-AC 7260HMW (a/b/g/n/ac, Bluetooth 4.0)
- Compatibility: Works out of the box on Ubuntu 26.04 (kernel driver `iwlwifi`)
- Antenna: 2 connectors (main + aux) — the 7260 uses both

---

## 6. Ubuntu Server 26.04 Tuning

### Kernel Parameters for Server
Add to `/etc/sysctl.d/99-server.conf`:
```
# Reduce swap tendency (we use ZRAM)
vm.swappiness=10

# Network tuning for server
net.core.somaxconn=1024
net.ipv4.tcp_fastopen=3

# OOM behavior (kill quickly, don't freeze)
vm.panic_on_oom=0
kernel.panic=10
```

### systemd-oomd (Ubuntu 26.04 feature)
Ubuntu 26.04 ships with `systemd-oomd` for proactive OOM management:
```bash
sudo systemctl enable --now systemd-oomd
```
Configure in `/etc/systemd/oomd.conf`:
```
[OOM]
DefaultMemoryPressureLimit=50%
DefaultMemoryPressureDurationSec=30
```

### Journald Size Limit
Prevent logs from filling the OS drive:
```bash
sudo nano /etc/systemd/journald.conf
```
```
SystemMaxUse=500M
MaxFileSec=1week
```
```bash
sudo systemctl restart systemd-journald
```

### Docker Resource Limits
Every container needs memory limits. Add to every `compose.yaml`:
```yaml
deploy:
  resources:
    limits:
      memory: 256M
```

Example per-service limits:

| Service | Limit |
|---------|-------|
| Pi-hole | 256M |
| Unbound | 128M |
| Navidrome | 256M |
| Syncthing | 256M |
| Uptime Kuma | 128M |
| Gitea | 256M |
| Dockge | 128M |

---

## 7. ExpressCard/54 Hotplug

The ExpressCard slot connects to the PCI Express bus via `pciehp` driver.

### Manual Rescan (for cards not auto-detected)
```bash
sudo bash -c "echo 1 > /sys/bus/pci/rescan"
```

### Safe Removal
```bash
sudo bash -c "echo 1 > /sys/bus/pci/devices/0000:06:00.0/remove"
```

### Potential Upgrades
| Card | Use Case | Notes |
|------|----------|-------|
| USB 3.0 ExpressCard | 2 extra USB 3.0 ports | Cheap (~$10) |
| eSATA ExpressCard | External SATA storage | Niche |
| 2.5GbE ExpressCard | High-speed Ethernet | Rare, expensive; USB adapter is cheaper |

---

## 8. SD Card Udev Backup Rig

The built-in SD reader registers as `/dev/mmcblk0`. You can trigger automated backups on card insertion.

### udev Rule
`/etc/udev/rules.d/99-sd-backup.rules`:
```
ACTION=="add", SUBSYSTEM=="block", KERNEL=="mmcblk0p1", RUN+="/usr/local/bin/backup_sd.sh"
```

### Backup Script
`/usr/local/bin/backup_sd.sh`:
```bash
#!/bin/bash
set -euo pipefail
TARGET_DEVICE="/dev/mmcblk0"
BACKUP_DIR="/var/backups/sd_images"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${BACKUP_DIR}/sd_snap_${TIMESTAMP}.img.gz"
mkdir -p "${BACKUP_DIR}"
dd bs=1M iflag=fullblock if="${TARGET_DEVICE}" | gzip > "${OUTPUT_FILE}"
sync
```

---

## 9. Power Consumption Estimation

| Component | Idle (W) | Load (W) |
|-----------|---------|----------|
| i7-2860QM (45W TDP) | ~8W | ~35-45W |
| RAM 8GB (2×4GB) | ~3W | ~3W |
| mSATA SSD | ~1W | ~3W |
| HDD 447GB | ~4W | ~7W |
| WiFi, chipset | ~2W | ~3W |
| Total | **~18W** | **~50-55W** |

**Yearly cost** at 18W idle: 18W × 24h × 365d = 157.7 kWh. At ~2,500 VND/kWh = **~394,000 VND/year** (~$16).

At 50W under load: ~438 kWh = **~1,095,000 VND/year** (~$44).

For reference, a modern mini PC (N100 based) idles at 6-10W. The M4600 uses 2-3x more power but cost $0 to acquire.

---

## References

1. Intel ARK: Core i7-2860QM. https://ark.intel.com
2. dell-bios-fan-control. https://github.com/TomFreudenberg/dell-bios-fan-control
3. i8kutils. https://github.com/mohamed-badaoui/i8kutils
4. Ubuntu Server Guide 26.04. https://ubuntu.com/server/docs
5. Dell Precision M4600 Service Manual. Dell Support.
