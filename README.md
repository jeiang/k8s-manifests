# k8s manifests

Helm charts and Kubernetes manifests for my servers.

Repository-wide cluster notes live in [`AGENTS.md`](./AGENTS.md). Chart-specific maintenance guidance lives in each chart directory's `AGENTS.md` when present.

## Charts

| Chart | Purpose |
| --- | --- |
| [`website`](./website) | Static website deployment behind Traefik with cert-manager TLS. |
| [`bitwarden-sm-operator`](./bitwarden-sm-operator) | Values for the upstream Bitwarden Secrets Manager Kubernetes Operator chart. |
| [`blocky-dns`](./blocky-dns) | Internal Blocky DNS resolver exposed through a `ClusterIP` Service. |
| [`hath`](./hath) | H@H Rust client with persistent cache storage. |
| [`idp`](./idp) | Pocket ID and LLDAP identity provider stack with persistent state. |
| [`netbird`](./netbird) | NetBird management server, dashboard, and relay stack. |
| [`netbird-resources`](./netbird-resources) | Shared NetBird operator API token and router resources for Kubernetes Services. |
| [`rclone-csi-driver`](./rclone-csi-driver) | Values and Bitwarden configuration for the upstream rclone CSI driver chart. |
| [`rbac-access`](./rbac-access) | Cluster admin and namespace admin RBAC bindings. |
| [`traefik`](./traefik) | k3s bundled Traefik `HelmChartConfig` with Hetzner Load Balancer annotations. |

## Global Prerequisites

- Helm 3.
- `kubectl` configured for the target cluster.
- Optional: `devenv shell` to load `kubectl`, Helm, `helm-ls`, and `yaml-language-server`.
- Working DNS records for public ingress hosts before installing internet-facing charts.
- Hetzner Cloud Controller Manager for charts that expose `LoadBalancer` Services.

## Cluster Platform

The current target cluster is a fresh k3s cluster on Hetzner Cloud nodes running NixOS.

Expected node-level setup:

- Configure each node's Hetzner public IPv4 as a `/32` address and public IPv6 as a `/64` address in NixOS/systemd-networkd.
- Keep private cluster traffic on the Hetzner private network interface and use that interface for Flannel.
- Use IPv4-only pod and service CIDRs for Kubernetes networking.
- Disable k3s ServiceLB so Hetzner Cloud Controller Manager owns `LoadBalancer` Services.
- Disable the embedded k3s cloud controller and set the kubelet cloud provider to `external` before installing `hcloud-cloud-controller-manager`.
- Install the Hetzner CSI driver for Hetzner Cloud Volumes, backed by a `kube-system/hcloud` Secret containing a read/write Hetzner Cloud API token.

Important k3s flags for this platform:

```sh
--flannel-iface=<hetzner-private-interface>
--disable=servicelb
--disable-cloud-controller
--kubelet-arg=cloud-provider=external
--cluster-cidr=10.42.0.0/16
--service-cidr=10.43.0.0/16
```

The Hetzner Cloud Controller Manager should own node provider IDs and cloud-discovered node addresses. Do not commit live Hetzner API tokens, real secret values, or one-off cluster bootstrap tokens to this repository.

## Secrets Policy

All application and workload secrets should live in Bitwarden Secrets Manager and be synced into Kubernetes with `BitwardenSecret` resources. The only Kubernetes Secrets that should be created directly are bootstrap/operator credentials required before Bitwarden can sync anything:

- `kube-system/hcloud`, used by Hetzner Cloud Controller Manager and Hetzner CSI.
- Per-namespace `bw-auth-token` Secrets, used by the Bitwarden Secrets Manager operator to read Bitwarden items.

Do not create application Secrets manually with literal values when a `BitwardenSecret` can own them instead.

Install the Hetzner components after the k3s nodes are up:

