# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this repo is

The platform layer of the kirito.com homelab (Raspberry Pi 5): four
image stacks (`traefik`, `authelia`, `pihole`, `wireguard`) and two
script stacks (`networks`, `tls` — `apply.sh`, no images), deployed by
merge-to-main via the homelab-ops reusable workflows. Conventions live
in homelab-docs (STD-002 compose, STD-003 traefik, architecture/003–005);
this file covers what is repo-specific — above all, **how versions are
upgraded**. Everything here is ingress/auth/DNS/VPN: the layer where a
bad bump locks you out, and the layer ADR-014 patches *immediately* on
Trivy HIGH/CRITICAL, not at the monthly window.

## Where versions are pinned

Image tags are exact pins; `latest`/`stable` are banned (STD-002
rule 2). Every version in this repo, and its coupling:

| Pin | File(s) | Coupling to watch |
|---|---|---|
| Service images | `<stack>/compose.yaml` `image:` lines | — |
| Dump-helper image | `alpine:3.21` in `authelia/dump.sh` | Same pin in `homelab-services` (`monitoring/dump.sh`, `monitoring/prepare.sh`, `uptime-kuma/dump.sh`) — bump all four together |
| Traefik config schema | `traefik/config/traefik.yaml` + `config/dynamic/*.yaml` | Version-coupled to the image major (v2→v3 was a syntax break) — re-read both when crossing a major |
| Authelia config schema | `authelia/config/configuration.yml` | Authelia renames/deprecates config keys between **minors**; also `users_database.yml` on the Pi must stay parseable |
| Reusable workflows | `.github/workflows/{ci,deploy}.yml` reference `homelab-ops@main` | Deliberately unpinned — ops main is the platform contract |

## Upgrade procedure (ADR-014: manual updates, automated reporting)

Updates land in a monthly maintenance window (RB-006), **one PR per
stack**. The weekly `update-report.yml` in homelab-ops maintains a
GitHub issue listing newer tags — with one blind spot in this repo
(wg-easy, below). Trivy HIGH/CRITICAL on any stack here is patched
immediately: this repo *is* the ingress/auth/VPN exception.

Per-stack steps:

1. **Verify the tag exists** — never trust memory; registries move fast
   (see commands below).
2. **Read the release notes** for anything crossing a major/minor:
   - `traefik`: static config (`traefik.yaml`) and dynamic files
     (`middlewares.yaml`, `tls.yaml`) must match the major. Keep the
     `:8082` metrics entrypoint — Prometheus scrapes it over
     `net_monitoring`. A broken Traefik takes down **every** UI,
     including the ones you would use to debug it; the deploy gate's
     auto-rollback is the net, but do the bump from the LAN.
   - `authelia`: check the deprecation section of the release notes
     against `config/configuration.yml` — keys move between minors and
     the container refuses to start on unknown/removed keys. Config is
     mounted ro from Git, so the fix is a PR, not a Pi edit.
   - `pihole`: calendar tags (`YYYY.MM.N`), not semver. Stay on the
     v6-era `FTLCONF_*` env naming — v5-style vars are silently
     ignored. The split-horizon wildcard lives in
     `config/99-kirito.conf`, loaded via `FTLCONF_misc_etc_dnsmasq_d`.
   - `wg-easy`: integer-only major tags (`14`) on ghcr — the weekly
     update report's semver filter **skips these**, so check manually
     each window. Majors have historically reworked the config format
     (migration!); confirm arm64 in the release. Breaking WireGuard or
     Pi-hole can cut off *remote* access — bump these from the LAN too.
     The `entrypoint:` override in `wireguard/compose.yaml` forces the
     nft iptables backend (Pi kernels have no legacy modules) and
     restates the image CMD — on any bump, check whether the new image
     defaults to nft (drop the override) or changed its CMD (restate).
3. **Bump the pin** (and any coupled file from the table).
4. **Validate locally** (CI-identical — see commands below).
5. **PR** using the template: "which stacks redeploy" = the bumped
   stack. Merging **deploys**; the health gate auto-rolls-back a broken
   image.
6. **Verify after merge**: Uptime Kuma stays green, the container is
   healthy in `docker ps`, and — for this repo — log in through
   Authelia once and resolve a `*.kirito.com` name to prove the
   auth/DNS path end-to-end.

If a bump needs a bigger `mem_limit`, update the RAM budget table in
homelab-docs `architecture/005` in the same PR wave.

## Checking registry tags

`skopeo list-tags docker://<image>` if available; otherwise:

```bash
# Docker Hub — traefik is a library image
curl -s "https://hub.docker.com/v2/repositories/library/traefik/tags/?page_size=50" \
  | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"

# Docker Hub — namespaced (authelia/authelia, pihole/pihole)
curl -s "https://hub.docker.com/v2/repositories/<ns>/<repo>/tags/?page_size=50" \
  | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"

# ghcr (wg-easy)
TOK=$(curl -s "https://ghcr.io/token?scope=repository:wg-easy/wg-easy:pull&service=ghcr.io" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
curl -s -H "Authorization: Bearer $TOK" \
  "https://ghcr.io/v2/wg-easy/wg-easy/tags/list?n=100"
```

## Local validation (run before every PR)

```bash
# Compose render, exactly as CI does it (networks/ and tls/ have no
# compose.yaml and are skipped by the glob)
export DATA_ROOT=/srv/homelab/data
for f in */compose.yaml; do d=$(dirname "$f"); \
  docker compose --project-directory "$d" --env-file "$d/.env.example" config -q; done

# Linters (same images/versions as CI behavior)
docker run --rm -v "$PWD:/mnt:ro" koalaman/shellcheck:v0.10.0 -x $(git ls-files '*.sh')
docker run --rm -v "$PWD:/mnt:ro" -w /mnt mvdan/shfmt:v3.10.0 -d -i 2 -bn -ci $(git ls-files '*.sh')
docker run --rm -v "$PWD:/code:ro" -w /code registry.gitlab.com/pipeline-components/yamllint:latest yamllint -s .
docker run --rm -v "$PWD:/workdir:ro" davidanson/markdownlint-cli2:v0.17.2 "**/*.md"
docker run --rm -v "$PWD:/mnt:ro" zricethezav/gitleaks:v8.21.2 detect --source /mnt --no-git --redact
```

## Repo rules Claude must not violate

- This repo holds **all three** published-port exceptions (STD-002
  rule 3): traefik 80/443, pihole 53, wireguard 51820/udp. Nothing
  else here or anywhere may add `ports:`.
- Secrets never enter Git — `.env.example` holds placeholders only;
  real values live in `/srv/homelab/secrets/` on the Pi. Same for
  `users_database.yml` (only the `.example` is committed).
- Adding a service to the platform means a rule in Authelia's
  `access_control` (default is deny) — same PR wave as the service's
  catalog row (architecture/005 intake checklist).
- `main` is protected (five `validate / *` contexts, squash-only);
  all changes go through a PR — direct pushes are rejected.
- Push over SSH via the `github.com_mg` remote alias (the HTTPS OAuth
  token lacks `workflow` scope).

The same pin-bump procedure applies to `homelab-services` — its
couplings (duplicati env file, grafana provisioning, etc.) are
documented in its own CLAUDE.md.
