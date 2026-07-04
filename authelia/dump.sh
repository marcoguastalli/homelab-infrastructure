#!/usr/bin/env bash
# Consistent dump of Authelia's SQLite DB (STD-002 rule 11), invoked
# nightly by homelab-ops pre-backup-export.sh before Duplicati runs.
# Uses SQLite's online backup API — a raw copy of a live DB is not a
# valid backup. Needs the registry reachable (alpine pull, cached after
# the first run); an offline night keeps yesterday's dump.

set -Eeuo pipefail

DATA_ROOT="${DATA_ROOT:-/srv/homelab/data}"
DB_DIR="${DATA_ROOT}/authelia"
DUMP_DIR="${DATA_ROOT}/authelia/dumps"

install -d "$DUMP_DIR"
docker run --rm -v "${DB_DIR}:/work" alpine:3.21 sh -c \
  "apk add --no-cache -q sqlite \
   && sqlite3 /work/db.sqlite3 '.backup /work/dumps/db.sqlite3'"
printf '[authelia-dump] OK: %s/db.sqlite3\n' "$DUMP_DIR"
