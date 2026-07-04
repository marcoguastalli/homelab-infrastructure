#!/usr/bin/env bash
# networks — script stack (no compose.yaml; deploy.sh runs this apply.sh).
#
# Creates the two shared Docker networks every other stack declares as
# external (homelab-docs architecture/003). Idempotent: existing networks
# are left untouched. Per-stack <stack>_internal networks are NOT created
# here — each compose file owns its own.

set -Eeuo pipefail

log() { printf '[networks] %s\n' "$*"; }

ensure_network() {
  local name="$1" subnet="$2"
  if docker network inspect "$name" >/dev/null 2>&1; then
    log "OK: ${name} exists"
    return 0
  fi
  docker network create --driver bridge --subnet "$subnet" "$name" >/dev/null
  log "created ${name} (${subnet})"
}

ensure_network net_proxy 172.20.0.0/24
ensure_network net_monitoring 172.21.0.0/24
