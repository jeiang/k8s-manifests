# Chart Guidelines

## Scope

This local Helm chart deploys Pocket ID with LLDAP, persistent state, ingress, Bitwarden secret sync, and optional NetBird access to LDAP.

## Runtime Contract

- Pocket ID is public at `auth.jeiang.dev` through Traefik and cert-manager.
- LLDAP is internal-only by default through a `ClusterIP` Service.
- Persistence uses the RWO-only `hcloud-volumes` StorageClass.
- `idp-secrets` is expected to be synced by the chart-managed `BitwardenSecret`; the only direct namespace Secret should be the Bitwarden bootstrap `bw-auth-token`.
- The optional NetBird integration is disabled by default and is enabled with `netbird.enabled=true`.
- When NetBird is enabled, the subchart should render the `lldap` `NetworkResource` only; shared router and API token resources belong to `netbird-resources/`.

## Editing Notes

- Keep LLDAP secret keys stable after first deploy.
- Do not add a manual literal `idp-secrets` creation path to docs unless the user explicitly asks for an emergency fallback.
- Do not enable public LLDAP ingress unless there is an explicit reason and DNS/TLS are updated.
- Run `helm dependency build ./idp` after dependency changes or before rendering with `netbird.enabled=true`.
- Avoid reintroducing static hostPath PV defaults; dynamic Hetzner CSI provisioning is the default.

## Validation

```sh
helm lint ./idp
helm template test ./idp --namespace idp
helm template test ./idp --namespace idp --set netbird.enabled=true
```
