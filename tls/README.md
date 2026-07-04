# tls/

Script stack: generates the single **10-year self-signed wildcard
certificate** for `*.kirito.com` into `/srv/homelab/secrets/tls/`
([ADR-011](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-011-self-signed-tls.md)).
Traefik serves it as the default cert via the file provider
(`traefik/config/dynamic/tls.yaml`).

- Idempotent: an existing cert is never overwritten. To rotate, delete
  `wildcard.crt` + `wildcard.key` and redeploy this stack.
- Trust the cert per device once:
  [RB-008](https://github.com/marcoguastalli/homelab-docs/blob/main/runbooks/RB-008-trust-selfsigned-cert.md).
- Upgrade path to a real domain + Let's Encrypt is contained in this
  directory plus one Traefik config file (ADR-011).
