# Repository Guidelines

## Project Structure & Module Organization

This repository contains Helm charts, upstream chart values, and Kubernetes manifests for server workloads. Chart-specific maintenance notes live in each chart directory's `AGENTS.md`; keep this root file limited to cluster-wide conventions, external platform dependencies, and repository-wide workflow.

Top-level directories generally fall into one of three forms:

- Local Helm charts with `Chart.yaml`, `values.yaml`, `templates/`, and `README.md`.
- Values-only directories for upstream Helm charts installed from external repositories.
- Plain Kubernetes manifest directories for cluster-owned components such as k3s bundled Traefik configuration.

The `monitoring/` directory is intentionally out of scope for this guidance unless a task explicitly asks to work on it.

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

Run `helm dependency build ./<chart-name>` before rendering or installing charts that declare local dependencies. `helm lint` catches chart and template problems. `helm template` renders manifests locally for review. Use `helm upgrade --install` only when applying to a configured cluster.

## Coding Style & Naming Conventions

Use two-space YAML indentation. Keep Kubernetes resource names lowercase, DNS-safe, and stable. Prefer chart-local helper names such as `<chart>.fullname` and `<chart>.labels`, and use `nindent`, `quote`, `trunc 63`, and `trimSuffix "-"` where needed for valid manifests.

Values should be grouped by component, for example `server.image`, `ingress.tls`, and `persistence.size`. Keep environment-specific defaults visible in `values.yaml` and document risky defaults in the chart README.

## Cluster Platform Notes

The target cluster is k3s on Hetzner Cloud nodes running NixOS. Keep cluster-facing docs and manifests compatible with this baseline:

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

Inspect rendered YAML for correct namespaces, labels, selectors, secret references, PVC/PV names, ingress hosts, and conditional resources. For values-only upstream chart directories, render the upstream chart with the local values file. For plain manifest directories, review with `kubectl diff --server-side -f <file>` when a configured cluster is available. For RBAC changes, verify generated subjects and role bindings carefully.

## Commit & Pull Request Guidelines

Recent commits use short conventional prefixes such as `feat:`, `feature:`, and `chore:`. Keep commit messages imperative and scoped, for example `feat: add netbird chart` or `chore: update devenv tools`.

Pull requests should describe the affected chart, summarize behavior changes, list validation commands run, and call out cluster-facing risks such as public ingress, LoadBalancer services, persistent storage, RBAC grants, or secret key changes.

## Security & Configuration Tips

Do not commit live secret values. Prefer existing Kubernetes Secrets referenced from `values.yaml`. Review public hostnames, ACME issuer names, external services, hostPort exposure, and persistent storage before applying manifests to any cluster.

## External Cluster Components

These components are expected to exist but are not defined as local Helm charts here:

- Hetzner Cloud Controller Manager from `hcloud/hcloud-cloud-controller-manager`, installed in `kube-system` with networking enabled for the cluster CIDR.
- Hetzner CSI from `hcloud/hcloud-csi`, installed in `kube-system` with `node.kubeletDir=/var/lib/kubelet`.
- cert-manager and a production `letsencrypt-prod` `ClusterIssuer`.
- k3s bundled Traefik, configured by `traefik/traefik-helmchartconfig.yaml`.
- Bitwarden Secrets Manager operator when charts render `BitwardenSecret` resources.
- NetBird Kubernetes operator when charts render `NetworkRouter` or `NetworkResource` resources.
- Prometheus Operator CRDs when a chart's `ServiceMonitor` output is enabled.
- Rclone CSI driver from `oci://ghcr.io/veloxpack/charts/csi-driver-rclone` when rclone-backed PVCs are needed; local values live in `rclone-csi-driver/`.
