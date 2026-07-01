# bitwarden-sm-operator Values

These values override the upstream `bitwarden/sm-operator` chart for this cluster.

| Value | Default | Purpose |
| --- | --- | --- |
| `settings.bwSecretsManagerRefreshInterval` | `300` | Sync interval in seconds; Bitwarden requires at least `180`. |
| `settings.cloudRegion` | `US` | Uses Bitwarden Cloud US. |
| `settings.bwApiUrlOverride` | `https://vault.bitwarden.com/api` | Bitwarden API URL override. |
| `settings.bwIdentityUrlOverride` | `https://vault.bitwarden.com/identity` | Bitwarden identity URL override. |
| `settings.kubernetesClusterDomain` | `cluster.local` | Kubernetes DNS cluster domain. |
| `settings.replicas` | `1` | Runs one operator replica. |
| `commonLabels` | `{}` | Optional labels applied by the upstream chart. |
| `containers.manager.enableLeaderElection` | `true` | Enables leader election for the manager. |
| `containers.manager.image.repository` | `ghcr.io/bitwarden/sm-operator` | Operator image repository. |
| `containers.manager.image.tag` | `""` | Uses the upstream chart default image tag. |
| `containers.manager.resources.requests` | `cpu: 10m`, `memory: 64Mi` | Baseline scheduling request for the manager. |
| `containers.manager.resources.limits` | `cpu: 100m`, `memory: 128Mi` | Runtime resource cap for the manager. |
| `containers.manager.terminationGracePeriodSeconds` | `10` | Grace period for manager shutdown. |
| `containers.serviceAccount.annotations` | `{}` | Optional service account annotations. |
| `containers.enableSeccompProfileRuntimeDefault` | `true` | Enables the runtime default seccomp profile. |
| `containers.imagePullSecrets` | `""` | Optional image pull secret reference. |
| `containers.nodeSelector` | `{}` | Optional node placement constraints. |
| `containers.tolerations` | `[]` | Optional taint tolerations. |
| `revisionHistoryLimit` | `""` | Uses the upstream chart default revision history. |
| `metricsService.type` | `ClusterIP` | Keeps metrics service internal. |
| `metricsService.ports` | `https:8443 -> https` | Exposes operator metrics over HTTPS. |
| `livenessProbe` | initial delay `15s`, period `20s`, timeout `1s`, failure threshold `3` | Liveness probe timings. |
| `readinessProbe` | initial delay `5s`, period `10s`, timeout `1s`, failure threshold `3` | Readiness probe timings. |

## Notes

- For self-hosted Bitwarden, set `settings.cloudRegion` to an empty value and point both URL overrides at the self-hosted API and identity endpoints.
- Machine account tokens are not values here; create namespace-local `bw-auth-token` Secrets outside this repository.
