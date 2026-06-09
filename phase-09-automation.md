# Phase 9: Automation & DevOps

**Learning goals**: Ansible IaC, Docker volume backup patterns, monitoring/alerting.

---

## 9.1 Ansible Managed Configuration

**What to do**:
```bash
# Install Ansible - either on a control machine (your main PC) OR on the server itself
# Option A: Remote management (run from another computer)
#   Install on your local PC: sudo apt install -y ansible
# Option B: Local mode (if M4600 is your only computer - still works)
#   Install on server: sudo apt install -y ansible
#   Then use: ansible-playbook -i inventory.ini docker-services.yml -c local
sudo apt install -y ansible

# Create inventory
mkdir ~/ansible-m4600 && cd ~/ansible-m4600
nano inventory.ini
```
**inventory.ini**:
```ini
[servers]
m4600 ansible_host=192.168.1.100 ansible_user=danko ansible_ssh_private_key_file=~/.ssh/id_ed25519

[servers:vars]
ansible_python_interpreter=/usr/bin/python3
```
```bash
# Test connection
ansible m4600 -i inventory.ini -m ping

# Create a playbook to manage services
nano docker-services.yml
```
**docker-services.yml** (example):
```yaml
---
- hosts: servers
  tasks:
    - name: Ensure Docker is running
      systemd:
        name: docker
        state: started
        enabled: yes

    - name: Ensure Portainer is running
      docker_container:
        name: portainer
        image: portainer/portainer-ce:latest
        state: started
        restart_policy: always
        ports:
          - "9000:9000"
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - portainer_data:/data
```
```bash
ansible-playbook -i inventory.ini docker-services.yml --check
```

**Learning**: Infrastructure as Code, idempotence, Ansible modules (systemd, docker_container, apt)

**Must NOT do**:
- Don't run playbooks without `--check` first
- Don't store SSH private keys in playbooks

**Verification**:
- `ansible m4600 -i inventory.ini -m ping` → pong
- `ansible m4600 -i inventory.ini -a "uptime"` → uptime output
- Playbook `--check` passes
- Service state matches playbook definitions

**Evidence to Capture**:
- [ ] ansible ping result
- [ ] Playbook --check output

---

## 9.2 Automated Docker Volume Backup

**What to do**:
```bash
sudo nano /usr/local/bin/backup-docker.sh
```
**Content**:
```bash
#!/bin/bash
# Backup Docker volumes
BACKUP_DIR="/mnt/data/backups/docker"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"

for volume in $(docker volume ls -q); do
  docker run --rm -v $volume:/source -v $BACKUP_DIR:/backup alpine \
    tar czf "/backup/${volume}-${DATE}.tar.gz" -C /source .
done

# Export container list
docker ps --format '{{.Names}}' > "$BACKUP_DIR/containers-$DATE.txt"

# Keep 7 days
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
```
```bash
sudo chmod +x /usr/local/bin/backup-docker.sh

# Add to crontab
echo '0 4 * * * /usr/local/bin/backup-docker.sh >> /var/log/backup-docker.log 2>&1' | sudo crontab -
```

**Learning**: Docker volume lifecycle, backup strategies for stateful containers

**Verification**:
- Run script manually: `sudo /usr/local/bin/backup-docker.sh`
- Backup archives created in /mnt/data/backups/docker/
- Can extract and verify: `tar tzf backup-volume.tar.gz`

**Evidence to Capture**:
- [ ] Backup script runs successfully
- [ ] Archives verified extractable

---

## 9.3 Monitoring + Alerting (Uptime Kuma)

**What to do**:
```bash
mkdir -p ~/docker/uptime-kuma && cd ~/docker/uptime-kuma
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - "./data:/app/data"
```
```bash
docker compose up -d

# Add monitors for: server SSH, Pi-hole DNS, Jellyfin, Gitea, system resources
```

---

## 9.4 Kernel Samepage Merging (KSM) Optimization

**What to do**:
Since you have 8GB of RAM, KSM will deduplicate memory across similar containers.

```bash
# Install the tuning daemon
sudo apt update
sudo apt install ksmtuned

# Enable the service
sudo systemctl enable --now ksmtuned

# Monitor savings
grep . /sys/kernel/mm/ksm/pages_sharing
```

**Learning**: Kernel memory management, deduplication, scan thresholds.

**Verification**:
- `pages_sharing` should show a number > 0 after the server has been running several containers for a while.

---

## 9.5 Smart Card (SC) Identity Management

**What to do**:
Use the physical slot for hardware-backed security.

```bash
# Install SC utilities
sudo apt install opensc pcscd

# Verify reader detection
opensc-tool -l
```

**Learning**: PKCS#11, hardware security modules (HSM), physical presence authentication.

**Verification**:
- Insert a PIV or OpenPGP card.
- `pkcs11-tool --list-slots` shows the card in the Dell slot.
- Configure SSH to use the card for authentication.

**Learning**: Monitoring concepts (push vs pull), alerting channels (email, webhook, Telegram)

**Verification**:
- Browser: `http://192.168.1.100:3001` → Uptime Kuma dashboard
- Add monitor for `http://192.168.1.100:8096` → status: UP
- Set up notification (email/Telegram/webhook)

**Evidence to Capture**:
- [ ] Uptime Kuma dashboard screenshot
- [ ] Monitors reporting UP
