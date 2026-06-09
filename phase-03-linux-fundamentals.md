# Phase 3: Linux Fundamentals

**Learning goals**: Networking, SSH, firewall, users (`sudo-rs`), systemd (cgroup v2), apt, monitoring.

---

## 3.1 Static IP Network Configuration

**What to do** (Ubuntu 26.04 uses netplan):
```bash
# List interfaces
ip link show
# Identify primary Ethernet interface (likely eno1 or enpXsY)

# Check EXISTING netplan files (do NOT assume filename)
ls /etc/netplan/
# Common: 00-installer-config.yaml, 50-cloud-init.yaml, or 01-netcfg.yaml
# Edit whichever exists (or create new .yaml if directory empty)
sudo nano /etc/netplan/XX-your-config.yaml
# ^ replace with actual filename found above
```
**Content**:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:  # <-- replace with your interface name
      addresses:
        - 192.168.1.100/24  # <-- choose static IP within your LAN
      routes:
        - to: default
          via: 192.168.1.1  # <-- your router's IP
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
      dhcp4: no
```
**Apply**:
```bash
sudo netplan apply
```

**Learning**: Understand CIDR notation, gateway, DNS resolvers, netplan YAML syntax

**Must NOT do**:
- Don't set IP that conflicts with DHCP range (check router first)
- Don't close SSH session until new config verified

**Verification**:
- `ip a` shows static IP configured
- `ping 8.8.8.8` succeeds
- `ping google.com` succeeds (DNS works)
- SSH from another machine to the static IP works

**Evidence to Capture**:
- [ ] ip a output
- [ ] Successful ping test
- [ ] SSH login from another machine

---

## 3.2 SSH Hardening

**What to do**:
```bash
# On your local machine, generate SSH key pair
ssh-keygen -t ed25519 -C "m4600-server"

# Copy public key to server
ssh-copy-id user@192.168.1.100

# On server, harden SSH config
sudo nano /etc/ssh/sshd_config.d/99-hardening.conf
```
**Content**:
```
# Key-based auth only
PasswordAuthentication no
PermitRootLogin no
# Use key-based auth
PubkeyAuthentication yes
# Limit users who can SSH (replace with your username)
AllowUsers danko
# Idle timeout
ClientAliveInterval 300
ClientAliveCountMax 2
# Protocol
Protocol 2
```
```bash
sudo systemctl restart sshd
```

**Learning**: Symmetric vs asymmetric crypto, SSH key types (RSA/Ed25519), sshd config directives

**Must NOT do**:
- Don't close current SSH session until NEW session with key auth verified
- Keep root login disabled at all times

**Verification**:
- Open NEW terminal, SSH from local machine: `ssh user@192.168.1.100 -i ~/.ssh/id_ed25519`
- Password login should fail (test with `ssh -o PreferredAuthentications=password user@192.168.1.100`)
- Root login should fail

**Evidence to Capture**:
- [ ] Successful SSH with key
- [ ] Password auth rejected

---

## 3.3 UFW Firewall Setup

**What to do**:
```bash
# Default deny
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh
# Or specific port: sudo ufw allow 22/tcp

# If planning HTTP/HTTPS services later
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

**Learning**: Firewall rules, default deny principle, stateful vs stateless, port numbering

**Must NOT do**:
- Don't enable UFW without first allowing SSH (will lock yourself out)
- Don't disable UFW for convenience

**Verification**:
- `sudo ufw status` shows active rules, SSH allowed
- SSH from another machine still works
- `nmap -p- 192.168.1.100` from another machine shows ONLY port 22 open

**Evidence to Capture**:
- [ ] ufw status output
- [ ] nmap scan showing only SSH open

---

## 3.4 User Management + sudo

**What to do**:
```bash
# Create service account for automated tasks
sudo useradd -r -s /usr/sbin/nologin -M svc-backup

# Add user to groups for future needs
sudo usermod -aG docker danko  # (will use in Docker phase)
sudo usermod -aG sudo danko    # (should already be set on install)

# Learning: sudo-rs
# Ubuntu 26.04 uses sudo-rs, a memory-safe implementation of sudo in Rust.
# The command syntax remains compatible with traditional sudo.

# Understand /etc/passwd, /etc/shadow, /etc/group
cat /etc/passwd | grep danko
cat /etc/group | grep sudo

# Configure sudo timeout
echo 'Defaults timestamp_timeout=15' | sudo tee /etc/sudoers.d/timeout
```

**Learning**: User/group files, service accounts, sudoers, /etc/skel

**Must NOT do**:
- Don't create shared passwords
- Don't use root for daily work

**Verification**:
- `id danko` shows correct groups
- `sudo -l` lists allowed commands
- Passwordless sudo is NOT enabled (security)

**Evidence to Capture**:
- [ ] id output
- [ ] sudo -l output

---

## 3.5 systemd Service Management

**What to do**:
```bash
# Explore current services
systemctl list-units --type=service --state=running
systemctl list-unit-files --type=service

# Examine critical services
systemctl status sshd
systemctl status systemd-networkd
systemctl status systemd-resolved

# Check boot time
systemd-analyze
systemd-analyze blame

# View logs
journalctl -u sshd
journalctl -u sshd -n 20 --no-pager
journalctl --since "1 hour ago"

# Watch live logs
journalctl -f
```

**Learning**: systemd units, targets, journald, service dependencies, socket activation, **cgroup v2** (Ubuntu 26.04 has fully removed cgroup v1 support)

**Must NOT do**:
- Don't disable essential system services

**Verification**:
- Can list running services
- Can read journalctl logs for any service
- Understand diff between enabled/disabled/static/masked

**Evidence to Capture**:
- [ ] systemctl list-units output
- [ ] journalctl -u sshd sample

---

## 3.6 Package Management

**What to do**:
```bash
# Explore apt commands
apt list --installed | head -30
apt-cache search <package>
apt show <package>
apt policy <package>

# Understand repos
ls /etc/apt/sources.list.d/
cat /etc/apt/sources.list

# Add a PPA (example)
# sudo add-apt-repository ppa:<name>

# dpkg low-level
dpkg -l | grep openssh
dpkg -L openssh-server
dpkg -S /etc/ssh/sshd_config
```

**Learning**: apt vs dpkg, dependency resolution, repository management, debian packaging basics

**Must NOT do**:
- Don't add untrusted PPAs
- Don't run `apt autoremove` without checking what would be removed

**Verification**:
- Can find installed packages, their files, and which package owns a file
- Can add/remove repositories

**Evidence to Capture**:
- [ ] dpkg -l | wc -l (package count)
- [ ] apt policy for a known package

---

## 3.7 Monitoring Tools

**What to do**:
```bash
# Baseline system info
fastfetch

# Memory baseline
free -h
cat /proc/meminfo

# CPU info
cat /proc/cpuinfo | grep "model name" | head -1
lscpu

# Disk health
sudo smartctl -H /dev/sda

# Disk usage
df -h
du -sh /var/log

# Process monitoring
htop
```

**Learning**: /proc filesystem, system monitoring, performance baselining

**Must NOT do**:
- Don't skip this - baseline is needed to detect issues later

**Verification**:
- Save baseline output to a file for comparison
- Understand each metric

**Evidence to Capture**:
- [ ] fastfetch output saved
- [ ] Baseline memory/disk/CPU stats saved
