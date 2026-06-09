# Phase 1: Preparation & Assessment

---

## 1.1 Physical Hardware Assessment

**What to do**:
- Power off, remove battery, open bottom panel
- Identify installed drives: type (SSD/HDD), capacity, interface (SATA/mSATA)
- **RAM Check**: Note current RAM configuration. Your **i7-2860QM** (quad-core) enables all **4 physical DIMM slots** (Max 32GB).
- Check if optical drive is present (candidate for caddy conversion - future)
- Note drive bay configuration (primary SATA, secondary mSATA if present)
- **Thermal Maintenance**: If possible, clean fans and repaste CPU/GPU. The original paste is likely dry by 2026.
- Reassemble and boot to BIOS to verify detection
- Report findings back or continue if plan covers the scenario

**Must NOT do**:
- Don't force any connectors

**Verification**:
- Run `lsblk` from a live USB to confirm disk detection
- Document: which drives available, sizes, health

**Evidence to Capture**:
- [ ] lsblk output saved
- [ ] Drive configuration documented
- [ ] Thermal maintenance performed (optional but recommended)

---

## 1.2 BIOS Configuration for Server Operation

**What to do**:
- Boot and press F2 to enter BIOS setup
- Set the following critical options:
  - **SATA Operation**: AHCI (not RAID)
  - **Deep Sleep Control**: Disabled (required for WOL)
  - **Power On w/ AC**: Enabled (auto-boot after power loss)
  - **Boot Mode**: UEFI (not Legacy)
  - **Boot Order**: USB first, then primary SSD
  - **Wireless**: Disable (recommended for wired server, optional)
  - **Fingerprint reader**: Disable if present (unnecessary)
- Save and exit (F10)
- **BIOS Version**: Ensure you are on the latest (A19). If on < A02, step-up to A03, then A08, then A19.

**Must NOT do**:
- Don't change CPU voltage or memory multiplier settings
- Don't set supervisor password unless you'll remember it

**Verification**:
- Boot once, reboot, re-enter BIOS to confirm settings persisted
- Boot from USB installer successfully (tests AHCI + boot order)

**Evidence to Capture**:
- [ ] BIOS version confirmed (or updated to A19)
- [ ] Settings verified

---

## 1.3 Create Ubuntu Server Bootable USB

**What to do**:
- On another computer, download Ubuntu Server LTS 26.04 ISO
  - URL: https://ubuntu.com/download/server
- Write ISO to USB drive (>=4GB):
  - Linux: `sudo dd if=ubuntu-26.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress && sync`
  - Windows: Use Rufus (dd mode) or BalenaEtcher
  - macOS: `sudo dd if=ubuntu-26.04-live-server-amd64.iso of=/dev/diskX bs=4m`
- Verify USB boots on the M4600 (boot from USB, see installer screen, then power off)

**Must NOT do**:
- Don't use /dev/sda (or your main disk) as the USB target
- Don't write ISO in "FAT32 extraction" mode (must be dd/raw mode)

**Verification**:
- USB boots to Ubuntu Server installer GRUB menu
- Exit installer without installing

**Evidence to Capture**:
- [ ] USB boots successfully
