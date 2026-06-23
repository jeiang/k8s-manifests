# Repository Guidelines

## Project Structure & Module Organization

This repository contains Helm charts and Kubernetes manifests for server workloads. Each top-level chart directory owns its `Chart.yaml`, `values.yaml`, `templates/`, and chart-specific `README.md`.
Values-only directories are used for upstream charts installed directly from external Helm repositories.

- `website/`: static website deployment with Traefik ingress and cert-manager TLS.
- `blocky-dns/`: Blocky DNS resolver deployment and service.
- `idp/`: Pocket ID and LLDAP identity provider stack.
- `netbird/`: NetBird server, dashboard, relay, ingress, and storage resources.
- `traefik/`: k3s bundled Traefik `HelmChartConfig` with Hetzner Load Balancer annotations.
- `rbac-access/`: namespace and cluster RBAC bindings.

Keep reusable Helm helpers in each chart's `templates/_helpers.tpl`. Avoid sharing hidden coupling between charts; prefer explicit values in the chart that needs them.

## Build, Test, and Development Commands

Use the Nix/devenv environment when available:

```sh
devenv shell
```

Common validation commands:

```sh
helm lint ./<chart-name>
helm template <release-name> ./<chart-name> --namespace <namespace>
helm upgrade --install <release-name> ./<chart-name> --namespace <namespace> --create-namespace
```

`helm lint` catches chart and template problems. `helm template` renders manifests locally for review. Use `helm upgrade --install` only when applying to a configured cluster.

## Coding Style & Naming Conventions

Use two-space YAML indentation. Keep Kubernetes resource names lowercase, DNS-safe, and stable. Prefer chart-local helper names such as `website.fullname` and `rbac-access.labels`, and use `nindent`, `quote`, `trunc 63`, and `trimSuffix "-"` where needed for valid manifests.

Values should be grouped by component, for example `server.image`, `ingress.tls`, and `persistence.size`. Keep environment-specific defaults visible in `values.yaml` and document risky defaults in the chart README.

## Cluster Platform Notes

The target cluster is k3s on Hetzner Cloud nodes running NixOS. Keep docs and manifests compatible with this baseline:

- k3s should use the Hetzner private network interface for Flannel.
- k3s ServiceLB is disabled because Hetzner Cloud Controller Manager owns `LoadBalancer` Services.
- k3s embedded cloud controller is disabled and kubelet uses `cloud-provider=external` for `hcloud-cloud-controller-manager`.
- The cluster is IPv4-only for pod and service networking; public IPv6 can still be handled by Hetzner Load Balancers where needed.
- Hetzner CSI uses a `kube-system/hcloud` Secret. Repository PVC defaults use the RWO-only `hcloud-volumes` StorageClass; never commit the live token.
- On this k3s/NixOS setup, install `hcloud-csi` with `node.kubeletDir=/var/lib/kubelet`.
- Hetzner public IPv4s belong in node OS networking, but k3s node external addresses should generally be left to the external cloud controller.
- Hetzner Cloud Volumes are node-attached RWO storage. Do not configure repo PVCs as RWX unless the storage backend changes.

## Testing Guidelines

There is no separate unit test suite. Validate every changed chart with:

```sh
helm lint ./<chart-name>
helm template test ./<chart-name> --namespace test
```

Inspect rendered YAML for correct namespaces, labels, selectors, secret references, PVC/PV names, ingress hosts, and conditional resources. For RBAC changes, verify generated subjects and role bindings carefully.

## Commit & Pull Request Guidelines

Recent commits use short conventional prefixes such as `feat:`, `feature:`, and `chore:`. Keep commit messages imperative and scoped, for example `feat: add netbird chart` or `chore: update devenv tools`.

Pull requests should describe the affected chart, summarize behavior changes, list validation commands run, and call out cluster-facing risks such as public ingress, LoadBalancer services, persistent storage, RBAC grants, or secret key changes.

## Security & Configuration Tips

Do not commit live secret values. Prefer existing Kubernetes Secrets referenced from `values.yaml`. Review public hostnames, ACME issuer names, external services, hostPort exposure, and persistent storage before applying manifests to any cluster.
