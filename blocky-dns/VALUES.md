# blocky-dns Values

These values configure the local Blocky DNS Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `2` | Fixed replica count for availability across node reboots/maintenance; ignored when `autoscaling.enabled=true`. |
| `image.repository` | `ghcr.io/0xerr0r/blocky` | Blocky image repository. |
| `image.tag` | `v0.33.0` | Blocky image tag. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `service.type` | `ClusterIP` | Keeps DNS service internal. |
| `service.annotations` | `{}` | Optional Service annotations. |
| `service.externalTrafficPolicy` | `Cluster` | Service traffic policy if the type is changed. |
| `service.dnsPort` | `53` | DNS TCP/UDP service port. |
| `resources.requests` | `cpu: 100m`, `memory: 128Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: 500m`, `memory: 350Mi` | Runtime resource cap. |
| `autoscaling.enabled` | `false` | Creates an HPA when enabled; off by default in favor of the fixed `replicaCount`. |
| `autoscaling.minReplicas` | `1` | Minimum HPA replica count. |
| `autoscaling.maxReplicas` | `5` | Maximum HPA replica count. |
| `autoscaling.targetCPUUtilizationPercentage` | `70` | CPU utilization target. |
| `podSecurityContext` | `{}` | Optional pod security context. |
| `securityContext` | drops all capabilities, adds `NET_BIND_SERVICE`, no privilege escalation | Allows binding port `53` without broader privileges. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |
| `blocky.config` | Literal Blocky YAML config | Configures blocklists, upstream resolvers, custom DNS, ports, and logging. |
| `netbird.enabled` | `true` | Enables NetBird resource rendering by default. |
| `netbird.bitwardenSecrets.netbirdApi.enabled` | `false` | Prevents workload chart from owning the shared NetBird API Secret. |
| `netbird.networkRouter.enabled` | `false` | Prevents workload chart from owning the shared NetBird router. |
| `netbird.networkRouter.name` | `k8s` | References the shared router name when NetBird is enabled. |
| `netbird.networkRouter.namespace` | `netbird` | References the shared router namespace. |
| `netbird.networkResources.enabled` | `true` | Allows this chart to render workload-specific NetBird resources when the subchart is enabled. |
| `netbird.networkResources.resources` | `blocky-dns` for group `All` | Exposes the Blocky Service through NetBird. |

## Notes

- The HPA is disabled by default; each Blocky pod keeps its own independent in-memory blocklist cache, so CPU-triggered scaling multiplies cold-start cost without a caching benefit. Enable `autoscaling.enabled=true` only with a deliberate reason, and note it requires metrics-server or another resource metrics provider.
- Remote blocklists require outbound HTTPS from the Blocky pod.
