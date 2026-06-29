# Secrets

Application and workload secrets should live in Bitwarden Secrets Manager and be synced into Kubernetes with `BitwardenSecret` resources.

## Policy

Do not commit live secret values. This includes application secrets, storage tokens, rclone credentials, Hetzner API tokens, Bitwarden access tokens, and one-off cluster bootstrap tokens.

Do not create application Secrets manually with literal values when a `BitwardenSecret` can own them instead. Prefer existing Kubernetes Secret references in `values.yaml`; do not add literal secret values.

## Allowed Direct Kubernetes Secrets

The only Kubernetes Secrets expected to be created directly in normal operation are bootstrap/operator credentials required before Bitwarden can sync anything:

- `kube-system/hcloud`, used by Hetzner Cloud Controller Manager and Hetzner CSI.
- Per-namespace `bw-auth-token` Secrets, used by the Bitwarden Secrets Manager operator to read Bitwarden items.

All other application and workload secrets should be stored in Bitwarden Secrets Manager and synced by a `BitwardenSecret`.

## Operational Review

Before applying manifests, review public hostnames, ACME issuer names, external services, hostPort exposure, persistent storage, and RBAC grants. Pay particular attention to any value that changes a Secret name, Secret key, Bitwarden organization ID, Bitwarden secret ID, or namespace-local `bw-auth-token` reference.
