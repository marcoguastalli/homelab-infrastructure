# Changelog

All notable changes to this repository are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added

- Script stacks: `networks` (net_proxy, net_monitoring), `tls`
  (10-year self-signed wildcard, ADR-011).
- Compose stacks: `traefik` (ingress, middlewares, dashboard),
  `authelia` (SSO + 2FA, deny-by-default access control), `pihole`
  (split-horizon DNS + Teleporter dump), `wireguard` (wg-easy).
- CI and deploy workflows delegating to homelab-ops reusable workflows.
