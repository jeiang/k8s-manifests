# crowdsec

Values and support manifests for deploying the upstream `crowdsec/crowdsec` Helm chart.

## What This Directory Configures

- CrowdSec LAPI in the `crowdsec` namespace.
- CrowdSec Agent log acquisition for k3s bundled Traefik pods in `kube-system`.
- CrowdSec AppSec/WAF on the internal AppSec service.
- Prometheus metrics on internal port `6060` for LAPI, Agent, and AppSec.
- A `VMServiceScrape` for VictoriaMetrics.
- A `BitwardenSecret` manifest that syncs Traefik's dynamic CrowdSec middleware config.

## Dependencies

- Helm 3 and `kubectl`.
- Upstream CrowdSec Helm repository: `https://crowdsecurity.github.io/helm-charts`.
- k3s using containerd.
- k3s bundled Traefik configured by `../traefik/traefik-helmchartconfig.yaml`.
- VictoriaMetrics operator CRDs from the `monitoring` stack for `VMServiceScrape`.
- Hetzner CSI `hcloud-volumes` StorageClass.
- Bitwarden Secrets Manager operator installed.
- A `bw-auth-token` Secret in `kube-system` for syncing the Traefik dynamic config Secret.

## Install CrowdSec

Add the upstream chart repository:

```fish
helm repo add crowdsec https://crowdsecurity.github.io/helm-charts
helm repo update
```

Render the chart:

```fish
helm template crowdsec crowdsec/crowdsec \
  --namespace crowdsec \
  -f ./crowdsec/values.yaml
```

Install or upgrade:

```fish
helm upgrade --install crowdsec crowdsec/crowdsec \
  --namespace crowdsec \
  --create-namespace \
  -f ./crowdsec/values.yaml \
  --wait
```

Apply the VictoriaMetrics scrape manifest after CrowdSec services exist:

```fish
kubectl apply -f ./crowdsec/crowdsec-vmservicescrape.yaml
```

## Bouncer Keys

Generate separate bouncer keys for NetBird and Traefik:

```fish
kubectl -n crowdsec exec deploy/crowdsec-lapi -- \
  cscli bouncers add netbird-proxy -o raw

kubectl -n crowdsec exec deploy/crowdsec-lapi -- \
  cscli bouncers add traefik-waf -o raw
```

Each command prints the key once. Store the NetBird key in Bitwarden Secrets Manager and set `netbird/values.yaml` `bitwardenSecrets.secretIds.crowdsecBouncerKey` to that Bitwarden secret ID before enabling `proxy.crowdsec.enabled`.

Store the Traefik key in Bitwarden as a full dynamic config file value named `crowdsec-dynamic.yaml`:

```yaml
http:
  middlewares:
    crowdsec-bouncer:
      plugin:
        crowdsec-bouncer:
          enabled: true
          crowdsecMode: appsec
          crowdsecAppsecEnabled: true
          crowdsecAppsecScheme: http
          crowdsecAppsecHost: crowdsec-appsec-service.crowdsec.svc.cluster.local:7422
          crowdsecAppsecFailureBlock: true
          crowdsecAppsecUnreachableBlock: true
          crowdsecLapiScheme: http
          crowdsecLapiHost: crowdsec-service.crowdsec.svc.cluster.local:8080
          crowdsecLapiKey: replace-with-traefik-bouncer-key
          forwardedHeadersTrustedIPs:
            - 10.0.0.0/8
```

Update `traefik-crowdsec-dynamic-bitwardensecret.yaml` with the Bitwarden secret ID, then sync it:

```fish
kubectl apply -f ./crowdsec/traefik-crowdsec-dynamic-bitwardensecret.yaml
kubectl -n kube-system get secret traefik-crowdsec-dynamic
```

Apply the Traefik `HelmChartConfig` only after this Secret exists; the Traefik pod mounts it at startup.

## Verify

```fish
kubectl -n crowdsec get pods,svc,pvc
kubectl -n crowdsec exec deploy/crowdsec-lapi -- cscli lapi status
kubectl -n kube-system rollout status deployment/traefik --timeout=5m
```

Confirm metrics are scraped:

```fish
kubectl -n monitoring port-forward svc/vmsingle-monitoring-victoria-metrics-k8s-stack 8428:8428
```

Then query for `cs_info`, `cs_lapi_*`, and `cs_appsec_*` in Grafana or VictoriaMetrics.

## References

- CrowdSec Helm chart: https://github.com/crowdsecurity/helm-charts/tree/main/charts/crowdsec
- CrowdSec Prometheus metrics: https://docs.crowdsec.net/docs/observability/prometheus/
- CrowdSec AppSec/WAF: https://docs.crowdsec.net/docs/appsec/intro/
- NetBird CrowdSec integration: https://docs.netbird.io/selfhosted/maintenance/crowdsec
