# blocky-dns

Helm chart for running Blocky as an internal DNS service.

Default application version: `v0.28.2`.

## What This Chart Creates

- A Blocky Deployment with 2 fixed replicas for availability across node reboots/maintenance.
- An optional `HorizontalPodAutoscaler` (disabled by default; `autoscaling.enabled=true` scales 1-5 pods on CPU).
- A `ClusterIP` Service exposing DNS on port `53` for UDP and TCP inside the cluster.
- A ConfigMap-mounted Blocky `config.yml`.
- DNS blocklists from StevenBlack and Hagezi.
- Default upstreams for Cloudflare, Google, and Quad9.
- A NetBird `NetworkResource` for the Blocky Service, enabled by default (`netbird.enabled=true`).
- Resource limits of `500m` CPU and `350Mi` memory.

## Dependencies

- Helm 3 and `kubectl`.
- metrics-server or another Kubernetes resource metrics provider, only if `autoscaling.enabled=true`.
- Outbound HTTPS access so Blocky can download remote blocklists.
- Outbound DNS access to the configured upstream resolvers.
- NetBird operator CRDs and the shared `NetworkRouter/k8s` in the `netbird` namespace, since NetBird integration is enabled by default.

## Install

The shared NetBird router and operator resources must exist before installing, since NetBird integration is on by default:

```fish
helm dependency build ./blocky-dns

helm lint ./blocky-dns
helm template blocky-dns ./blocky-dns --namespace dns
helm upgrade --install blocky-dns ./blocky-dns \
  --namespace dns \
  --create-namespace
```

With the default values, that creates a `NetworkResource` named `blocky-dns` in the `dns` namespace for `blocky-dns.dns.k8s.jeiang.vpn`. Set `--set netbird.enabled=false` to opt out.

## Verify

Verify the Service and replica count:

```fish
kubectl -n dns get svc blocky-dns
kubectl -n dns get deploy blocky-dns
```

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.
