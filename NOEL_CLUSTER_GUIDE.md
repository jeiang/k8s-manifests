# Namespace Helm Chart Guide

This guide lists only the cluster resources and conventions needed to create namespace-scoped Helm charts for this environment.

## Scope

Charts should assume access only to resources in the target namespace and to cluster services intentionally exposed for workload use.

Do not create or depend on cluster-scoped resources unless a cluster administrator explicitly provides them. This includes `ClusterRole`, `ClusterRoleBinding`, CRDs, cluster-wide controllers, and shared infrastructure resources.

## Namespace Requirement

Deploy each Helm release into an approved namespace.

Allowed namespace patterns:

- The assigned personal namespace.
- `shared`, only for resources intentionally shared with other users.
- Explicitly approved prefixed namespaces, such as `<name>-<app>`.

Kubernetes RBAC does not grant access to future namespaces automatically. A new namespace must be created and authorized before a chart can be deployed there.

Example workflow:

```sh
helm lint ./<chart>
helm template <release> ./<chart> --namespace <namespace>
helm upgrade --install <release> ./<chart> --namespace <namespace> --create-namespace
```

Use `--create-namespace` only after confirming the namespace is approved.

## Available Workload Resources

| Resource | Use |
| --- | --- |
| Traefik IngressClass `traefik` | Public HTTP/HTTPS routing through Kubernetes `Ingress`. |
| cert-manager `ClusterIssuer` `letsencrypt-prod` | Public TLS certificates for approved DNS names. |
| Bitwarden Secrets Manager operator | Syncing application secrets into the namespace with `BitwardenSecret`. |
| StorageClass `hcloud-volumes` | Small `ReadWriteOnce` persistent volumes, roughly less than `20Gi`. |
| StorageClass `rclone-csi` | Larger, growth-prone, or `ReadWriteMany` persistent volumes. |
| NetBird namespace resources, when enabled | Private access to namespace Services without public ingress. |

## Chart Defaults

Prefer these defaults:

- Namespaced resources only.
- Service type `ClusterIP`.
- Public web access through `Ingress` with `ingressClassName: traefik`.
- TLS through `cert-manager.io/cluster-issuer: letsencrypt-prod`.
- Secrets referenced from Kubernetes Secrets synced by Bitwarden.
- Resource requests and limits for long-running containers.
- Stable DNS-safe names and labels.

Avoid these unless explicitly approved:

- `NodePort`, `LoadBalancer`, `hostNetwork`, or `hostPort`.
- Privileged containers or broad Linux capabilities.
- Literal passwords, tokens, private keys, cookies, or storage credentials in chart files.
- `ReadWriteMany` claims on `hcloud-volumes`.
- Cluster-scoped RBAC or controllers.

## Ingress And TLS

Use Traefik and cert-manager for public HTTP/HTTPS applications.

Example values shape:

```yaml
ingress:
  enabled: true
  className: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

Before installation, confirm the hostname is approved and points at the ingress endpoint. Keep the backing Service as `ClusterIP`.

## Secrets

Application secrets should be stored in Bitwarden Secrets Manager and synced into the namespace with `BitwardenSecret`.

Each namespace that syncs Bitwarden secrets needs a namespace-local bootstrap Secret named:

```text
bw-auth-token
```

Do not commit the token or any application secret value.

Example `BitwardenSecret` shape:

```yaml
apiVersion: k8s.bitwarden.com/v1
kind: BitwardenSecret
metadata:
  name: app-secrets
spec:
  organizationId: "<bitwarden-organization-id>"
  secretName: app-secrets
  onlyMappedSecrets: true
  map:
    - bwSecretId: "<bitwarden-secret-id>"
      secretKeyName: APP_SECRET
  authToken:
    secretName: bw-auth-token
    secretKey: token
```

Pods should consume the synced Kubernetes Secret by name through environment variables or mounted secret files.

## Persistent Storage

Choose the StorageClass by access mode and expected size.

Use `hcloud-volumes` for small `ReadWriteOnce` volumes:

```yaml
persistence:
  enabled: true
  storageClassName: hcloud-volumes
  accessModes:
    - ReadWriteOnce
  size: 5Gi
```

Use `rclone-csi` for `ReadWriteMany`, multi-pod, larger than `20Gi`, or growth-prone volumes:

```yaml
persistence:
  enabled: true
  storageClassName: rclone-csi
  accessModes:
    - ReadWriteMany
  size: 25Gi
```

Do not request `ReadWriteMany` from `hcloud-volumes`.

## Private Service Access

If private access is enabled for the namespace, expose the workload with a normal `ClusterIP` Service and a namespace-scoped NetBird resource that points at that Service.

Do not define shared NetBird router, API-token, or operator resources in application charts.

## Validation Checklist

Before handing off or installing a chart:

```sh
helm lint ./<chart>
helm template <release> ./<chart> --namespace <namespace>
```

Review the rendered manifests for:

- All resources are in the approved namespace.
- No unexpected cluster-scoped resources are rendered.
- Secret values are referenced by name only.
- `BitwardenSecret` uses namespace-local `bw-auth-token`.
- Ingress uses `traefik` and `letsencrypt-prod`.
- PVC storage class, access mode, and size match the storage policy.
- Services stay `ClusterIP` unless otherwise approved.
- Containers have resource requests and limits.
