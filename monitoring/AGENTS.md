# Chart Guidelines

## Scope

This directory contains values and support manifests for the upstream `victoria-metrics-k8s-stack` Helm chart. It does not own the upstream stack templates.

## Runtime Contract

- The chart is installed as release `monitoring` into the `monitoring` namespace.
- Grafana is public at `grafana.jeiang.dev` through Traefik and cert-manager.
- Grafana authenticates through Pocket ID using the OIDC client ID `a70e6d0d-360c-415f-b154-85ec7a6bc352`.
- Grafana OAuth roles come from Pocket ID groups: `monitoring_admin`, `monitoring_editor`, and `monitoring_reader`.
- The `grafana-oauth` Secret is expected to be synced by Bitwarden Secrets Manager from `grafana-oauth-bitwardensecret.yaml`.
- The CrowdSec dashboard is loaded by Grafana's dashboard sidecar from `crowdsec-dashboard-configmap.yaml`.
- VictoriaMetrics and VictoriaLogs raw HTTP endpoints must not be exposed through public ingress; they are reachable privately over NetBird instead, via `vmsingle-networkresource.yaml` and `vlsingle-networkresource.yaml`.
- VMSingle, VLSingle, and Grafana use the RWO-only `hcloud-volumes` StorageClass.
- Grafana must keep `grafana.deploymentStrategy.type: Recreate` and `grafana.deploymentStrategy.rollingUpdate: null`; rolling updates can leave replacement pods stuck on multi-attach errors with Hetzner RWO volumes.
- Alertmanager routes all alerts to a single Discord receiver via `discord_configs`; the webhook URL is synced by Bitwarden Secrets Manager into the `alertmanager-discord` Secret from `alertmanager-discord-bitwardensecret.yaml`, mounted at `/etc/vm/secrets/alertmanager-discord/webhookUrl` via `alertmanager.spec.secrets`, and referenced with `webhook_url_file` (never `webhook_url`) so the URL never appears in `values.yaml` or the rendered chart.
- `kubeScheduler`, `kubeControllerManager`, and `kubeEtcd` scraping/alerting is deliberately disabled (`enabled: false` plus the matching `defaultRules.groups` entries). k3s runs these components embedded on loopback-only ports with no matching pods, so the chart's default Services/`VMServiceScrape`s have zero endpoints and `KubeSchedulerDown`/`KubeControllerManagerDown`/`ScrapePoolHasNoTargets`/`RecordingRulesNoData` fire permanently rather than reflecting a real problem. This chart's `VMRule`/dashboard sync resources are created at runtime by a `sync-job` Deployment reading a ConfigMap, not by static Helm templates — `helm template` alone won't show them; use `--api-versions "operator.victoriametrics.com/v1beta1/VMServiceScrape"` to force CRD-gated resources to render, and inspect the `*-sync-job-config` ConfigMap's `rules.groups`/`dashboards.dashboards` keys to confirm a rule/dashboard toggle actually took effect.

## Editing Notes

- Do not commit the Grafana OAuth client secret.
- Do not commit the Discord webhook URL; always reference it via `webhook_url_file` against the mounted `alertmanager-discord` Secret.
- Keep the Grafana OAuth callback aligned with Pocket ID: `https://grafana.jeiang.dev/login/generic_oauth`.
- Keep `vmsingle.ingress`, `vlsingle.ingress`, and `vlagent.ingress` disabled unless an explicit access-control design is added.
- If `vmsingle`/`vlsingle` Service names ever change (e.g. a release rename), update `serviceRef.name` in both `vmsingle-networkresource.yaml` and `vlsingle-networkresource.yaml` to match.
- If the Discord webhook is ever rotated, only the Bitwarden secret item needs to change; `alertmanager-discord-bitwardensecret.yaml` and `values.yaml` do not need edits.
- Do not re-enable `kubeScheduler`/`kubeControllerManager`/`kubeEtcd` without also fixing the underlying k3s exposure first: add `--kube-scheduler-arg=bind-address=0.0.0.0`, `--kube-controller-manager-arg=bind-address=0.0.0.0`, and `--etcd-expose-metrics=true` to the k3s server flags (outside this repo), then set `kubeScheduler.endpoints`/`kubeControllerManager.endpoints`/`kubeEtcd.endpoints` to the control-plane node's internal IP (the chart's built-in "component is not deployed as a pod" mechanism) and `kubeEtcd.service.port`/`targetPort: 2381` (k3s's dedicated etcd metrics port, not the chart's default `2379` client port). Re-enabling without those steps just brings the noisy alerts back.

## Validation

```sh
helm template monitoring vm/victoria-metrics-k8s-stack \
  --namespace monitoring \
  --api-versions "operator.victoriametrics.com/v1beta1/VMServiceScrape" \
  -f ./monitoring/values.yaml

kubectl apply --dry-run=client -f ./monitoring/grafana-oauth-bitwardensecret.yaml
kubectl apply --dry-run=client -f ./monitoring/crowdsec-dashboard-configmap.yaml
kubectl apply --dry-run=client -f ./monitoring/vmsingle-networkresource.yaml
kubectl apply --dry-run=client -f ./monitoring/vlsingle-networkresource.yaml
kubectl apply --dry-run=client -f ./monitoring/alertmanager-discord-bitwardensecret.yaml
```
