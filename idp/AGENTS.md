# Chart Guidelines

## Scope

This local Helm chart deploys Pocket ID with persistent state, ingress, Bitwarden secret sync, and email delivery. Pocket ID is the only source of truth for users and groups.

## Runtime Contract

- Pocket ID is public at `auth.jeiang.dev` through Traefik and cert-manager.
- Pocket ID sends email through iCloud SMTP as `noreply@jeiang.dev` when `pocketId.smtp.enabled=true`.
- User signups use admin-issued signup tokens through `ALLOW_USER_SIGNUPS=withToken`.
- Persistence uses the RWO-only `hcloud-volumes` StorageClass.
- `idp-secrets` is expected to be synced by the chart-managed `BitwardenSecret`; the only direct namespace Secret should be the Bitwarden bootstrap `bw-auth-token`.
- Pocket ID owns identity data directly. Do not add LDAP sync, LDAP bind secrets, or an LDAP sidecar/service without an explicit migration plan.

## Editing Notes

- Keep the Pocket ID encryption key stable after first deploy.
- Keep the SMTP password in Bitwarden Secrets Manager and expose it through `SMTP_PASSWORD_FILE`; do not render it as a literal environment variable.
- Do not add a manual literal `idp-secrets` creation path to docs unless the user explicitly asks for an emergency fallback.
- Avoid reintroducing static hostPath PV defaults; dynamic Hetzner CSI provisioning is the default.
- When removing legacy LLDAP data after migration, treat PVC/PV and Bitwarden secret deletion as operator actions, not chart-managed cleanup.

## Validation

```sh
helm lint ./idp
helm template test ./idp --namespace idp
```
