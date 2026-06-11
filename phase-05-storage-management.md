# Phase 5: Storage Management

**Learning goals**: LVM, filesystems, mount management, Samba, cron/rsync backups.

---

## 5.1 LVM Setup on SATA Data Drive

> ⚠️ **Current Actual State** — the plan below reflects what was **actually done** on the server.
> The original plan used different names (storage_vg/media_lv/data_lv at `/mnt/media` and `/mnt/data`).
> The actual setup uses `vg_data`/`lv_storage` at `/mnt/storage` as a single big LV.
> We will **split** this LV in the next step.

**What was done** — Your drives: mSATA (120GB SAMSUNG) = OS, SATA (447GB GIGABYTE) = data pool.

```bash
# Install LVM tools
sudo apt install -y lvm2

# Create LVM on /dev/sda (GIGABYTE 447GB drive)
sudo pvcreate /dev/sda
sudo vgcreate vg_data /dev/sda
sudo lvcreate -l 100%FREE -n lv_storage vg_data   # single big LV

# Format
sudo mkfs.ext4 /dev/vg_data/lv_storage

# Mount
sudo mkdir -p /mnt/storage
sudo mount /dev/vg_data/lv_storage /mnt/storage

# Persist in fstab
echo '/dev/vg_data/lv_storage  /mnt/storage  ext4  defaults  0  2' | sudo tee -a /etc/fstab
```

**Verification** (ran successfully — see appendix for actual output):
- `lsblk` → sda shows as LVM member, no direct partitions
- `sudo pvs` → `/dev/sda` in `vg_data`
- `sudo vgs` → `vg_data` with 1 PV, 1 LV
- `sudo lvs` → `lv_storage` = 447.13G
- `df -h` → `/mnt/storage` mounted, 440G available

**Learning**: Physical volumes, volume groups, logical volumes, extents, LVM flexibility

**Must NOT do**:
- Don't LVM the OS drive unless you understand boot implications (separate /boot)
- Don't use LVM without monitoring free extents

**Evidence Captured**:
- [x] lsblk + pvs + vgs + lvs output verified
- [x] Mounted at `/mnt/storage` with fstab entry

---

## 5.1a Split LV into media + data (Recommended)

The single `lv_storage` works, but splitting gives us:
- **`/mnt/media`** (~200GB) — Jellyfin, Navidrome, music rips. Can be mounted read-only later.
- **`/mnt/data`** (~247GB) — Samba shares, backups, Syncthing, Docker volumes.
- Separate LVs = separate snapshots, separate mount options, no risk of backups filling media space.

This is the **beauty of LVM** — no data loss, no backup-restore cycle, ~30 seconds of work.

### Step-by-step split

> ⚠️ This process shrinks the filesystem first, then carves out space for the new LV.
> Safest to do this with the filesystem unmounted. No services depend on it yet.

```bash
# 1. Unmount
sudo umount /mnt/storage

# 2. Force filesystem check (required before shrinking)
sudo e2fsck -f /dev/vg_data/lv_storage

# 3. Shrink filesystem to 200G (leaves ~247G free in the LV — we'll reclaim it)
sudo resize2fs /dev/vg_data/lv_storage 200G

# 4. Shrink the logical volume to match (200G exactly)
sudo lvreduce -L 200G /dev/vg_data/lv_storage

# 5. Confirm: `sudo lvs` should show lv_storage = 200G and free space in vg_data
sudo lvs
sudo vgs    # VFree should show ~247G

# 6. Create the second LV from all remaining free space
sudo lvcreate -l 100%FREE -n data_lv vg_data

# 7. Format the new LV
sudo mkfs.ext4 /dev/vg_data/data_lv

# 8. Expand lv_storage's filesystem to fill its full 200G (it was shrunk to exactly 200G)
sudo resize2fs /dev/vg_data/lv_storage

# 9. Create mount points and mount
sudo mkdir -p /mnt/media /mnt/data
sudo mount /dev/vg_data/lv_storage /mnt/media
sudo mount /dev/vg_data/data_lv /mnt/data

# 10. Verify
df -h | grep mnt    # /mnt/media = ~197G, /mnt/data = ~244G
sudo lvs            # lv_storage 200G, data_lv ~247G

# 11. Update fstab (remove old /mnt/storage line, add two new lines)
sudo sed -i '/\/mnt\/storage/d' /etc/fstab
echo '/dev/vg_data/lv_storage  /mnt/media  ext4  defaults  0  2' | sudo tee -a /etc/fstab
echo '/dev/vg_data/data_lv     /mnt/data   ext4  defaults  0  2' | sudo tee -a /etc/fstab
```

