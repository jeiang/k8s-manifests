# k8s manifests

Helm charts and Kubernetes manifests for my servers.

## Charts

| Chart | Purpose |
| --- | --- |
| [`website`](./website) | Static website deployment behind Traefik with cert-manager TLS. |
| [`bitwarden-sm-operator`](./bitwarden-sm-operator) | Values for the upstream Bitwarden Secrets Manager Kubernetes Operator chart. |
| [`blocky-dns`](./blocky-dns) | Internal Blocky DNS resolver exposed through a `ClusterIP` Service. |
| [`hath`](./hath) | H@H Rust client with persistent cache storage. |
| [`idp`](./idp) | Pocket ID and LLDAP identity provider stack with persistent state. |
| [`longhorn`](./longhorn) | Values for the upstream Longhorn storage chart. |
| [`monitoring`](./monitoring) | Values for upstream Prometheus, Alertmanager, Grafana, Loki, and Alloy charts. |
| [`netbird`](./netbird) | NetBird management server, dashboard, and relay stack. |
| [`netbird-resources`](./netbird-resources) | NetBird operator routing resources for Kubernetes Services. |
| [`rbac-access`](./rbac-access) | Cluster admin and namespace admin RBAC bindings. |

## Global Prerequisites

- Helm 3.
- `kubectl` configured for the target cluster.
- Optional: `devenv shell` to load `kubectl`, Helm, `helm-ls`, and `yaml-language-server`.
- Working DNS records for public ingress hosts before installing internet-facing charts.
- A load balancer implementation for charts that expose `LoadBalancer` Services.

## Chart Dependencies

| Chart | Dependencies |
| --- | --- |
| `website` | Traefik IngressClass named `traefik`; Traefik `Middleware` CRD; cert-manager CRDs/controller; existing `letsencrypt-prod` `ClusterIssuer` unless `certManager.clusterIssuer.create=true`; DNS for all `ingress.hosts`. |
| `bitwarden-sm-operator` | Bitwarden organization with Secrets Manager enabled; machine account access token; permissions to install CRDs/RBAC/operator resources; network egress to Bitwarden Cloud or self-hosted Bitwarden URLs. |
| `blocky-dns` | metrics-server or another resource metrics provider for the HPA; outbound DNS/HTTPS access for upstreams and blocklists. |
| `hath` | Longhorn storage for cache/data directories; load balancer and firewall rules for public access to the configured H@H port; Prometheus Operator CRDs if ServiceMonitor output is enabled. |
| `idp` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `auth.jeiang.dev`; pre-created `idp-secrets` or Bitwarden Secrets Manager operator; hostPath storage under `/var/lib/idp` or alternative persistence values. |
| `longhorn` | Kubernetes `>=1.25`; node storage under `/var/lib/longhorn`; open-iscsi and mount/NFS tooling on storage nodes; privileged workloads allowed in `longhorn-system`. |
| `monitoring` | Kubernetes `>=1.25`; permissions to install Prometheus Operator CRDs/RBAC; Longhorn storage class for Prometheus, Alertmanager, Grafana, and Loki PVCs; Discord webhook Secret for Alertmanager; optional Traefik/cert-manager/DNS for Grafana ingress. |
| `netbird` | Traefik `IngressRoute` CRDs and `websecure` entryPoint; cert-manager `Certificate` CRD/controller and `letsencrypt-prod` `ClusterIssuer`; load balancer access for UDP `3478`; DNS for `netbird.jeiang.dev`; pre-created `netbird-secrets` or Bitwarden Secrets Manager operator; persistent storage for the server PVC; Prometheus Operator CRDs if ServiceMonitor output is enabled. |
| `netbird-resources` | NetBird Kubernetes operator and CRDs for `NetworkRouter` and `NetworkResource`; custom NetBird DNS zone; existing `blocky-dns`, `idp-lldap`, `longhorn-frontend`, `longhorn-backend`, and `monitoring-grafana` Services; optional Bitwarden Secrets Manager operator for the NetBird API token Secret. |
| `rbac-access` | Installer must have permission to create `Namespace`, `RoleBinding`, and `ClusterRoleBinding` resources; configured subjects must match identities from cluster authentication. |

## Usage

Install a chart from the repository root:

```fish
helm upgrade --install <release-name> ./<chart-name> --namespace <namespace> --create-namespace
```

Review each chart README before installing. Several charts contain environment-specific defaults such as public hostnames, ACME issuer names, RBAC usernames, hostPath storage paths, and externally exposed services.

Render or lint a chart before applying changes:

```fish
helm lint ./<chart-name>
helm template <release-name> ./<chart-name> --namespace <namespace>
```
