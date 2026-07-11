# github-redirect Values

These values configure the local github-redirect Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `ingress.enabled` | `true` | Creates the Traefik `Middleware`, `IngressRoute`, and cert-manager `Certificate`. |
| `ingress.entryPoint` | `websecure` | Traefik entryPoint the `IngressRoute` listens on. |
| `ingress.host` | `github.jeiang.dev` | Public redirect source hostname; also drives the middleware's regex host. |
| `ingress.tls.enabled` | `true` | Enables TLS on the `IngressRoute` and creates the `Certificate`. |
| `ingress.tls.secretName` | `github-redirect-tls` | TLS Secret name populated by the `Certificate`. |
| `ingress.certManager.enabled` | `true` | Creates the cert-manager `Certificate` resource. |
| `ingress.certManager.clusterIssuer` | `letsencrypt-prod` | `ClusterIssuer` referenced by the `Certificate`. |
| `redirect.target` | `https://github.com/jeiang` | Base URL the redirect sends traffic to; the original path and query are appended without a duplicated slash. |

## Notes

- DNS for `ingress.host` must point at the Traefik load balancer before installing, so the ACME HTTP-01 challenge can complete.
- This chart deploys no Deployment or Service; Traefik's built-in `noop@internal` service handles the redirect-only route, so there is no backend to scale, probe, or troubleshoot beyond the `IngressRoute`/`Middleware`/`Certificate`.
- Changing `ingress.host` also changes the regex host matched by the redirect middleware; keep `ingress.tls.secretName` and DNS in sync with it.
- Keep `redirect.target` free of a trailing slash; the middleware appends `/${1}`.
