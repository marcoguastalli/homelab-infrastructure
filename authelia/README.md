# authelia/

SSO + 2FA portal
([ADR-003](https://github.com/marcoguastalli/homelab-docs/blob/main/adr/ADR-003-authelia.md)).
`auth.kirito.com`; enforcement happens in Traefik via the
`authelia@file` forwardAuth middleware, policy per the table in
[architecture/005](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/005-platform-services.md).
`access_control.default_policy: deny` — adding a service REQUIRES a rule
in `config/configuration.yml` (RB-002 covers this).

- Users: `${DATA_ROOT}/authelia/users_database.yml` on the Pi, never in
  Git (password hashes). Bootstrap it from `users_database.yml.example`.
- Secrets (session, storage encryption, JWT) via
  `/srv/homelab/secrets/authelia.env` — see `.env.example`.
- No mail server: 2FA enrolment links land in
  `${DATA_ROOT}/authelia/notification.txt`.
- **Backup** (STD-002 rule 11): `dump.sh` performs an SQLite online
  backup to `${DATA_ROOT}/authelia/dumps/db.sqlite3`, nightly via
  homelab-ops `pre-backup-export.sh`.
