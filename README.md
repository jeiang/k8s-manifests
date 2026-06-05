# k8s manifests

Helm charts and Kubernetes manifests for my servers.

## Charts

| Chart | Purpose |
| --- | --- |
| [`aidanp-website`](./aidanp-website) | Static website deployment behind Traefik with cert-manager TLS. |
| [`blocky-dns`](./blocky-dns) | Public Blocky DNS resolver exposed through a `LoadBalancer` Service. |
| [`idp`](./idp) | Pocket ID and LLDAP identity provider stack with persistent state. |
| [`rbac-access`](./rbac-access) | Cluster admin and namespace admin RBAC bindings. |

## Prerequisites

- Helm 3.
- `kubectl` configured for the target cluster.
- Traefik for charts that enable ingress by default.
- cert-manager and a `letsencrypt-prod` `ClusterIssuer` for charts that request TLS by default.
- Working DNS records for public ingress hosts before installing internet-facing charts.

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