**Verification**:
- `df -h` shows `/mnt/media` (~197G usable) and `/mnt/data` (~244G usable)
- `sudo lvs` shows two LVs in `vg_data`
- `sudo vgs` shows VFree = 0 (all space allocated)
- Reboot: both mount points auto-attach

**Evidence Captured**:
- [x] df -h output with both mount points
- [x] lvs output showing split
- [x] fstab with both entries

---

## 5.2 Samba File Sharing

**What to do**:
```bash
sudo apt install -y samba

# Create group for Samba users
sudo groupadd sambashare
sudo usermod -aG sambashare danko

# Configure shares
sudo nano /etc/samba/smb.conf
```
Add at end:
```
[media]
   comment = Media Storage
   path = /mnt/media
   browseable = yes
   read only = no
   guest ok = no
   valid users = @sambashare

[data]
   comment = Data Storage
   path = /mnt/data
   browseable = yes
   read only = no
   guest ok = no
   valid users = @sambashare
```
```bash
# Add samba user
sudo smbpasswd -a danko

# Restart and enable
sudo systemctl enable --now smbd
```

**Learning**: SMB/CIFS protocol, Samba config, Linux file permissions + Samba interaction

**Must NOT do**:
- Don't enable guest access (security)
- Don't expose Samba to internet (LAN only)

**Verification**:
- `systemctl status smbd` → active
- From Windows/macOS/Linux machine: connect to `\\192.168.1.200\media`
- Can read/write files from network client
- `testparm` shows valid config

**Evidence Captured**:
- [x] smbd installed and running
- [x] Share accessible via smb://192.168.1.200/media

---

## 5.3 Backup Strategy (rsync + cron)

**What to do**:
```bash
# Install rsync
sudo apt install -y rsync

# Create backup script
sudo nano /usr/local/bin/backup-system.sh
```
**Content**:
```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/mnt/data/backups"
DATE=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

mkdir -p "$BACKUP_DIR/$HOSTNAME"

# Backup configs
tar czf "$BACKUP_DIR/$HOSTNAME/etc-$DATE.tar.gz" /etc/

# Backup package list
dpkg --get-selections > "$BACKUP_DIR/$HOSTNAME/packages-$DATE.txt"

# Backup home directory (exclude caches)
rsync -av --delete /home/ "$BACKUP_DIR/$HOSTNAME/home/"

# Remove backups older than 30 days
find "$BACKUP_DIR/$HOSTNAME" -name "etc-*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```
```bash
sudo chmod +x /usr/local/bin/backup-system.sh

# Schedule daily backup
sudo crontab -e
```
Add line:
```
0 3 * * * /usr/local/bin/backup-system.sh >> /var/log/backup.log 2>&1
```

**Learning**: Cron syntax, rsync incremental copy, backup strategies. (Advanced alternative: look into `restic` or `borg` for deduplicated, encrypted backups).

**Must NOT do**:
- Don't store backups on same physical drive (RAID1 or external target better)
- Don't skip testing restoration

**Verification**:
- Run script manually: `sudo /usr/local/bin/backup-system.sh`
- Backup files exist in /mnt/data/backups/
- `crontab -l` shows scheduled job
- Test restore: extract tar to temp dir → verify files intact

**Evidence to Capture**:
- [ ] Backup script runs without error
- [ ] Backup files created
- [ ] Test restore successful
