#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/homelab"

declare -A MAP=(
  ["$REPO/compose/arr/compose.yaml"]="/srv/docker/arr/compose.yaml"
  ["$REPO/compose/caddy/compose.yaml"]="/srv/docker/caddy/compose.yaml"
  ["$REPO/compose/ddns/compose.yaml"]="/srv/docker/ddns/compose.yaml"
  ["$REPO/compose/homepage-stack/compose.yaml"]="/srv/docker/homepage-stack/compose.yaml"
  ["$REPO/compose/immich/compose.yaml"]="/srv/docker/immich/compose/compose.yaml"
  ["$REPO/compose/jellyfin/compose.yaml"]="/srv/docker/jellyfin/compose.yaml"
  ["$REPO/compose/vaultwarden/compose.yaml"]="/srv/docker/vaultwarden/compose.yaml"
  ["$REPO/compose/vpn/compose.yaml"]="/srv/docker/vpn/compose.yaml"

  ["$REPO/configs/caddy/Caddyfile"]="/srv/docker/caddy/Caddyfile"

  ["$REPO/configs/homepage/bookmarks.yaml"]="/srv/docker/homepage-stack/homepage-config/bookmarks.yaml"
  ["$REPO/configs/homepage/custom.css"]="/srv/docker/homepage-stack/homepage-config/custom.css"
  ["$REPO/configs/homepage/custom.js"]="/srv/docker/homepage-stack/homepage-config/custom.js"
  ["$REPO/configs/homepage/docker.yaml"]="/srv/docker/homepage-stack/homepage-config/docker.yaml"
  ["$REPO/configs/homepage/kubernetes.yaml"]="/srv/docker/homepage-stack/homepage-config/kubernetes.yaml"
  ["$REPO/configs/homepage/providers.yaml"]="/srv/docker/homepage-stack/homepage-config/providers.yaml"
  ["$REPO/configs/homepage/proxmox.yaml"]="/srv/docker/homepage-stack/homepage-config/proxmox.yaml"
  ["$REPO/configs/homepage/services.yaml"]="/srv/docker/homepage-stack/homepage-config/services.yaml"
  ["$REPO/configs/homepage/settings.yaml"]="/srv/docker/homepage-stack/homepage-config/settings.yaml"
  ["$REPO/configs/homepage/widgets.yaml"]="/srv/docker/homepage-stack/homepage-config/widgets.yaml"

  ["$REPO/configs/immich/config.yml"]="/srv/docker/immich/compose/config.yml"
)

echo "Checking for drift between $REPO and /srv/docker..."
echo

for repo_file in "${!MAP[@]}"; do
  live_file="${MAP[$repo_file]}"

  if [[ ! -f "$repo_file" ]]; then
    echo "MISSING IN REPO: $repo_file"
    echo "  Live file exists at: $live_file"
    echo
    continue
  fi

  if [[ ! -f "$live_file" ]]; then
    echo "MISSING LIVE FILE: $live_file"
    echo "  Repo file exists at: $repo_file"
    echo
    continue
  fi

  if ! cmp -s "$repo_file" "$live_file"; then
    echo "OUTDATED / DIFFERENT:"
    echo "  Repo: $repo_file"
    echo "  Live: $live_file"
    echo
    diff -u "$repo_file" "$live_file" || true
    echo
    echo "----------------------------------------"
    echo
  fi
done

echo "Done."
