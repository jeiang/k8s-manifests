# k8s manifests

Helm charts, upstream chart values, and Kubernetes manifests for my servers.

Repository-wide operational notes live in:

- [`docs/CLUSTER.md`](./docs/CLUSTER.md) for k3s, Hetzner, networking, storage, and external platform dependencies.
- [`docs/AUTHENTICATION.md`](./docs/AUTHENTICATION.md) for Pocket ID/OIDC kubectl authentication on macOS, Linux, and Windows.
- [`docs/SETUP_INSTRUCTIONS.md`](./docs/SETUP_INSTRUCTIONS.md) for user setup, namespace access, and delegation commands.
- [`docs/AGENT_INSTRUCTIONS.md`](./docs/AGENT_INSTRUCTIONS.md) for cloud agents or other users creating namespace-scoped Helm charts.
- [`docs/SECRETS.md`](./docs/SECRETS.md) for repository secret handling and Bitwarden Secrets Manager policy.
- [`AGENTS.md`](./AGENTS.md) for contributor and automation guidance.

Chart-specific maintenance guidance lives in each chart directory's `AGENTS.md` when present.

## Charts

| Chart | Purpose |
| --- | --- |
| [`website`](./website) | Static website deployment behind Traefik with cert-manager TLS. |
| [`bitwarden-sm-operator`](./bitwarden-sm-operator) | Values for the upstream Bitwarden Secrets Manager Kubernetes Operator chart. |
| [`blocky-dns`](./blocky-dns) | Internal Blocky DNS resolver exposed through a `ClusterIP` Service. |
| [`crowdsec`](./crowdsec) | Values and support manifests for upstream CrowdSec WAF, NetBird IP reputation, and metrics scraping. |
| [`hath`](./hath) | H@H Rust client with persistent cache storage. |
| [`idp`](./idp) | Pocket ID identity provider with persistent state. |
| [`monitoring`](./monitoring) | Values and Bitwarden configuration for the upstream VictoriaMetrics monitoring stack with Grafana and VictoriaLogs. |
| [`netbird`](./netbird) | NetBird management server, dashboard, and relay stack. |
| [`netbird-resources`](./netbird-resources) | Shared NetBird operator API token and router resources for Kubernetes Services. |
| [`rclone-csi-driver`](./rclone-csi-driver) | Values and Bitwarden configuration for the upstream rclone CSI driver chart. |
| [`rbac-access`](./rbac-access) | Pocket ID/OIDC group RBAC plus Kyverno namespace ownership policies. |
| [`traefik`](./traefik) | k3s bundled Traefik `HelmChartConfig` with Hetzner Load Balancer annotations. |

## Global Prerequisites

