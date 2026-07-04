#!/usr/bin/env bash
# Consistent Pi-hole export (STD-002 rule 11), invoked nightly by
# homelab-ops pre-backup-export.sh. Teleporter is Pi-hole's own
# consistent-export mechanism (config + gravity + local DNS records);
# it writes into /dumps, bind-mounted to ${DATA_ROOT}/pihole/dumps.
# Keeps the last 7 exports.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"
DUMP_DIR="${DATA_ROOT}/pihole/dumps"

# Teleporter filenames embed the timestamp, so lexical sort is
# chronological; keep the newest 7.
docker exec --workdir /dumps pihole pihole-FTL --teleporter >/dev/null
find "$DUMP_DIR" -maxdepth 1 -name '*.zip' -type f | sort | head -n -7 \
  | xargs -r rm --
printf '[pihole-dump] OK: %s\n' \
  "$(find "$DUMP_DIR" -maxdepth 1 -name '*.zip' -type f | sort | tail -n 1)"
