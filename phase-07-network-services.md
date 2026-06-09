# Phase 7: Network Services

**Learning goals**: DNS, VPN tunneling, reverse proxy, TLS/certificates.

---

## 7.1 Pi-hole DNS Sinkhole

**What to do**:
```bash
mkdir -p ~/docker/pihole && cd ~/docker/pihole

nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:80/tcp"
    environment:
      TZ: "Your/Timezone"
      WEBPASSWORD: "your-admin-password"
      PIHOLE_DNS_: "1.1.1.1;8.8.8.8"
    volumes:
      - "./etc-pihole:/etc/pihole"
      - "./etc-dnsmasq.d:/etc/dnsmasq.d"
    restart: unless-stopped
```
```bash
docker compose up -d

# Set Pi-hole as system DNS
ls /etc/netplan/  # find your config file
sudo nano /etc/netplan/XX-your-config.yaml
# Change nameservers to: 127.0.0.1 (for local, then Pi-hole)

sudo netplan apply
```

**Learning**: DNS protocol, sinkhole filtering, dnsmasq, port binding. **Pi-hole v6** (2026) includes a modernized web interface and integrated DHCP/DNS engine.

**Must NOT do**:
- Don't expose port 53 to internet (DNS amplification attack vector)
- Don't change router DHCP DNS until Pi-hole is verified working

**Verification**:
- `docker ps` → pihole container running
- Browser: `http://192.168.1.100:8080/admin` → Pi-hole dashboard
- `nslookup doubleclick.net 192.168.1.100` → returns 0.0.0.0 (blocked)
- `nslookup google.com 192.168.1.100` → returns valid IP (allowed)

**Evidence to Capture**:
- [ ] Pi-hole dashboard screenshot
- [ ] DNS query test (blocked vs allowed)

---

## 7.2 WireGuard VPN

**What to do**:
```bash
# Install wireguard (kernel module built-in on Ubuntu 26.04)
sudo apt install -y wireguard

# Generate keys
wg genkey | sudo tee /etc/wireguard/server.key
sudo chmod 600 /etc/wireguard/server.key
sudo cat /etc/wireguard/server.key | wg pubkey | sudo tee /etc/wireguard/server.pub

# Create config
sudo nano /etc/wireguard/wg0.conf
```
**wg0.conf**:
```
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eno1 -j MASQUERADE
ListenPort = 51820
PrivateKey = <server-private-key>

[Peer]
# Phone/Laptop
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32
```
```bash
sudo systemctl enable --now wg-quick@wg0
sudo ufw allow 51820/udp
```

**Learning**: VPN tunneling, WireGuard protocol, key exchange, iptables NAT, AllowedIPs concept

**Must NOT do**:
- Don't reuse private keys between machines

**Verification**:
- `sudo wg show` → interface up, peer listed
- `sudo systemctl status wg-quick@wg0` → active
- From phone/laptop: connect via WireGuard app, ping 10.0.0.1
- From phone: access http://192.168.1.100:9000 (Portainer through VPN)

**Evidence to Capture**:
- [ ] wg show output
- [ ] VPN connection successful from client

---

## 7.3 Remote Access (2026 Meta: Cloudflare Tunnels)

**What to do**:
In 2026, dynamic DNS (like DuckDNS) and manual port forwarding (like traditional Nginx) are considered legacy and potentially insecure. The modern standard is a reverse tunnel, ensuring your server has **zero open inbound ports**.

```bash
mkdir -p ~/docker/cloudflared && cd ~/docker/cloudflared
nano compose.yaml
```
**compose.yaml**:
```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=your_token_from_cloudflare_dashboard
```
```bash
docker compose up -d
```

**Learning**: Reverse tunnels, Zero Trust Network Access (ZTNA), deprecating port forwarding (NAT).

**Must NOT do**:
- Don't port forward 80/443 on your router.
- Don't use DuckDNS (highly flagged by spam filters/ISPs in 2026).

**Verification**:
- Go to Cloudflare Zero Trust Dashboard → Tunnels.
- Verify the tunnel is "Healthy".
- Route a public domain (e.g., `jellyfin.yourdomain.com`) to `http://192.168.1.100:8096`.
- Access your domain from a cell network.

**Evidence to Capture**:
- [ ] Cloudflare Tunnel "Healthy" status screenshot
- [ ] Successful external access to a service

---

## 7.4 Mesh VPN Alternative (Tailscale)

**What to do**:
While we learned native WireGuard in 7.2, the 2026 standard for *personal* remote access to services you don't want public (like Syncthing or SSH) is a Mesh VPN like Tailscale.

```bash
# Install Tailscale natively
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate and bring the node up
sudo tailscale up
```

**Learning**: Mesh networks vs traditional Hub-and-Spoke VPNs, CGNAT traversal.

**Must NOT do**:
- Don't expose private services (like SSH or Portainer) through Cloudflare Tunnels without strong ZTNA rules; use Tailscale instead.

**Verification**:
- `tailscale status` shows your M4600 and other connected devices (e.g., your phone).
- Disconnect your phone from Wi-Fi and ping the Tailscale IP of the M4600 (usually `100.x.y.z`).

**Evidence to Capture**:
- [ ] `tailscale status` output
- [ ] Successful ping over Tailnet
