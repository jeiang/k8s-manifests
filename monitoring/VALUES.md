# monitoring Values

These values override the upstream `vm/victoria-metrics-k8s-stack` chart for this cluster.

| Value | Default | Purpose |
| --- | --- | --- |
| `global.cluster.dnsDomain` | `cluster.local.` | Cluster DNS suffix used by generated datasource URLs. |
| `vmsingle.enabled` | `true` | Enables single-node VictoriaMetrics storage. |
| `vmsingle.spec.retentionPeriod` | `"1"` | Keeps metrics for one month. |
| `vmsingle.spec.storage.storageClassName` | `hcloud-volumes` | Uses Hetzner CSI RWO storage. |
| `vmsingle.spec.storage.resources.requests.storage` | `20Gi` | Initial metrics volume size. |
| `vmsingle.ingress.enabled` | `false` | Keeps the raw metrics endpoint off public ingress. |
| `vlsingle.enabled` | `true` | Enables single-node VictoriaLogs storage. |
| `vlsingle.spec.retentionPeriod` | `"1"` | Keeps logs for one month. |
| `vlsingle.spec.storage.storageClassName` | `hcloud-volumes` | Uses Hetzner CSI RWO storage. |
| `vlsingle.spec.storage.resources.requests.storage` | `20Gi` | Initial logs volume size. |
| `vlsingle.ingress.enabled` | `false` | Keeps the raw logs endpoint off public ingress. |
| `vlagent.enabled` | `true` | Enables Kubernetes log collection into VictoriaLogs. |
| `vlagent.spec.k8sCollector.enabled` | `true` | Collects Kubernetes container logs. |
| `vlagent.ingress.enabled` | `false` | Keeps the log agent endpoint off public ingress. |
| `grafana.enabled` | `true` | Deploys bundled Grafana. |
| `grafana.deploymentStrategy.type` | `Recreate` | Avoids rolling-update multi-attach conflicts with the RWO Hetzner volume. |
| `grafana.resources` | `100m/768Mi` request, `1 CPU/2Gi` limit | Avoids BestEffort eviction/OOM during startup, plugin loading, and first login. |
| `grafana.persistence` | `5Gi` `hcloud-volumes` RWO PVC | Persists Grafana state, plugins, sessions, and the SQLite database across restarts. |
| `grafana.plugins` | VictoriaMetrics metrics and logs datasource plugins | Installs plugins needed by the default datasource definitions. |
| `grafana.envFromSecret` | `grafana-oauth` | Reads the OAuth client secret from the Bitwarden-synced Secret. |
| `crowdsec-dashboard-configmap.yaml` | `grafana_dashboard=1` ConfigMap | Loads the CrowdSec dashboard through Grafana's dashboard sidecar. |
| `grafana.grafana.ini.server.root_url` | `https://grafana.jeiang.dev` | Public Grafana URL and OAuth callback base. |
| `grafana.grafana.ini.auth.generic_oauth.client_id` | `a70e6d0d-360c-415f-b154-85ec7a6bc352` | Pocket ID Grafana OIDC client ID. |
| `grafana.grafana.ini.auth.generic_oauth.role_attribute_strict` | `true` | Denies users without an explicit monitoring role group. |
| `grafana.ingress.enabled` | `true` | Exposes Grafana publicly. |
| `grafana.ingress.ingressClassName` | `traefik` | Uses the Traefik IngressClass. |
| `grafana.ingress.annotations` | `cert-manager.io/cluster-issuer: letsencrypt-prod` | Requests TLS through cert-manager. |
| `grafana.ingress.hosts` | `grafana.jeiang.dev` | Public Grafana hostname. |
| `grafana.ingress.tls` | `grafana-tls` for `grafana.jeiang.dev` | TLS secret created by cert-manager. |

## Notes

- The Grafana OAuth client secret must not be placed in `values.yaml`. It should be synced to `grafana-oauth` with key `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET`.
- Grafana uses `Recreate` because `hcloud-volumes` is RWO block storage; rolling updates can leave a replacement pod waiting on a multi-attach error until the old pod releases the volume.
- The raw VictoriaMetrics and VictoriaLogs HTTP endpoints are intentionally internal for now. A later change should expose them through NetBird resources, not public ingress.
- If metrics or logs grow beyond the small RWO profile, revisit retention and storage before increasing write volume.
