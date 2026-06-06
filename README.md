# k8s manifests

Helm charts and Kubernetes manifests for my servers.

## Charts

| Chart | Purpose |
| --- | --- |
| [`website`](./website) | Static website deployment behind Traefik with cert-manager TLS. |
| [`blocky-dns`](./blocky-dns) | Public Blocky DNS resolver exposed through a `LoadBalancer` Service. |
| [`idp`](./idp) | Pocket ID and LLDAP identity provider stack with persistent state. |
| [`netbird`](./netbird) | NetBird management server, dashboard, and relay stack. |
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
| `blocky-dns` | Load balancer that supports UDP and TCP port `53`; metrics-server or another resource metrics provider for the HPA; outbound DNS/HTTPS access for upstreams and blocklists; firewall or network ACLs for public resolver protection. |
| `idp` | Traefik IngressClass named `traefik`; cert-manager controller and `letsencrypt-prod` `ClusterIssuer`; DNS for `auth.jeiang.dev` and `lldap.jeiang.dev`; pre-created `idp-secrets`; hostPath storage under `/var/lib/idp` or alternative persistence values. |
| `netbird` | Traefik `IngressRoute` CRDs and `websecure` entryPoint; cert-manager `Certificate` CRD/controller and `letsencrypt-prod` `ClusterIssuer`; load balancer access for UDP `3478`; DNS for `netbird.jeiang.dev`; pre-created `netbird-secrets`; persistent storage for the server PVC. |
| `rbac-access` | Installer must have permission to create `Namespace`, `RoleBinding`, and `ClusterRoleBinding` resources; configured subjects must match identities from cluster authentication. |

## Usage

Install a chart from the repository root:

```sh
helm upgrade --install <release-name> ./<chart-name> --namespace <namespace> --create-namespace
```

Review each chart README before installing. Several charts contain environment-specific defaults such as public hostnames, ACME issuer names, RBAC usernames, hostPath storage paths, and externally exposed services.

Render or lint a chart before applying changes:

```sh
helm lint ./<chart-name>
helm template <release-name> ./<chart-name> --namespace <namespace>
```
