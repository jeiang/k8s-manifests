# traefik

k3s `HelmChartConfig` for the bundled Traefik chart.

## What This Directory Configures

- A k3s-managed `HelmChartConfig` named `traefik` in `kube-system`.
- Hetzner Load Balancer annotations for the bundled Traefik Service.
- TCP protocol and health check settings for the load balancer.
- CrowdSec Traefik plugin static configuration.
- Global CrowdSec WAF middleware attachment for the `web` and `websecure` entryPoints.
- A Secret-backed file-provider dynamic config mount at `/config/crowdsec-dynamic.yaml`.

## Dependencies

- k3s bundled Traefik enabled.
- Hetzner Cloud Controller Manager installed and managing `LoadBalancer` Services.
- Hetzner Load Balancer name `legion-lb1` in the `us-east` network zone.
- CrowdSec LAPI and AppSec services installed in the `crowdsec` namespace.
- A `kube-system/traefik-crowdsec-dynamic` Secret containing the `crowdsec-dynamic.yaml` key.
- Bitwarden Secrets Manager operator installed if syncing the dynamic config from `../crowdsec/traefik-crowdsec-dynamic-bitwardensecret.yaml`.

## Apply

```sh
kubectl -n kube-system get secret traefik-crowdsec-dynamic
kubectl apply -f ./traefik/traefik-helmchartconfig.yaml
```

The config names the Hetzner Load Balancer `legion-lb1` and places it in the `us-east` network zone. It also mounts the CrowdSec dynamic config Secret; apply the Bitwarden sync manifest in `../crowdsec/` before applying this file.

## Verify

```sh
kubectl -n kube-system rollout status deployment/traefik --timeout=5m
kubectl -n kube-system get svc traefik
kubectl -n kube-system logs deploy/traefik --tail=100 | grep -i crowdsec
```
