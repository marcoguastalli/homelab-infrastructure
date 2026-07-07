# Changelog

All notable changes to this repository are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-07-07

### Added

- Script stacks: `networks` (net_proxy, net_monitoring), `tls`
  (10-year self-signed wildcard, ADR-011).
- Compose stacks: `traefik` (ingress, middlewares, dashboard),
  `authelia` (SSO + 2FA, deny-by-default access control), `pihole`
  (split-horizon DNS + Teleporter dump), `wireguard` (wg-easy).
- CI and deploy workflows delegating to homelab-ops reusable workflows.
- `CLAUDE.md`: version-pin inventory with couplings and the ADR-014
  upgrade procedure for the platform layer.

### Fixed

- wireguard: entrypoint override forces the nft iptables backend —
  wg-easy:14 defaults to legacy, which crash-loops on nft-only
  Raspberry Pi kernels.
- wireguard: healthcheck probes `127.0.0.1` instead of `localhost`
  (resolves to `::1` first, but wg-easy binds IPv4-only — the
  container sat permanently unhealthy).
- wireguard: `WG_DEFAULT_DNS` is site-specific and moved from a
  compose literal to the secrets env file.
- pihole: split-horizon wildcard IP corrected to the reference
  install's `192.168.8.110` (must match bootstrap `LAN_IP`).
