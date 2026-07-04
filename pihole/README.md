# pihole/

LAN + VPN DNS with ad-blocking; admin UI at `dns.kirito.com`
(two_factor). Publishes port 53 — one of the three allowed exceptions
(STD-002 rule 3).

- **Split-horizon**: `config/99-kirito.conf` maps `*.kirito.com` to the
  Pi ([architecture/003](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/003-network-architecture.md)).
  Git-managed — never add records via the UI. The IP must match
  `LAN_IP` in homelab-bootstrap.
- The Pi itself does **not** resolve through Pi-hole (bootstrap
  paradox, architecture/003) — the host resolver points at the router.
- Point the router's DHCP DNS at the Pi to enroll the LAN; WireGuard
  clients get it via `WG_DEFAULT_DNS`.
- **Backup** (STD-002 rule 11): `dump.sh` runs Pi-hole's Teleporter
  export into `${DATA_ROOT}/pihole/dumps/` (keeps 7), nightly via
  homelab-ops `pre-backup-export.sh`.
