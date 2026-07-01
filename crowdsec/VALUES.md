# crowdsec Values

These values override the upstream `crowdsec/crowdsec` chart for this cluster.

| Value | Default | Purpose |
| --- | --- | --- |
| `container_runtime` | `containerd` | Matches k3s log format. |
| `config.config.yaml.local.api.server.auto_registration.allowed_ranges` | loopback, private ranges, and `10.42.0.0/16` | Allows in-cluster agents and AppSec pods to register with LAPI. |
| `config.config.yaml.local.prometheus.enabled` | `true` | Enables CrowdSec Prometheus metrics. |
| `config.config.yaml.local.prometheus.level` | `full` | Exposes full LAPI, parser, acquisition, and AppSec metric families. |
| `config.config.yaml.local.prometheus.listen_addr` | `0.0.0.0` | Allows in-cluster scraping. |
| `config.config.yaml.local.prometheus.listen_port` | `6060` | Metrics port exposed by chart services. |
| `lapi.enabled` | `true` | Runs the CrowdSec Local API. |
| `lapi.replicas` | `1` | Uses one LAPI replica with local persistent state. |
| `lapi.persistentVolume.data.storageClassName` | `hcloud-volumes` | Stores LAPI database and bouncer state on Hetzner RWO storage. |
| `lapi.persistentVolume.data.size` | `1Gi` | Initial LAPI data volume size. |
| `lapi.persistentVolume.config.storageClassName` | `hcloud-volumes` | Stores LAPI config state on Hetzner RWO storage. |
| `lapi.persistentVolume.config.size` | `100Mi` | Initial LAPI config volume size. |
| `lapi.service.type` | `ClusterIP` | Keeps LAPI internal. |
| `lapi.service.labels.victoria-metrics-scrape` | `crowdsec` | Selects the service for `VMServiceScrape`. |
| `lapi.metrics.enabled` | `true` | Exposes LAPI metrics service port. |
| `agent.enabled` | `true` | Runs CrowdSec log acquisition agents. |
| `agent.acquisition` | `kube-system` `traefik-*` as `traefik` | Reads k3s bundled Traefik access logs. |
| `agent.env.COLLECTIONS` | `crowdsecurity/traefik` | Installs Traefik parsing/scenario collection. |
| `agent.service.labels.victoria-metrics-scrape` | `crowdsec` | Selects the agent metrics service for `VMServiceScrape`. |
| `appsec.enabled` | `true` | Runs CrowdSec AppSec/WAF. |
| `appsec.acquisitions` | AppSec listener on `0.0.0.0:7422` | Provides the WAF endpoint used by Traefik. |
| `appsec.configs.crs-vpatch.yaml` | CRS plus virtual patching config | Enables request inspection with default ban remediation. |
| `appsec.env.COLLECTIONS` | `crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-crs` | Installs AppSec WAF collections. |
| `appsec.service.type` | `ClusterIP` | Keeps AppSec internal. |
| `appsec.service.labels.victoria-metrics-scrape` | `crowdsec` | Selects the service for `VMServiceScrape`. |
| `appsec.metrics.enabled` | `true` | Exposes AppSec metrics service port. |

## Notes

- LAPI and AppSec endpoints are intentionally not exposed through public ingress.
- Bouncer keys must be generated with `cscli bouncers add` after LAPI is running and then stored in Bitwarden Secrets Manager.
- The Traefik dynamic config Secret must exist before applying the Traefik `HelmChartConfig` that mounts it.
