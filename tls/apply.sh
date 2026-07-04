#!/usr/bin/env bash
# tls — script stack (no compose.yaml; deploy.sh runs this apply.sh).
#
# Generates the single 10-year self-signed wildcard certificate for
# *.kirito.com into /srv/homelab/secrets/tls/ (ADR-011). Traefik's file
# provider picks it up as the default certificate (traefik/config/
# dynamic/tls.yaml). Idempotent: an existing cert is never overwritten —
# to rotate, delete both files and redeploy (RB-005).

set -Eeuo pipefail

log() { printf '[tls] %s\n' "$*"; }

DOMAIN="${TLS_DOMAIN:-kirito.com}"
TLS_DIR="${SECRETS_DIR:-/srv/homelab/secrets}/tls"
CRT="${TLS_DIR}/wildcard.crt"
KEY="${TLS_DIR}/wildcard.key"

if [[ -f $CRT && -f $KEY ]]; then
  log "OK: certificate exists ($(openssl x509 -in "$CRT" -noout -enddate))"
  exit 0
fi

install -d -m 0700 "$TLS_DIR"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 3650 \
  -keyout "$KEY" -out "$CRT" \
  -subj "/CN=*.${DOMAIN}" \
  -addext "subjectAltName=DNS:*.${DOMAIN},DNS:${DOMAIN}" \
  -addext "basicConstraints=CA:FALSE" 2>/dev/null
chmod 0600 "$KEY"
chmod 0644 "$CRT"
log "generated ${CRT} (10 years, *.${DOMAIN} + ${DOMAIN})"
log "trust it on your devices: homelab-docs RB-008"
