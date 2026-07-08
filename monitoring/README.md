# monitoring

Values and support manifests for deploying the upstream `vm/victoria-metrics-k8s-stack` Helm chart.

## Contents

- [What This Directory Configures](#what-this-directory-configures)
- [Dependencies](#dependencies)
- [Pocket ID Authentication](#pocket-id-authentication)
- [Bitwarden Secret](#bitwarden-secret)
- [Alerting](#alerting)
- [CrowdSec Dashboard](#crowdsec-dashboard)
- [Install](#install)
- [Verify](#verify)
- [NetBird Exposure](#netbird-exposure)
- [Values](#values)
- [References](#references)

## What This Directory Configures

- VictoriaMetrics single-node storage with a `20Gi` `hcloud-volumes` PVC and one month retention.
- VictoriaLogs single-node storage with a `20Gi` `hcloud-volumes` PVC and one month retention.
- VLAgent Kubernetes log collection.
- Bundled Grafana with VictoriaMetrics and VictoriaLogs datasources and dashboards.
- A CrowdSec Grafana dashboard loaded from a sidecar-discovered ConfigMap.
- A `5Gi` `hcloud-volumes` PVC and explicit resources for Grafana.
- Public Grafana ingress at `https://grafana.jeiang.dev` through Traefik and cert-manager.
- Pocket ID generic OAuth for Grafana.
- A `BitwardenSecret` manifest that syncs the Grafana OAuth client secret.
- NetBird `NetworkResource` objects that expose the raw VictoriaMetrics and VictoriaLogs endpoints privately (see [NetBird Exposure](#netbird-exposure)).
- Alertmanager routed to a Discord webhook, synced from Bitwarden (see [Alerting](#alerting)).

The raw VictoriaMetrics and VictoriaLogs HTTP endpoints are not exposed publicly.

## Dependencies

- Helm 3 and `kubectl`.
- Traefik installed with an IngressClass named `traefik`.
- cert-manager installed with a `letsencrypt-prod` `ClusterIssuer`.
- DNS for `grafana.jeiang.dev` pointing at the Traefik load balancer.
- Hetzner CSI `hcloud-volumes` StorageClass.
- Bitwarden Secrets Manager operator installed.
- A Bitwarden machine-account token Secret named `bw-auth-token` in the `monitoring` namespace.
- Network egress from Grafana to `auth.jeiang.dev` and from Grafana to the Grafana plugin catalog.
- CrowdSec metrics scraped into VictoriaMetrics for the CrowdSec dashboard to show data.

## Pocket ID Authentication

Grafana uses Pocket ID through generic OAuth.

Create or verify a confidential Pocket ID OIDC client with:

- Client ID: `a70e6d0d-360c-415f-b154-85ec7a6bc352`
- Redirect URI: `https://grafana.jeiang.dev/login/generic_oauth`
- Scopes: `openid profile email groups`

Pocket ID groups map to Grafana roles:

| Pocket ID group | Grafana role |
| --- | --- |
| `monitoring_admin` | `Admin` |
| `monitoring_editor` | `Editor` |
| `monitoring_reader` | `Viewer` |

Grafana uses strict role mapping. A user without one of these groups should be denied.

## Bitwarden Secret

Store the Grafana OAuth client secret in Bitwarden Secrets Manager. Update `grafana-oauth-bitwardensecret.yaml` so `spec.map[0].bwSecretId` points at that Bitwarden secret item.

The synced Kubernetes Secret must be named `grafana-oauth` and contain:

```yaml
GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET: <client-secret>
```

Store the Alertmanager Discord webhook URL in Bitwarden Secrets Manager. Update `alertmanager-discord-bitwardensecret.yaml` so `spec.map[0].bwSecretId` points at that Bitwarden secret item.

The synced Kubernetes Secret must be named `alertmanager-discord` and contain:

```yaml
webhookUrl: <discord-webhook-url>
```

Create the namespace and Bitwarden auth token Secret:

```fish
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

read --silent --prompt-str 'Bitwarden machine account token: ' BW_AUTH_TOKEN
echo

kubectl -n monitoring create secret generic bw-auth-token \
  --from-literal=token="$BW_AUTH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

set --erase BW_AUTH_TOKEN
```

Sync the Grafana OAuth secret and Alertmanager Discord webhook:

```fish
kubectl apply -f ./monitoring/grafana-oauth-bitwardensecret.yaml
kubectl -n monitoring get bitwardensecret grafana-oauth
kubectl -n monitoring get secret grafana-oauth

kubectl apply -f ./monitoring/alertmanager-discord-bitwardensecret.yaml
kubectl -n monitoring get bitwardensecret alertmanager-discord
kubectl -n monitoring get secret alertmanager-discord
```

## Alerting

Alertmanager routes all alerts (the chart's `defaultRules` plus anything from `vmalert`) to a single Discord receiver via `discord_configs`. The webhook URL is never written to `values.yaml`; it is synced from Bitwarden into the `alertmanager-discord` Secret (see [Bitwarden Secret](#bitwarden-secret)), mounted into the Alertmanager pod at `/etc/vm/secrets/alertmanager-discord/webhookUrl` via `alertmanager.spec.secrets`, and referenced by `alertmanager.config.receivers[0].discord_configs[0].webhook_url_file`.

Current routing is a single catch-all: `group_by: ["alertgroup", "job"]`, `group_wait: 30s`, `group_interval: 5m`, `repeat_interval: 12h`. Add more specific routes under `alertmanager.config.route.routes` if some alerts need a different receiver or cadence later.

## CrowdSec Dashboard

Apply the dashboard ConfigMap after Grafana is installed:

```fish
kubectl apply -f ./monitoring/crowdsec-dashboard-configmap.yaml
```

The dashboard uses the existing `VictoriaMetrics` datasource and documented CrowdSec metric names such as `cs_info`, `cs_active_decisions`, `cs_lapi_*`, and `cs_appsec_*`. Panels will be empty until `crowdsec/crowdsec-vmservicescrape.yaml` is active and CrowdSec has emitted matching metrics.

## Install

Add the VictoriaMetrics chart repository:

```fish
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update
```

Review the rendered manifests:

```fish
helm template monitoring vm/victoria-metrics-k8s-stack \
  --namespace monitoring \
  -f ./monitoring/values.yaml
```

Install or upgrade:

```fish
helm upgrade --install monitoring vm/victoria-metrics-k8s-stack \
  --namespace monitoring \
  --create-namespace \
  -f ./monitoring/values.yaml \
  --wait
```

## Verify

Check workloads, storage, and ingress:

```fish
kubectl -n monitoring get pods,pvc,ingress
kubectl -n monitoring rollout status deploy/monitoring-grafana
kubectl -n monitoring get configmap crowdsec-dashboard
```

Confirm that Grafana is reachable at `https://grafana.jeiang.dev` and redirects to Pocket ID. Test users in `monitoring_admin`, `monitoring_editor`, and `monitoring_reader` should receive the matching Grafana role. A user without those groups should be denied.
Open the `CrowdSec` dashboard and confirm panels populate after CrowdSec metrics are scraped.

Confirm Alertmanager loaded the Discord receiver and can reach the webhook mount:

```fish
kubectl -n monitoring get secret alertmanager-discord
kubectl -n monitoring exec vmalertmanager-monitoring-victoria-metrics-k8s-stack-0 -- cat /etc/vm/secrets/alertmanager-discord/webhookUrl | head -c0 && echo mounted
kubectl -n monitoring logs vmalertmanager-monitoring-victoria-metrics-k8s-stack-0 -c alertmanager --tail=50
```

Trigger a test alert to confirm delivery end-to-end (safe to run any time; `TestAlert` is not a real alertname):

```fish
kubectl -n monitoring exec vmalertmanager-monitoring-victoria-metrics-k8s-stack-0 -- wget -q -O- --post-data='[{"labels":{"alertname":"TestAlert","severity":"info"}}]' --header='Content-Type: application/json' http://localhost:9093/api/v2/alerts
```

A message should appear in the configured Discord channel within a few seconds.

Inspect the rendered chart before deployment for:

- Grafana ingress host, TLS secret, and cert-manager annotation.
- VMSingle and VLSingle storage class, size, access mode, and retention.
- No public ingress for VictoriaMetrics, VictoriaLogs, or VLAgent.
- Grafana OAuth secret reference.
- Generated VictoriaMetrics and VictoriaLogs datasources.
- CrowdSec dashboard ConfigMap label `grafana_dashboard: "1"`.
- Grafana Deployment strategy `Recreate`, so the RWO Hetzner volume is detached before the replacement pod starts.

If Grafana resets the connection after returning from Pocket ID, check for OOM kills first:

```fish
kubectl -n monitoring describe pod -l app.kubernetes.io/name=grafana
kubectl -n monitoring logs deploy/monitoring-grafana -c grafana --previous --tail=120
```

The Grafana values intentionally set memory requests/limits and persistence so startup, plugin loading, and first-login database work do not run as a BestEffort emptyDir workload.

## NetBird Exposure

VictoriaMetrics and VictoriaLogs raw HTTP endpoints are exposed privately over NetBird instead of public ingress, via `vmsingle-networkresource.yaml` and `vlsingle-networkresource.yaml`. Apply them after the shared NetBird router and operator resources exist (see `../netbird-resources/`):

```fish
kubectl apply -f ./monitoring/vmsingle-networkresource.yaml
kubectl apply -f ./monitoring/vlsingle-networkresource.yaml
```

They reference:

- `vmsingle-monitoring-victoria-metrics-k8s-stack` in namespace `monitoring` on port `8428`.
- `vlsingle-monitoring-victoria-metrics-k8s-stack` in namespace `monitoring` on port `9428`.

Both `NetworkResource` objects currently scope access to the `All` NetBird group, matching the existing `blocky-dns` convention; narrow the group if a more restrictive one exists for this organization.

## Values

See [`VALUES.md`](./VALUES.md) for local values documented with defaults and operational notes.

## References

- VictoriaMetrics stack chart: https://docs.victoriametrics.com/helm/victoria-metrics-k8s-stack/
- VictoriaMetrics: https://docs.victoriametrics.com/victoriametrics/
- VictoriaLogs: https://docs.victoriametrics.com/victorialogs/
