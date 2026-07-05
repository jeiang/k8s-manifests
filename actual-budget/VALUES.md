# actual-budget Values

These values override the upstream `community-charts/actualbudget` chart for this cluster.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `1` | Runs one Actual Budget pod. |
| `fullnameOverride` | `actual-budget` | Fixes generated resource names. |
| `strategy.type` | `Recreate` | Avoids rolling-update multi-attach conflicts with the RWO Hetzner volume. |
| `strategy.rollingUpdate` | `null` | Clears the upstream rolling update settings. |
| `image.repository` | `actualbudget/actual-server` | Actual Budget container image repository. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `image.tag` | `""` | Uses the upstream chart default image tag. |
| `service.type` | `ClusterIP` | Keeps the service internal behind ingress. |
| `service.port` | `5006` | Exposes the Actual Budget HTTP port. |
| `service.name` | `http` | Names the service port. |
| `service.annotations` | `{}` | Optional Service annotations. |
| `ingress.enabled` | `true` | Creates public ingress. |
| `ingress.className` | `traefik` | Uses the Traefik IngressClass. |
| `ingress.annotations` | `cert-manager.io/cluster-issuer: letsencrypt-prod` | Requests TLS through cert-manager. |
| `ingress.hosts` | `budget.jeiang.dev` at `/` | Public hostname and path. |
| `ingress.tls` | `actual-budget-tls` for `budget.jeiang.dev` | TLS Secret and covered host. |
| `persistence.enabled` | `true` | Enables persistent application data. |
| `persistence.annotations` | `{}` | Optional PVC annotations. |
| `persistence.existingClaim` | `actual-budget-hcloud` | Mounts the pre-created and pre-populated hcloud PVC. |
| `persistence.storageClass` | `hcloud-volumes` | Uses Hetzner CSI storage when the chart creates a PVC. |
| `persistence.subPath` | `""` | Mounts the PVC root. |
| `persistence.volumeMode` | `""` | Uses Kubernetes default volume mode. |
| `persistence.accessModes` | `ReadWriteOnce` | Requests RWO access for Hetzner Cloud Volumes. |
| `persistence.size` | `10Gi` | Requested data volume size. |
| `login.method` | `password` | Enables password login. |
| `login.skipSSLVerification` | `false` | Keeps TLS verification enabled for login flows. |
| `login.allowedLoginMethods` | `password` | Restricts login methods to password. |
| `resources.requests` | `cpu: 50m`, `memory: 128Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: 250m`, `memory: 256Mi` | Runtime resource cap. |
| `initContainers` | `prepare-data-directories` busybox container | Creates `/data/server-files` and `/data/user-files` on empty volumes. |
| `podSecurityContext` | `fsGroup: 1000`, `fsGroupChangePolicy: OnRootMismatch` | Keeps copied data writable by the Actual Budget process. |
| `securityContext` | non-root UID/GID `1000`, drops all capabilities | Runs the application without privilege escalation. |
| `extraEnvVars` | `{}` | Optional extra environment variables. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |

## Notes

- `budget.jeiang.dev` must resolve to the Traefik load balancer before ingress is useful.
- Existing installs must copy data into `actual-budget-hcloud` before upgrading to these values.
- Do not commit one-off migration Jobs, copy pods, or live storage credentials.
