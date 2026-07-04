# Contributing

Workflow and conventions are defined centrally in
[homelab-docs](https://github.com/marcoguastalli/homelab-docs):
[STD-002 compose](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-002-compose-conventions.md),
[STD-003 traefik](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-003-traefik-conventions.md),
[STD-006 commits & branches](https://github.com/marcoguastalli/homelab-docs/blob/main/standards/STD-006-commit-and-branch-conventions.md).

Repo-specific rules:

1. Merging to `main` **deploys** — the PR template's "which stacks
   redeploy" answer is not decoration.
2. Network subnets, published ports and middleware names are contracts
   consumed by homelab-services; changing them needs an ADR first.
3. New subdomain = same PR updates architecture/005 (docs) and the
   Authelia `access_control` rules here — default policy is deny, so
   forgetting the rule means 403, not exposure.
4. Every compose change must render against its `.env.example`
   (CI enforces; run it locally with
   `docker compose --project-directory <stack> --env-file <stack>/.env.example config -q`).
