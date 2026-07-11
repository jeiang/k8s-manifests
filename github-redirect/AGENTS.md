# Chart Guidelines

## Scope

This local Helm chart creates a Traefik-only permanent redirect from `github.jeiang.dev` to `https://github.com/jeiang`. It runs no workload.

## Runtime Contract

- The public host is `ingress.host`.
- This chart intentionally does not create a plain `networking.k8s.io/v1 Ingress`; Kubernetes `Ingress` requires every rule to reference a real backend Service, which this redirect-only route doesn't have.
- The `IngressRoute` forwards to Traefik's built-in `noop@internal` `TraefikService` instead of a real backend, so there is no Deployment, Service, or pod.
- TLS uses `ingress.tls.secretName` and the existing `letsencrypt-prod` `ClusterIssuer`. cert-manager's ingress-shim does not watch `IngressRoute` the way it watches plain `Ingress`, so this chart creates its own `Certificate` directly — same pattern as `netbird`.
- The redirect middleware uses `redirectRegex`, not `redirectScheme`, because the target is a different host than the source; `redirectScheme` can only change scheme/port.

## Editing Notes

- Keep `redirect.target` free of a trailing slash; the middleware appends `/${1}` to it.
- Changing `ingress.host` changes the regex host matched by the middleware; update DNS and `ingress.tls.secretName` together.
- Do not add a placeholder backend Deployment/Service to satisfy a plain `Ingress`; `noop@internal` is Traefik's built-in mechanism for redirect-only routes.

## Validation

```sh
helm lint ./github-redirect
helm template github-redirect ./github-redirect --namespace github-redirect
```
