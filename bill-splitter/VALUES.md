# bill-splitter Values

These values configure the local bill splitter Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `1` | Runs one bill splitter pod. |
| `image.repository` | `ghcr.io/jeiang/bill-splitter` | Bill splitter image repository. |
| `image.tag` | `latest` | Bill splitter image tag. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `service.type` | `ClusterIP` | Keeps the service internal behind ingress. |
| `service.port` | `80` | HTTP service port. |
| `resources.requests` | `cpu: 25m`, `memory: 32Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: 100m`, `memory: 128Mi` | Runtime resource cap. |
| `ingress.enabled` | `true` | Creates public ingress. |
| `ingress.className` | `traefik` | Uses Traefik ingress. |
| `ingress.hosts` | `bill-split.jeiang.dev` | Public hostname. |
| `ingress.tls.enabled` | `true` | Enables TLS. |
| `ingress.tls.secretName` | `bill-splitter-tls` | TLS Secret name. |
| `ingress.redirectToHttps` | `true` | Creates HTTPS redirect middleware. |
| `certManager.enabled` | `true` | Enables cert-manager integration. |
| `certManager.clusterIssuer.create` | `false` | Uses an existing ClusterIssuer by default. |
| `certManager.clusterIssuer.name` | `letsencrypt-prod` | ClusterIssuer name. |
| `certManager.clusterIssuer.email` | `aidan@aidanpinard.co` | ACME account email if this chart creates the issuer. |
| `certManager.clusterIssuer.server` | `https://acme-v02.api.letsencrypt.org/directory` | ACME server if this chart creates the issuer. |

## Notes

- DNS for `bill-split.jeiang.dev` must point at the Traefik load balancer.
- Review the ACME email and server before setting `certManager.clusterIssuer.create=true`.
