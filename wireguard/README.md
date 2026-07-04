# wireguard/

wg-easy: WireGuard server + peer-management UI (`vpn.kirito.com`,
two_factor). **The only internet-facing listener on the platform** — the
router forwards exactly UDP 51820 here
([architecture/003](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/003-network-architecture.md)).

- `WG_HOST` must be your real WAN IP or a DDNS hostname — `kirito.com`
  is unregistered and does not resolve publicly (ADR-011 context).
- Clients get Pi-hole as DNS (`WG_DEFAULT_DNS`), so remote access has
  the same split-horizon names and ad-blocking as the LAN.
- `NET_ADMIN` + `SYS_MODULE` caps and forwarding sysctls are the
  documented exception to the container-hardening baseline
  ([architecture/004](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/004-security-architecture.md)):
  WireGuard needs to create interfaces and NAT.
- State (`${DATA_ROOT}/wireguard`, peer configs + keys) is small, files
  are written atomically on change — backed up raw, no `dump.sh` needed
  (STD-002 rule 11 targets live databases).
