# Phase 6: Containerization

**Learning goals**: Docker architecture, compose, volumes, networks, container lifecycle.

---

## 6.1 Docker CE Installation

**What to do**:
```bash
# Install prerequisites
sudo apt install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in OR use 'newgrp docker'

# Verify
docker --version
docker run hello-world
```

**Learning**: Container vs VM, Docker architecture (daemon, client, containerd, runc), image layers

**Must NOT do**:
- Don't run `dockerd` directly (use systemd)
- Don't add `--privileged` to containers without understanding risks

**Verification**:
- `docker --version` → version printed
- `docker run hello-world` → Hello from Docker! message
- `sudo systemctl status docker` → active
- `docker info` shows system details

**Evidence Captured**:
- [x] hello-world output — "Hello from Docker!"
- [x] docker — version verified

---

## 6.2 Docker Compose Setup

**What to do**:
```bash
# Install docker compose plugin (included with Docker CE)
sudo apt install -y docker-compose-plugin

# Verify
docker compose version

# Create project structure for all future services
mkdir -p ~/docker/{portainer,pihole,wireguard,jellyfin,gitea}
```

**Learning**: Docker Compose YAML, service definitions, volumes, networks, env vars. 
**2026 Best Practices**:
- **Filename**: Use `compose.yaml` (modern default) instead of `docker-compose.yml`.
- **Version**: The `version: '3.x'` tag is now **deprecated**. Omit it from your files.
- **Project Name**: Use `name: my-project` at the top of the file for explicit naming.
- **Compose Watch**: Learn about `develop: watch` for syncing code into containers.

**Must NOT do**:
- Don't use `latest` tag in production (pin versions)

**Verification**:
- `docker compose version` → version output
- Create a test `compose.yaml` and run `docker compose config` → validates

**Evidence Captured**:
- [x] docker compose version verified
- [x] compose config validates

---

## 6.3 Portainer (Docker Web UI)

**What to do**:
```bash
# Create volume
docker volume create portainer_data

# Run Portainer
docker run -d \
  --name portainer \
  --restart=always \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

**Learning**: Docker volumes, port mapping, restart policies, socket mounting

**Verification**:
- `docker ps` → portainer container running
- Open browser: `http://192.168.1.200:9000`
- Set admin password on first login
- See Docker dashboard with containers, images, volumes

**Evidence to Capture**:
- [ ] docker ps shows portainer
- [ ] Browser screenshot of Portainer dashboard

---

## 6.4 Container Networking Deep-Dive

**What to do**:
```bash
# List Docker networks
docker network ls

# Inspect default bridge network
docker network inspect bridge

# Create custom network
docker network create --driver bridge --subnet 172.20.0.0/16 mynet

# Run container on custom network
docker run -d --name nginx-test --network mynet nginx:alpine

# Inspect
docker network inspect mynet

# DNS resolution between containers
docker run --rm --network mynet alpine nslookup nginx-test

# Port publishing
# -p host_port:container_port

# Clean up
docker rm -f nginx-test
docker network rm mynet
```

**Learning**: Bridge networks, overlay (for swarm), DNS resolution, port publishing vs network isolation

**Verification**:
- Can create custom networks
- Container-Container DNS resolution works
- Understand `--network host`, `--network none`, bridge modes

**Evidence to Capture**:
- [ ] Docker network inspect output
- [ ] Cross-container DNS test
