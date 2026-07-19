# Chart Guidelines

## Scope

This local Helm chart deploys the Attic server fork with GitHub Actions OIDC,
Mega S4 object storage, a Supabase-hosted PostgreSQL metadata database, and
public Traefik ingress.

## Runtime Contract

- Keep the image pinned to an immutable commit build from `ghcr.io/jeiang/attic`.
- The chart is stateless: metadata lives in the external PostgreSQL database
  and objects in S3. Do not reintroduce a PVC or SQLite settings.
- Keep the canonical API endpoint, GitHub OIDC audience, ingress host, and TLS
  host aligned; the endpoint and audience must end in `/`.
- Store S3 credentials, the base64 PKCS#1 RSA private key, and the PostgreSQL
  connection URL only in the Bitwarden-synced Secret. The database URL reaches
  the server via `ATTIC_SERVER_DATABASE_URL`; the rendered `server.toml` must
  never contain `database.url`.
- Pod egress is IPv4-only (nodes are dual-stack, pods are not), so the
  database URL must use a Supabase host that resolves over IPv4: the
  Supavisor session pooler on port 5432 or the IPv4 add-on, not the
  IPv6-only direct host. Avoid the transaction-mode pooler (port 6543); the
  server relies on prepared statements.
- GitHub rules must match an immutable repository or owner ID plus an explicitly
  trusted protected-ref claim. Do not grant cache administration permissions to CI.
- Changing chunking settings harms deduplication reuse for existing data.
- Keep `server.requireProofOfPossession: false`: the server disables
  chunk-level upload dedup negotiation whenever proof of possession is
  required. The accepted tradeoff is that knowing a NAR hash grants access to
  that NAR in the global dedup store.

## Validation

```sh
helm lint ./attic
helm template attic ./attic --namespace attic
```

Inspect the rendered ConfigMap whenever OIDC rules or storage settings change.