```fish
kubectl -n kube-system create secret generic hcloud \
  --from-literal=token=REPLACE_ME_HCLOUD_TOKEN \
  --from-literal=network=REPLACE_ME_HETZNER_NETWORK_ID_OR_NAME

helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud

helm upgrade --install hccm hcloud/hcloud-cloud-controller-manager \
  --namespace kube-system \
  --set networking.enabled=true \
  --set networking.clusterCIDR=10.42.0.0/16 \
  --wait

helm upgrade --install hcloud-csi hcloud/hcloud-csi \
  --namespace kube-system \
  --set node.kubeletDir=/var/lib/kubelet \
  --wait
```

Most repository PVC defaults use the Hetzner CSI-backed `hcloud-volumes` StorageClass. It must be treated as ReadWriteOnce-only; Hetzner Cloud Volumes are node-attached block volumes and do not support RWX. Workloads that explicitly use rclone-backed storage set `storageClassName` or `storageClass` to `rclone-csi`.

Verify the storage class before installing workloads that create PVCs:

```fish
kubectl get storageclass hcloud-volumes
kubectl get storageclass rclone-csi
```

## Chart Dependencies

| Chart | Dependencies |
| --- | --- |
| `website` | Traefik IngressClass named `traefik`; Traefik `Middleware` CRD; cert-manager CRDs/controller; existing `letsencrypt-prod` `ClusterIssuer` unless `certManager.clusterIssuer.create=true`; DNS for all `ingress.hosts`. |
| `bitwarden-sm-operator` | Bitwarden organization with Secrets Manager enabled; machine account access token; permissions to install CRDs/RBAC/operator resources; network egress to Bitwarden Cloud or self-hosted Bitwarden URLs. |
| `actual-budget` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `budget.jeiang.dev`; rclone CSI `rclone-csi` StorageClass and Bitwarden-synced `rclone-config` Secret. |
| `blocky-dns` | metrics-server or another resource metrics provider for the HPA; outbound DNS/HTTPS access for upstreams and blocklists; optional NetBird operator CRDs when `netbird.enabled=true`. |
| `hath` | rclone CSI `rclone-csi` storage for cache/data directories; firewall rules for TCP `8888` to the node running the Hath pod. |
| `idp` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `auth.jeiang.dev`; Bitwarden Secrets Manager operator for `idp-secrets`; Hetzner CSI `hcloud-volumes` storage; optional NetBird operator CRDs when `netbird.enabled=true`. |
| `netbird` | Traefik `IngressRoute` CRDs and `websecure` entryPoint; cert-manager `Certificate` CRD/controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `netbird.jeiang.dev` to the Traefik load balancer; DNS for `stun.netbird.jeiang.dev` to the two labeled STUN relay nodes; firewall access for UDP `3478`; Bitwarden Secrets Manager operator for `netbird-secrets`; persistent storage for the server PVC. |
| `netbird-resources` | NetBird Kubernetes operator and CRDs for `NetworkRouter` and `NetworkResource`; custom NetBird DNS zone; Bitwarden Secrets Manager operator for the NetBird API token Secret. |
| `rclone-csi-driver` | FUSE support on cluster nodes; Bitwarden Secrets Manager operator for `rclone-config`; network access from nodes to the configured rclone backend; upstream OCI Helm chart access to `ghcr.io/veloxpack/charts/csi-driver-rclone`. |
| `rbac-access` | Installer must have permission to create `Namespace`, `RoleBinding`, and `ClusterRoleBinding` resources; configured subjects must match identities from cluster authentication. |
| `traefik` | k3s bundled Traefik chart enabled; Hetzner Cloud Controller Manager installed; `legion-lb1` Load Balancer in the `us-east` network zone. |

## Usage

Install a chart from the repository root:

```fish
helm upgrade --install <release-name> ./<chart-name> --namespace <namespace> --create-namespace
```

Run `helm dependency build ./<chart-name>` before rendering or installing charts with local dependencies, such as `blocky-dns` or `idp` when using their optional NetBird subchart.

Review each chart README before installing. Several charts contain environment-specific defaults such as public hostnames, ACME issuer names, RBAC usernames, hostPort exposure, and persistent storage.

Render or lint a chart before applying changes:

```fish
helm lint ./<chart-name>
helm template <release-name> ./<chart-name> --namespace <namespace>
```
