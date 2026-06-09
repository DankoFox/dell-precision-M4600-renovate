# Phase 2: OS Installation

---

## 2.1 Install Ubuntu Server LTS 26.04

**What to do**:
- Boot from USB installer
- Select language (English), keyboard layout (your layout)
- Network: Use DHCP for now (will set static IP in Phase 3)
- Proxy: leave blank
- Mirror: default or select country-close
- **Encryption**: Consider enabling **TPM-backed Full Disk Encryption** if your M4600 has a TPM chip enabled in BIOS.
- **Drive layout**:
  - mSATA (120GB SAMSUNG PM871) → OS + boot + swap
  - SATA (447GB GIGABYTE) → leave unallocated (LVM pool in Phase 5)
- Storage config: Use **Custom layout** (not guided)
  - Select mSATA drive (120GB):
    - `/boot`: 1GB ext4
    - `swap`: 4GB
    - `/`: rest of mSATA (ext4)
  - Select SATA drive (447GB): leave completely unallocated
- Profile: Set username + hostname (e.g., `m4600-server`)
- SSH Setup: **Install OpenSSH server** (enable during install)
- Featured Server Snaps: **None** (skip all, we install natively)
- Let install complete, then reboot (remove USB when prompted)

**Must NOT do**:
- Don't use ZFS (heavy on RAM, unnecessary for learning)
- Don't install snaps (we'll manage packages manually)
- Don't set up Ubuntu Pro unless you want it (free for personal use)

**Verification**:
- System boots to login prompt
- Login with created user credentials
- `ip a` shows network interface with IP
- `lsblk` confirms partition layout

**Evidence to Capture**:
- [ ] Screenshot/photo of login prompt
- [ ] lsblk output saved

---

## 2.2 Post-Install: System Updates + Essential Tools

**What to do**:
```bash
# Update package lists and upgrade all packages
sudo apt update && sudo apt upgrade -y

# Install essential admin tools
sudo apt install -y \
  htop iotop nmon \
  net-tools curl wget \
  git vim tmux \
  tree lsof \
  smartmontools \
  bash-completion \
  fastfetch \
  zram-config

# Reboot to apply kernel updates if any
sudo reboot
```

- Configure vim if desired: `sudo update-alternatives --config editor` → select vim
- Time zone: `sudo timedatectl set-timezone Your/Timezone`

**Must NOT do**:
- Don't install unnecessary packages (desktop, GUI, games)
- Don't disable automatic security updates

**Verification**:
- `htop` shows processes, CPU, memory
- `fastfetch` shows system info
- `curl google.com` → succeeds (internet works)
- `timedatectl` shows correct timezone

**Evidence to Capture**:
- [ ] fastfetch output saved
- [ ] apt update/upgrade completed cleanly