- Helm 3.
- `kubectl` configured for the target cluster.
- `kubectl oidc-login` for normal user authentication; see [`docs/AUTHENTICATION.md`](./docs/AUTHENTICATION.md).
- Optional: `devenv shell` to load `kubectl`, Helm, `helm-ls`, and `yaml-language-server`.
- Working DNS records for public ingress hosts before installing internet-facing charts.
- Hetzner Cloud Controller Manager for charts that expose `LoadBalancer` Services.
- Storage classes expected by the workload being installed; see [`docs/CLUSTER.md`](./docs/CLUSTER.md#storage-policy).
- Deployments that mount Hetzner `hcloud-volumes` PVCs must use `Recreate`, not rolling updates, to avoid RWO multi-attach failures during upgrades.
- Bootstrap/operator Secrets required by the workload; see [`docs/SECRETS.md`](./docs/SECRETS.md).

## Usage

Install a chart from the repository root:

```fish
helm upgrade --install <release-name> ./<chart-name> --namespace <namespace> --create-namespace
```

Run `helm dependency build ./<chart-name>` before rendering or installing charts with local dependencies, such as `blocky-dns` when using its optional NetBird subchart.

Review each chart README before installing. Several charts contain environment-specific defaults such as public hostnames, ACME issuer names, RBAC usernames, hostPort exposure, and persistent storage.

Render or lint a chart before applying changes:

```fish
helm lint ./<chart-name>
helm template <release-name> ./<chart-name> --namespace <namespace>
```

For values-only upstream chart directories, render the upstream chart with the local values file. For plain manifest directories, review with `kubectl diff --server-side -f <file>` when a configured cluster is available.

## Cluster Platform

The target platform is a k3s cluster on Hetzner Cloud nodes running NixOS. See [`docs/CLUSTER.md`](./docs/CLUSTER.md) for networking flags, OIDC authentication, Hetzner component installation, storage class policy, and expected external cluster components.

## Secrets Policy

Application and workload secrets should live in Bitwarden Secrets Manager and be synced through `BitwardenSecret` resources. See [`docs/SECRETS.md`](./docs/SECRETS.md) for allowed bootstrap Secrets and repository handling rules.

## Chart Dependencies

| Chart | Dependencies |
| --- | --- |
| `website` | Traefik IngressClass named `traefik`; Traefik `Middleware` CRD; cert-manager CRDs/controller; existing `letsencrypt-prod` `ClusterIssuer` unless `certManager.clusterIssuer.create=true`; DNS for all `ingress.hosts`. |
| `bitwarden-sm-operator` | Bitwarden organization with Secrets Manager enabled; machine account access token; permissions to install CRDs/RBAC/operator resources; network egress to Bitwarden Cloud or self-hosted Bitwarden URLs. |
| `actual-budget` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `budget.jeiang.dev`; rclone CSI `rclone-csi` StorageClass and Bitwarden-synced `rclone-config` Secret. |
| `blocky-dns` | metrics-server or another resource metrics provider for the HPA; outbound DNS/HTTPS access for upstreams and blocklists; optional NetBird operator CRDs when `netbird.enabled=true`. |
| `crowdsec` | Upstream CrowdSec Helm chart repository; k3s containerd logs; Traefik pods in `kube-system`; VictoriaMetrics operator CRDs for `VMServiceScrape`; Bitwarden Secrets Manager operator for the Traefik dynamic config Secret; Hetzner CSI `hcloud-volumes` storage. |
| `hath` | rclone CSI `rclone-csi` storage for cache/data directories; firewall rules for TCP `8888` to the node running the Hath pod. |
| `idp` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `auth.jeiang.dev`; Bitwarden Secrets Manager operator for `idp-secrets`; Hetzner CSI `hcloud-volumes` storage. |
| `monitoring` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `grafana.jeiang.dev`; Pocket ID OIDC client `a70e6d0d-360c-415f-b154-85ec7a6bc352`; Bitwarden Secrets Manager operator for `grafana-oauth`; Hetzner CSI `hcloud-volumes` storage; later NetBird resources for raw VictoriaMetrics and VictoriaLogs endpoints. |
| `netbird` | Traefik `IngressRoute` CRDs and `websecure` entryPoint; cert-manager `Certificate` CRD/controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `netbird.jeiang.dev` to the Traefik load balancer; DNS for `stun.netbird.jeiang.dev` to the two labeled STUN relay nodes; firewall access for UDP `3478`; Bitwarden Secrets Manager operator for `netbird-secrets`; CrowdSec LAPI and a bouncer key when `proxy.crowdsec.enabled=true`; persistent storage for the server PVC. |
| `netbird-resources` | NetBird Kubernetes operator and CRDs for `NetworkRouter` and `NetworkResource`; custom NetBird DNS zone; Bitwarden Secrets Manager operator for the NetBird API token Secret. |
| `rclone-csi-driver` | FUSE support on cluster nodes; Bitwarden Secrets Manager operator for `rclone-config`; network access from nodes to the configured rclone backend; upstream OCI Helm chart access to `ghcr.io/veloxpack/charts/csi-driver-rclone`. |
| `rbac-access` | Pocket ID configured as the Kubernetes OIDC issuer; Kyverno installed; installer must have permission to create `ClusterPolicy`, `ClusterRole`, `ClusterRoleBinding`, and `RoleBinding` resources. |
| `traefik` | k3s bundled Traefik chart enabled; Hetzner Cloud Controller Manager installed; `legion-lb1` Load Balancer in the `us-east` network zone; `kube-system/traefik-crowdsec-dynamic` Secret when CrowdSec WAF is enabled. |
