#!/bin/bash
# MT-04: Add Docker resource limits (hard limit + soft reservation) to compose.yaml files
# Usage: scp to server, then bash mt-04-resource-limits.sh
# Safe to re-run — idempotent, skips if limits already exist.

# --- Methodology ---
# Based on Docker docs and selfhosting.sh best practices:
# - Hard limit = measured_peak x 1.5 (allows spike headroom without unnecessary kills)
# - Soft reservation = 50% of limit (Docker tries to keep under this during memory pressure)
# - Measured with 2 active Navidrome users (2026-06-14)
# - Source: https://docs.docker.com/engine/containers/resource_constraints/
# - Source: https://selfhosting.sh/foundations/docker-resource-limits/
# Total limits: ~1.4GB, well within 80% safe budget (6.4GB) on 8GB server.

set -euo pipefail

DOCKER_DIR="$HOME/docker"

add_limits() {
  local file="$1"
  local cpu="$2"
  local mem="$3"
  local mem_reserve="$4"
  local svc="$5"

  if [ ! -f "$file" ]; then
    echo "SKIP: $file not found"
    return
  fi

  if grep -q 'limits:' "$file" 2>/dev/null; then
    echo "OK (exists): $svc"
    return
  fi

  if command -v yq &>/dev/null; then
    yq eval "
      .services.$svc.deploy.resources.limits.cpus = \"$cpu\" |
      .services.$svc.deploy.resources.limits.memory = \"$mem\" |
      .services.$svc.deploy.resources.reservations.memory = \"$mem_reserve\"
    " -i "$file"
    echo "ADDED (yq): $svc (limit ${mem}, reserve ${mem_reserve}, cpu $cpu)"
  else
    local deploy_block="    deploy:
      resources:
        limits:
          cpus: '$cpu'
          memory: $mem
        reservations:
          memory: $mem_reserve"
    awk -v svc="$svc" -v block="$deploy_block" '
    {
      print
      if ($0 ~ "^  " svc ":") {
        printf "%s\n", block
      }
    }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    echo "ADDED (awk): $svc (limit ${mem}, reserve ${mem_reserve}, cpu $cpu)"
  fi
}

# Format: add_limits <compose.yaml> <cpu> <limit_mem> <reserve_mem> <service_name>
add_limits "$DOCKER_DIR/navidrome/compose.yaml" "0.5" "512M" "256M" "navidrome"
add_limits "$DOCKER_DIR/sync/compose.yaml" "0.25" "256M" "128M" "syncthing"
add_limits "$DOCKER_DIR/pihole/compose.yaml" "0.5" "128M" "64M" "pihole"
add_limits "$DOCKER_DIR/uptime-kuma/compose.yaml" "0.25" "256M" "128M" "uptime-kuma"
add_limits "$DOCKER_DIR/dockge/compose.yaml" "0.25" "256M" "128M" "dockge"

echo
echo "=== Recreating containers ==="
for dir in navidrome sync pihole uptime-kuma dockge; do
  if [ -f "$DOCKER_DIR/$dir/compose.yaml" ]; then
    echo "--- $dir ---"
    docker compose -f "$DOCKER_DIR/$dir/compose.yaml" up -d 2>&1
  fi
done

echo
echo "=== Verify limits ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
