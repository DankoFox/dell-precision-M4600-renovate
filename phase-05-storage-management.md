# Phase 5: Storage Management

**Learning goals**: LVM, filesystems, mount management, Samba, cron/rsync backups.

---

## 5.1 LVM Setup on SATA Data Drive

**What to do**:
- Your drives: mSATA (120GB) = OS, SATA (447GB GIGABYTE) = data pool
- Identify SATA device with `lsblk` (should be `/dev/sda` or `/dev/sdb`, ~447GB)
```bash
# Install LVM tools
sudo apt install -y lvm2

# Create LVM on SATA drive (replace /dev/sdX with actual device)
sudo pvcreate /dev/sdX
sudo vgcreate storage_vg /dev/sdX
sudo lvcreate -L 200G -n media_lv storage_vg
sudo lvcreate -l 100%FREE -n data_lv storage_vg

# Create filesystems
sudo mkfs.ext4 /dev/storage_vg/media_lv
sudo mkfs.ext4 /dev/storage_vg/data_lv

# Mount
sudo mkdir -p /mnt/media /mnt/data
sudo mount /dev/storage_vg/media_lv /mnt/media
sudo mount /dev/storage_vg/data_lv /mnt/data

# Persist in fstab
echo '/dev/storage_vg/media_lv /mnt/media ext4 defaults 0 2' | sudo tee -a /etc/fstab
echo '/dev/storage_vg/data_lv /mnt/data ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

**Learning**: Physical volumes, volume groups, logical volumes, extents, LVM flexibility

**Must NOT do**:
- Don't LVM the OS drive unless you understand boot implications (separate /boot)
- Don't use LVM without monitoring free extents

**Verification**:
- `sudo pvs` shows PVs
- `sudo vgs` shows VG
- `sudo lvs` shows LVs
- `df -h` shows mounted filesystems
- Reboot: all mounts auto-attached

**Evidence to Capture**:
- [ ] lsblk + pvs + vgs + lvs output
- [ ] Mounted filesystems after reboot

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
- From Windows/macOS/Linux machine: connect to `\\192.168.1.100\media`
- Can read/write files from network client
- `testparm` shows valid config

**Evidence to Capture**:
- [ ] smbd status
- [ ] Network share accessible from client

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
