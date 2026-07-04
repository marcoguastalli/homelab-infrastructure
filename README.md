# homelab-infrastructure

The platform layer of the [kirito.com homelab](https://github.com/marcoguastalli/homelab-docs):
ingress, SSO, DNS and VPN. Everything in
[homelab-services](https://github.com/marcoguastalli/homelab-services)
rides on the networks, certificate and middlewares defined here.

Architecture:
[003 network](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/003-network-architecture.md),
[004 security](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/004-security-architecture.md),
[005 services](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/005-platform-services.md).
Conventions:
[STD-002 compose](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-002-compose-conventions.md),
[STD-003 traefik](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-003-traefik-conventions.md).

## Stacks

| Stack | Type | Published ports | Provides |
|---|---|---|---|
| `networks` | script | — | `net_proxy` (172.20.0.0/24), `net_monitoring` (172.21.0.0/24) |
| `tls` | script | — | 10-year self-signed wildcard cert in `/srv/homelab/secrets/tls/` |
| `traefik` | compose | 80, 443 | Single ingress, TLS, shared middlewares, dashboard |
| `authelia` | compose | — | SSO + 2FA (`auth.kirito.com`), forwardAuth backend |
| `pihole` | compose | 53 | LAN/VPN DNS, ad-blocking, split-horizon `*.kirito.com` |
| `wireguard` | compose | 51820/udp | VPN — the only internet-facing listener |

These are the **only** stacks allowed published ports (STD-002 rule 3).

## How changes reach the Pi

PR → CI (`validate / *`, via
[homelab-ops reusable-validate](https://github.com/marcoguastalli/homelab-ops))
→ squash-merge to `main` → `deploy` workflow detects changed stacks →
`deploy.sh` on the Pi's self-hosted runner, one stack at a time, health
gate + auto-rollback. Manual path (first bring-up, GitHub down):
`deploy.sh homelab-infrastructure <stack>` directly on the Pi.

## First bring-up order

Deploy order matters **once**, on an empty Pi (afterwards any subset can
deploy in any order):

```bash
DEPLOY=/srv/homelab/repos/homelab-ops/scripts/deploy/deploy.sh
$DEPLOY homelab-infrastructure networks   # shared docker networks
$DEPLOY homelab-infrastructure tls        # wildcard cert into secrets/
$DEPLOY homelab-infrastructure authelia   # BEFORE traefik: the traefik
                                          # dashboard health-gates through
                                          # the authelia middleware
$DEPLOY homelab-infrastructure traefik
$DEPLOY homelab-infrastructure pihole
$DEPLOY homelab-infrastructure wireguard
```

Before the first deploy, create each stack's secrets file on the Pi from
its `.env.example` (`/srv/homelab/secrets/<stack>.env`, mode 0600) and
`${DATA_ROOT}/authelia/users_database.yml` from
`authelia/users_database.yml.example`.

## Repository layout

```text
networks/   apply.sh                      script stack
tls/        apply.sh                      script stack
traefik/    compose.yaml  config/         static + dynamic file provider
authelia/   compose.yaml  config/  dump.sh
pihole/     compose.yaml  config/  dump.sh
wireguard/  compose.yaml
```

Every compose stack ships a complete `.env.example`; CI renders each
stack against it. Secrets never enter this repo
([ADR-008](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-008-secrets-management.md));
gitleaks runs on every PR.
