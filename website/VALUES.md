# website Values

These values configure the local website Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `1` | Runs one website pod. |
| `image.repository` | `ghcr.io/jeiang/website` | Website image repository. |
| `image.tag` | `sha-6ac94e3` | Website image tag. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `service.type` | `ClusterIP` | Keeps the service internal behind ingress. |
| `service.port` | `80` | HTTP service port. |
| `resources.requests` | `cpu: 25m`, `memory: 32Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: 100m`, `memory: 128Mi` | Runtime resource cap. |
| `ingress.enabled` | `true` | Creates public ingress. |
| `ingress.className` | `traefik` | Uses Traefik ingress. |
| `ingress.hosts` | `jeiang.dev`, `aidanpinard.co`, `pinard.co.tt` | Public hostnames. |
| `ingress.tls.enabled` | `true` | Enables TLS. |
| `ingress.tls.secretName` | `website-tls` | TLS Secret name. |
| `ingress.redirectToHttps` | `true` | Creates HTTPS redirect middleware. |
| `certManager.enabled` | `true` | Enables cert-manager integration. |
| `certManager.clusterIssuer.create` | `false` | Uses an existing ClusterIssuer by default. |
| `certManager.clusterIssuer.name` | `letsencrypt-prod` | ClusterIssuer name. |
| `certManager.clusterIssuer.email` | `aidan@aidanpinard.co` | ACME account email if this chart creates the issuer. |
| `certManager.clusterIssuer.server` | `https://acme-v02.api.letsencrypt.org/directory` | ACME server if this chart creates the issuer. |

## Notes

- DNS for every `ingress.hosts` entry must point at the Traefik load balancer.
- Review the ACME email and server before setting `certManager.clusterIssuer.create=true`.
