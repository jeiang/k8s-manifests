# traefik

k3s `HelmChartConfig` for the bundled Traefik chart.

## What This Directory Configures

- A k3s-managed `HelmChartConfig` named `traefik` in `kube-system`.
- Hetzner Load Balancer annotations for the bundled Traefik Service.
- TCP protocol and health check settings for the load balancer.

## Dependencies

- k3s bundled Traefik enabled.
- Hetzner Cloud Controller Manager installed and managing `LoadBalancer` Services.
- Hetzner Load Balancer name `legion-lb1` in the `us-east` network zone.

## Apply

```sh
kubectl apply -f ./traefik/traefik-helmchartconfig.yaml
```

The config names the Hetzner Load Balancer `legion-lb1` and places it in the `us-east` network zone.

## Verify

```sh
kubectl -n kube-system rollout status deployment/traefik --timeout=5m
kubectl -n kube-system get svc traefik
```
