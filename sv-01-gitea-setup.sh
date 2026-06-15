#!/bin/bash
# SV-01: Deploy Gitea with SQLite, expose via Cloudflare tunnel
# Domain: git.dankofox.quest
# Usage: scp to server, then bash sv-01-gitea-setup.sh
#
# Architecture:
#   Gitea container (SQLite) → port 3000 → Cloudflare tunnel → git.dankofox.quest
#   No SSH passthrough — HTTPS-only via tunnel (simpler, no port-forwarding needed)

set -euo pipefail

GITEA_DIR="$HOME/docker/gitea"
CLOUDFLARED_CONFIG="/etc/cloudflared/config.yml"
DOMAIN="git.dankofox.quest"
TUNNEL_HOSTNAME="git.dankofox.quest"
COMPOSE_FILE="$GITEA_DIR/compose.yaml"

echo "=== SV-01: Deploy Gitea ==="
echo "Target: https://$DOMAIN"
echo

# --- Step 1: Create directory ---
if [ ! -d "$GITEA_DIR" ]; then
  mkdir -p "$GITEA_DIR"
  echo "CREATED: $GITEA_DIR"
else
  echo "EXISTS: $GITEA_DIR"
fi

# --- Step 2: Write compose.yaml ---
cat > "$COMPOSE_FILE" << 'COMPOSE'
services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=sqlite3
      - GITEA__server__DOMAIN=git.dankofox.quest
      - GITEA__server__ROOT_URL=https://git.dankofox.quest
      - GITEA__server__HTTP_PORT=3000
      - GITEA__server__SSH_PORT=22
      - GITEA__server__DISABLE_SSH=true
      - GITEA__server__OFFLINE_MODE=false
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "127.0.0.1:3000:3000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3000/"]
      interval: 15s
      timeout: 5s
      retries: 10
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: "0.5"
        reservations:
          memory: 128M
COMPOSE
echo "WRITTEN: $COMPOSE_FILE"

# --- Step 3: Pull image ---
echo
echo "=== Pulling Gitea image ==="
docker compose -f "$COMPOSE_FILE" pull

# --- Step 4: Start Gitea ---
echo
echo "=== Starting Gitea ==="
docker compose -f "$COMPOSE_FILE" up -d

# --- Step 5: Wait for health ---
echo
echo "=== Waiting for Gitea health check ==="
for i in $(seq 1 12); do
  if docker inspect --format '{{.State.Health.Status}}' gitea 2>/dev/null | grep -q healthy; then
    echo "Gitea is healthy!"
    break
  fi
  echo "Waiting... ($i/12)"
  sleep 5
done

# --- Step 6: Update Cloudflare tunnel config ---
echo
echo "=== Updating Cloudflare tunnel config ==="
if grep -q "git\.dankofox\.quest" "$CLOUDFLARED_CONFIG" 2>/dev/null; then
  echo "EXISTS: git.dankofox.quest already in tunnel config"
else
  # Insert new ingress rule before the catch-all (last line)
  # Find the catch-all line (last ingress rule, typically a 404)
  # This approach: rewrite the ingress section
  TUNNEL_ID=$(grep "^tunnel:" "$CLOUDFLARED_CONFIG" | awk '{print $2}')
  CRED_FILE=$(grep "credentials-file:" "$CLOUDFLARED_CONFIG" | awk '{print $2}')

  # Build new config preserving tunnel/credentials and replacing ingress
  cat > /tmp/cloudflared-config.yml << 'CFCONF'
tunnel: TUNNEL_ID_PLACEHOLDER
credentials-file: CRED_FILE_PLACEHOLDER

ingress:
  - hostname: music.dankofox.quest
    service: http://localhost:4533
  - hostname: git.dankofox.quest
    service: http://localhost:3000
  - service: http_status:404
CFCONF

  # Substitute placeholders
  sed -i "s|TUNNEL_ID_PLACEHOLDER|$TUNNEL_ID|" /tmp/cloudflared-config.yml
  sed -i "s|CRED_FILE_PLACEHOLDER|$CRED_FILE|" /tmp/cloudflared-config.yml

  # Backup existing config
  sudo cp "$CLOUDFLARED_CONFIG" "${CLOUDFLARED_CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
  sudo cp /tmp/cloudflared-config.yml "$CLOUDFLARED_CONFIG"
  rm /tmp/cloudflared-config.yml

  echo "UPDATED: $CLOUDFLARED_CONFIG"
  echo "BACKUP: ${CLOUDFLARED_CONFIG}.bak.*"

  # Restart cloudflared
  sudo systemctl restart cloudflared
  echo "RESTARTED: cloudflared service"
fi

# --- Step 7: Verify tunnel ---
echo
echo "=== Verifying tunnel ==="
sleep 3
sudo systemctl status cloudflared --no-pager 2>&1 | head -5
cloudflared tunnel info navidrome-tunnel 2>&1 | head -10

# --- Step 8: Verify Gitea responds locally ---
echo
echo "=== Local verification ==="
curl -s -o /dev/null -w "Gitea HTTP status: %{http_code}\n" http://localhost:3000/ || echo "FAIL: Gitea not responding locally"

# --- Step 9: Add DNS CNAME via Cloudflare API ---
echo
echo "=== DNS ==="
TUNNEL_ID_EXTRACTED=$(grep "^tunnel:" "$CLOUDFLARED_CONFIG" 2>/dev/null | awk '{print $2}' || true)
echo "Add CNAME record in Cloudflare dashboard:"
echo "  Name: git"
echo "  Target: ${TUNNEL_ID_EXTRACTED}.cfargotunnel.com"
echo "  Proxy: Orange cloud (proxied)"
echo
echo "Or create DNS record via API (if CLOUDFLARE_API_TOKEN set):"
if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
  ZONE_ID=$(curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    "https://api.cloudflare.com/client/v4/zones?name=dankofox.quest" \
    | jq -r '.result[0].id')
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"CNAME","name":"git","content":"06851969-a611-44bb-a271-b7387cb7f957.cfargotunnel.com","proxied":true}' \
    | jq '.success'
  echo "DNS record created."
else
  echo "No API token — create DNS record manually in Cloudflare dashboard."
fi

echo
echo "=== SV-01 Complete ==="
echo "Gitea running at: http://localhost:3000"
echo "Public URL: https://git.dankofox.quest (after DNS propagates)"
echo
echo "First-time setup:"
echo "  1. Visit https://git.dankofox.quest"
echo "  2. Fill in admin account details"
echo "  3. DB type: SQLite3 (default)"
echo "  4. Server domain: git.dankofox.quest"
echo "  5. Gitea base URL: https://git.dankofox.quest"
echo "  6. Disable self-registration (under admin settings)"
echo
echo "Post-setup:"
echo "  - Create repos at https://git.dankofox.quest"
echo "  - Clone: git clone https://git.dankofox.quest/username/repo.git"
echo "  - Admin UI: https://git.dankofox.quest/admin"
echo "  - Check logs: docker logs gitea"
