# Chart Guidelines

## Scope

This local Helm chart deploys the self-hosted NetBird management server, dashboard, relay, Traefik ingress routes, persistent state, Bitwarden secret sync, and optional metrics.

## Runtime Contract

- Management and dashboard traffic use Traefik `IngressRoute` resources at `netbird.jeiang.dev`.
- STUN uses direct node exposure on UDP `3478`; Hetzner Cloud Load Balancers and Traefik do not proxy this UDP path.
- Relay replicas default to `2` and use required pod anti-affinity so they do not share a host.
- Relay pods use host networking and require nodes labeled `netbird.io/stun=true`.
- DNS for `stun.netbird.jeiang.dev` must point at the public addresses of the labeled relay nodes.
- Persistence uses the RWO-only `hcloud-volumes` StorageClass.
- `netbird-secrets` is expected to be synced by the chart-managed `BitwardenSecret`; the only direct namespace Secret should be the Bitwarden bootstrap `bw-auth-token`.

## Editing Notes

- Keep server secrets stable after first deploy.
- Do not add a manual literal `netbird-secrets` creation path to docs unless the user explicitly asks for an emergency fallback.
- Be careful changing relay `hostNetwork`, `stunPort`, or anti-affinity; these values control public reachability.
- The NetBird operator resources are not owned by this chart; use `netbird-resources/` for router and network-resource objects.

## Validation

```sh
helm lint ./netbird
helm template test ./netbird --namespace netbird
```
