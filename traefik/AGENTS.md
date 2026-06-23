# Chart Guidelines

## Scope

This directory contains a k3s `HelmChartConfig` for the bundled Traefik chart. It is a plain Kubernetes manifest, not a local Helm chart.

## Runtime Contract

- The config is applied in `kube-system` with name `traefik`.
- The Hetzner Load Balancer name is `legion-lb1`.
- The Hetzner Load Balancer network zone is `us-east`.
- Protocol and health checks are TCP.

## Editing Notes

- Keep annotations compatible with Hetzner Cloud Controller Manager.
- This file changes the k3s-managed Traefik release; validate against a cluster before applying.
- Do not add workload-specific routing here.

## Validation

```sh
kubectl diff --server-side -f ./traefik/traefik-helmchartconfig.yaml
```

