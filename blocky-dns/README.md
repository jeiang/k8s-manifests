# blocky-dns

Helm chart for running Blocky as an internal DNS service.

Default application version: `v0.28.2`.

## What This Chart Creates

- A Blocky Deployment.
- A `HorizontalPodAutoscaler` that keeps at least 1 pod and scales up to 5 pods.
- A `ClusterIP` Service exposing DNS on port `53` for UDP and TCP inside the cluster.
- A ConfigMap-mounted Blocky `config.yml`.
- DNS blocklists from StevenBlack and Hagezi.
- Default upstreams for Cloudflare, Google, and Quad9.
- An optional NetBird `NetworkResource` for the Blocky Service when `netbird.enabled=true`.
- Resource limits of `500m` CPU and `350Mi` memory.

## Dependencies

- Helm 3 and `kubectl`.
- metrics-server or another Kubernetes resource metrics provider for HPA CPU scaling.
- Outbound HTTPS access so Blocky can download remote blocklists.
- Outbound DNS access to the configured upstream resolvers.
- NetBird operator CRDs if `netbird.enabled=true`.

## Install

```fish
helm lint ./blocky-dns
helm template blocky-dns ./blocky-dns --namespace dns
helm upgrade --install blocky-dns ./blocky-dns \
  --namespace dns \
  --create-namespace
```

The NetBird integration is disabled by default. Enable it after installing the shared NetBird router and operator resources:

```fish
helm dependency build ./blocky-dns

helm upgrade --install blocky-dns ./blocky-dns \
  --namespace dns \
  --create-namespace \
  --set netbird.enabled=true
```

With the default values, that creates a `NetworkResource` named `blocky-dns` in the `dns` namespace for `blocky-dns.dns.k8s.jeiang.vpn`.

## Verify

Verify the Service and HPA:

```fish
kubectl -n dns get svc blocky-dns
kubectl -n dns get hpa blocky-dns
```

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.
