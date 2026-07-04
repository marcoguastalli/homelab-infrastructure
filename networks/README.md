# networks/

Script stack: creates the two shared Docker networks
([architecture/003](https://github.com/marcoguastalli/homelab-docs/blob/main/architecture/003-network-architecture.md)).
Idempotent; must be the first stack deployed on an empty Pi. Every other
compose file declares them `external: true`. Per-stack `<stack>_internal`
networks are owned by their compose files, not created here.
