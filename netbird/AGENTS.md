# Chart Guidelines

## Scope

This local Helm chart deploys the self-hosted NetBird management server, dashboard, relay, reverse proxy, Traefik routes, persistent state, Bitwarden secret sync, and optional metrics.

## Runtime Contract

- Management and dashboard traffic use Traefik `IngressRoute` resources at `netbird.jeiang.dev`.
- Reverse proxy traffic uses Traefik `IngressRouteTCP` TLS passthrough for `proxy.jeiang.dev` and `*.proxy.jeiang.dev` only.
- STUN uses direct node exposure on UDP `3478`; Hetzner Cloud Load Balancers and Traefik do not proxy this UDP path.
- Relay replicas default to `1` because `relay.exposedAddress` advertises one shared `rels://` URL. Do not scale relay behind the same Service without relay-aware stickiness or distinct advertised relay addresses; peers connected to different relay pods cannot see each other.
- Relay pods use host networking and require nodes labeled `netbird.io/stun=true`.
- Server and relay Deployments use `Recreate`; rolling updates conflict with the server's RWO PVC and the relay's host-network STUN port binding.
- DNS for `stun.netbird.jeiang.dev` must point at the public address of the labeled relay node.
- DNS for `proxy.jeiang.dev` and `*.proxy.jeiang.dev` must point at the Traefik load balancer.
- Persistence uses the RWO-only `hcloud-volumes` StorageClass.
- `netbird-secrets` is expected to be synced by the chart-managed `BitwardenSecret`; the only direct namespace Secret should be the Bitwarden bootstrap `bw-auth-token`.
- CrowdSec IP reputation is optional and requires `proxy.crowdsec.enabled=true`, CrowdSec LAPI reachability, and a Bitwarden-synced bouncer key.

## Editing Notes

- Keep server secrets stable after first deploy.
- Keep the reverse proxy token in Bitwarden Secrets Manager; do not render it as a literal environment variable.
- Keep the CrowdSec bouncer key in Bitwarden Secrets Manager; do not render it as a literal environment variable.
- Do not add a manual literal `netbird-secrets` creation path to docs unless the user explicitly asks for an emergency fallback.
- Be careful changing relay `hostNetwork`, `stunPort`, replica count, or anti-affinity; these values control public reachability and relay peer rendezvous.
- Be careful changing proxy `IngressRouteTCP`, TLS passthrough, or ACME settings; the proxy must terminate TLS itself.
- The reverse proxy needs write access to `/certs` and namespace Lease RBAC for ACME certificate locking.
- The NetBird operator resources are not owned by this chart; use `netbird-resources/` for router and network-resource objects.

## Validation

```sh
helm lint ./netbird
helm template test ./netbird --namespace netbird
```
