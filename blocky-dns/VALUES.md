# blocky-dns Values

These values configure the local Blocky DNS Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `1` | Starts one Blocky pod before HPA scaling. |
| `image.repository` | `ghcr.io/0xerr0r/blocky` | Blocky image repository. |
| `image.tag` | `v0.28.2` | Blocky image tag. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `service.type` | `ClusterIP` | Keeps DNS service internal. |
| `service.annotations` | `{}` | Optional Service annotations. |
| `service.externalTrafficPolicy` | `Cluster` | Service traffic policy if the type is changed. |
| `service.dnsPort` | `53` | DNS TCP/UDP service port. |
| `resources.requests` | `cpu: 50m`, `memory: 64Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: 250m`, `memory: 192Mi` | Runtime resource cap. |
| `autoscaling.enabled` | `true` | Creates an HPA. |
| `autoscaling.minReplicas` | `1` | Minimum HPA replica count. |
| `autoscaling.maxReplicas` | `5` | Maximum HPA replica count. |
| `autoscaling.targetCPUUtilizationPercentage` | `70` | CPU utilization target. |
| `podSecurityContext` | `{}` | Optional pod security context. |
| `securityContext` | drops all capabilities, adds `NET_BIND_SERVICE`, no privilege escalation | Allows binding port `53` without broader privileges. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |
| `blocky.config` | Literal Blocky YAML config | Configures blocklists, upstream resolvers, custom DNS, ports, and logging. |
| `netbird.enabled` | `false` | Disables optional NetBird resource rendering by default. |
| `netbird.bitwardenSecrets.netbirdApi.enabled` | `false` | Prevents workload chart from owning the shared NetBird API Secret. |
| `netbird.networkRouter.enabled` | `false` | Prevents workload chart from owning the shared NetBird router. |
| `netbird.networkRouter.name` | `k8s` | References the shared router name when NetBird is enabled. |
| `netbird.networkRouter.namespace` | `netbird` | References the shared router namespace. |
| `netbird.networkResources.enabled` | `true` | Allows this chart to render workload-specific NetBird resources when the subchart is enabled. |
| `netbird.networkResources.resources` | `blocky-dns` for group `All` | Exposes the Blocky Service through NetBird. |

## Notes

- The HPA requires metrics-server or another resource metrics provider.
- Remote blocklists require outbound HTTPS from the Blocky pod.
