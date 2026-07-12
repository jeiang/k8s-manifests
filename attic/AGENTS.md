# Chart Guidelines

## Scope

This local Helm chart deploys the Attic server fork with GitHub Actions OIDC,
Mega S4 object storage, a SQLite metadata database, and public Traefik ingress.

## Runtime Contract

- Keep the image pinned to an immutable commit build from `ghcr.io/jeiang/attic`.
- Keep one replica and the `Recreate` strategy while SQLite uses an
  `hcloud-volumes` RWO claim.
- Keep the canonical API endpoint, GitHub OIDC audience, ingress host, and TLS
  host aligned; the endpoint and audience must end in `/`.
- Store S3 credentials and the base64 PKCS#1 RSA private key only in the
  Bitwarden-synced Secret.
- GitHub rules must match immutable `repository_id` plus an explicitly trusted
  protected ref. Do not grant cache administration permissions to CI.
- Changing chunking settings harms deduplication reuse for existing data.

## Validation

```sh
helm lint ./attic
helm template attic ./attic --namespace attic
```

Inspect the rendered ConfigMap whenever OIDC rules or storage settings change.
