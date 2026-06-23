# monitoring

Values for deploying Prometheus, Alertmanager, Grafana, kube-state-metrics, node-exporter, and the Prometheus Operator with the upstream `prometheus-community/kube-prometheus-stack` Helm chart.

This folder also includes values for `grafana/loki` and `grafana/alloy`. Alloy collects Kubernetes pod logs and events and sends them to Loki. Grafana is configured with a Loki datasource through `values.yaml`.

## What This Values File Configures

- Prometheus Operator CRDs and RBAC.
- Prometheus, Alertmanager, and Grafana enabled.
- kube-state-metrics and node-exporter enabled.
- Prometheus retention set to `15d`, capped at `18GiB`.
- Hetzner CSI-backed PVCs for Prometheus, Alertmanager, and Grafana.
- Grafana, Prometheus, and Alertmanager exposed only through `ClusterIP` Services by default.
- Grafana Loki datasource pointing at `loki-gateway.monitoring.svc.cluster.local`.
- Alertmanager routed to a Discord webhook stored in the `alertmanager-discord-webhook` Secret.
- k3s-unfriendly control-plane scrapes disabled by default: etcd, kube-controller-manager, kube-scheduler, and kube-proxy.
- CPU and memory requests/limits for the main monitoring workloads and helper containers.
- Loki single-binary mode with Hetzner CSI-backed storage and a `ClusterIP` gateway.
- Alloy as a DaemonSet collecting pod logs and Kubernetes events into Loki.

The upstream chart version checked while creating this file was `86.2.2`, with Prometheus Operator app version `v0.91.0`.
The upstream Loki chart version checked was `7.0.0`, and the upstream Alloy chart version checked was `1.9.0`.

## Dependencies

- Helm 3 and `kubectl`.
- Kubernetes `>=1.25`.
- Permissions to install CRDs, ClusterRoles, ClusterRoleBindings, ServiceMonitors, PrometheusRules, and StatefulSets.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.
- A Discord webhook URL for Alertmanager notifications.
- metrics-server is not required by this chart, but it is useful for broader cluster operations.

## Install

Add the official Prometheus community chart repository:

```fish
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Create the Discord webhook Secret before installing Alertmanager:

```fish
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

read --silent --prompt-str 'Discord webhook URL: ' DISCORD_WEBHOOK_URL
echo

kubectl -n monitoring create secret generic alertmanager-discord-webhook \
  --from-literal=webhook-url="$DISCORD_WEBHOOK_URL" \
  --dry-run=client -o yaml | kubectl apply -f -

set --erase DISCORD_WEBHOOK_URL
```

If you use Bitwarden Secrets Manager, edit `monitoring/alertmanager-discord-webhook-bitwardensecret.yaml` with your Bitwarden organization ID and Discord webhook Secret ID, then apply it instead:

```fish
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring get secret bw-auth-token
kubectl apply -f ./monitoring/alertmanager-discord-webhook-bitwardensecret.yaml
```

Review the rendered manifests:

```fish
helm template monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f ./monitoring/values.yaml

helm template loki grafana/loki \
  --namespace monitoring \
  -f ./monitoring/loki-values.yaml

helm template alloy grafana/alloy \
  --namespace monitoring \
  -f ./monitoring/alloy-values.yaml
```

Install or upgrade Prometheus, Alertmanager, and Grafana first:

```fish
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f ./monitoring/values.yaml \
  --wait
```

Install Loki, then Alloy:

```fish
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --create-namespace \
  -f ./monitoring/loki-values.yaml \
  --wait

helm upgrade --install alloy grafana/alloy \
  --namespace monitoring \
  --create-namespace \
  -f ./monitoring/alloy-values.yaml \
  --wait
```

## Verify

```fish
kubectl -n monitoring get pods,svc,pvc,servicemonitor
kubectl -n monitoring get prometheus,alertmanager
kubectl -n monitoring rollout status deployment/monitoring-kube-prometheus-operator --timeout=5m
kubectl -n monitoring rollout status deployment/monitoring-grafana --timeout=5m
kubectl -n monitoring rollout status deployment/monitoring-kube-state-metrics --timeout=5m
kubectl -n monitoring rollout status daemonset/monitoring-prometheus-node-exporter --timeout=5m
kubectl -n monitoring rollout status statefulset/loki --timeout=5m
kubectl -n monitoring rollout status deployment/loki-gateway --timeout=5m
kubectl -n monitoring rollout status daemonset/alloy --timeout=5m
```

Access Grafana with a port-forward:

```fish
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

Then open `http://localhost:3000`.

Get the generated Grafana admin password:

```fish
kubectl -n monitoring get secret monitoring-grafana \
  -o jsonpath='{.data.admin-password}' \
  | base64 --decode
echo
```

## Optional Grafana Ingress

The values include a prepared Grafana ingress host, but ingress is disabled by default. Enable it only after DNS points at Traefik:

```fish
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f ./monitoring/values.yaml \
  --set grafana.ingress.enabled=true \
  --wait
```

Default ingress host:

```text
grafana.jeiang.dev
```

## Values To Review

```yaml
grafana:
  persistence:
    storageClassName: hcloud-volumes
    size: 5Gi

alertmanager:
  alertmanagerSpec:
    retention: 120h
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: hcloud-volumes

prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: 18GiB
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: hcloud-volumes
```

Loki and Alloy defaults to review:

```yaml
singleBinary:
  persistence:
    storageClass: hcloud-volumes
    size: 15Gi

# monitoring/alloy-values.yaml
loki.write "loki" {
  endpoint {
    url = "http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"
  }
}
```

If your cluster exposes kube-controller-manager, kube-scheduler, kube-proxy, or etcd metrics in a scrapeable way, re-enable those sections in `values.yaml`.

## References

- Artifact Hub package: https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
- Chart source: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- Upstream kube-prometheus project: https://github.com/prometheus-operator/kube-prometheus
- Loki Helm chart: https://grafana.com/docs/loki/latest/setup/install/helm/
- Alloy Helm chart: https://grafana.com/docs/alloy/latest/set-up/install/kubernetes/
