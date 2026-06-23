# traefik

k3s `HelmChartConfig` for the bundled Traefik chart.

## Apply

```sh
kubectl apply -f ./traefik/traefik-helmchartconfig.yaml
kubectl -n kube-system rollout status deployment/traefik --timeout=5m
kubectl -n kube-system get svc traefik
```

The config names the Hetzner Load Balancer `legion-lb1` and places it in the `us-east` network zone.
