# actual-budget Values

These values override the upstream `community-charts/actualbudget` chart for this cluster.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `1` | Runs one Actual Budget pod. |
| `fullnameOverride` | `actual-budget` | Fixes generated resource names. |
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
| `persistence.existingClaim` | `""` | Creates a PVC instead of using an existing one. |
| `persistence.storageClass` | `rclone-csi` | Uses rclone-backed storage. |
| `persistence.subPath` | `""` | Mounts the PVC root. |
| `persistence.volumeMode` | `""` | Uses Kubernetes default volume mode. |
| `persistence.accessModes` | `ReadWriteMany` | Allows RWX semantics from the storage backend. |
| `persistence.size` | `10Gi` | Requested data volume size. |
| `login.method` | `password` | Enables password login. |
| `login.skipSSLVerification` | `false` | Keeps TLS verification enabled for login flows. |
| `login.allowedLoginMethods` | `password` | Restricts login methods to password. |
| `resources.requests` | `cpu: 100m`, `memory: 256Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: 500m`, `memory: 512Mi` | Runtime resource cap. |
| `initContainers` | `prepare-data-directories` busybox container | Creates `/data/server-files` and `/data/user-files` on empty volumes. |
| `podSecurityContext` | `fsGroup: 1000`, `fsGroupChangePolicy: OnRootMismatch` | Matches rclone mount ownership. |
| `securityContext` | non-root UID/GID `1000`, drops all capabilities | Runs the application without privilege escalation. |
| `extraEnvVars` | `{}` | Optional extra environment variables. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |

## Notes

- `budget.jeiang.dev` must resolve to the Traefik load balancer before ingress is useful.
- The `rclone-csi` StorageClass must provide a working `rclone-config` Secret and mount ownership compatible with UID/GID `1000`.
