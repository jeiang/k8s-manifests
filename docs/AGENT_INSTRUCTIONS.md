# Agent Instructions for Namespace Helm Charts

Use this guide when creating or reviewing namespace-scoped Helm charts for this cluster.

## Cluster Context

- The cluster is k3s on Hetzner Cloud nodes running NixOS.
- Normal users authenticate with Pocket ID/OIDC.
- Users in `kubernetes-access` can create their personal namespace and namespaces prefixed by their username.
- Users in `kubernetes-admin` are cluster admins.
- Emergency access uses the built-in k3s admin kubeconfig.

Example users:

- `john` owns `john` and `john-*`, such as `john-website`.
- `mike` owns `mike` and `mike-*`.
- `tony` owns `tony` and `tony-*`.

## First Steps To Assist A User

Confirm the user has followed [`SETUP_INSTRUCTIONS.md`](./SETUP_INSTRUCTIONS.md) and can run:

```sh
kubectl auth whoami
kubectl auth can-i create namespaces
```

For a new user `john`, help them create:

```sh
kubectl create namespace john
kubectl create namespace john-website
```

Use the personal namespace for private/default work and a prefixed namespace for shareable project work. Users cannot self-service share their personal namespace.

## Namespace And Access Rules

- Deploy all workload resources into an approved namespace.
- Normal users may create `<username>` and `<username>-*` namespaces only.
- A user may grant others access only in their prefixed namespaces, not their personal namespace.
- Grant read-only access with a RoleBinding to the built-in `view` ClusterRole.
- Grant editor/admin access with a RoleBinding to the built-in `admin` ClusterRole.
- Do not create cluster-scoped resources unless a cluster administrator explicitly approves them.

Grant `mike` read-only access to `john-website`:

```sh
kubectl create rolebinding mike-view \
  --namespace john-website \
  --clusterrole view \
  --user mike
```

Grant `tony` editor/admin access to `john-website`:

```sh
kubectl create rolebinding tony-admin \
  --namespace john-website \
  --clusterrole admin \
  --user tony
```

Revoke access:

```sh
kubectl delete rolebinding mike-view --namespace john-website
kubectl delete rolebinding tony-admin --namespace john-website
```

## Chart Defaults

Prefer:

- Namespaced resources only.
- Service type `ClusterIP`.
- Public HTTP/HTTPS through Kubernetes `Ingress` with `ingressClassName: traefik`.
- TLS with cert-manager annotation `cert-manager.io/cluster-issuer: letsencrypt-prod`.
- Application secrets stored in Bitwarden Secrets Manager and synced with `BitwardenSecret`.
- Resource requests and limits for long-running workloads.
- Stable, lowercase, DNS-safe names.

Avoid unless explicitly approved:

- `ClusterRole`, `ClusterRoleBinding`, CRDs, cluster-wide controllers, or webhooks.
- `NodePort`, `LoadBalancer`, `hostNetwork`, or `hostPort`.
- Privileged containers or broad Linux capabilities.
- Literal passwords, tokens, private keys, cookies, or storage credentials in chart files.
- `ReadWriteMany` claims on `hcloud-volumes`.

## Available Workload Resources

| Resource | Use |
| --- | --- |
| Traefik IngressClass `traefik` | Public HTTP/HTTPS routing through Kubernetes `Ingress`. |
| cert-manager `ClusterIssuer` `letsencrypt-prod` | Public TLS certificates for approved DNS names. |
| Bitwarden Secrets Manager operator | Syncing application secrets into namespaces with `BitwardenSecret`. |
| StorageClass `hcloud-volumes` | Small `ReadWriteOnce` persistent volumes, roughly less than `20Gi`. |
| StorageClass `rclone-csi` | Larger, growth-prone, or `ReadWriteMany` persistent volumes. |
| NetBird namespace resources | Private service access when enabled and approved. |

## Secrets

Do not commit live secret values.

Application secrets should be stored in Bitwarden Secrets Manager and synced into the namespace with `BitwardenSecret`. Each namespace that syncs Bitwarden secrets needs a namespace-local bootstrap Secret named `bw-auth-token`, created outside the chart.

Use this shape for Bitwarden-managed application secrets:

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

## Storage

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

## Validation

Before handing off a chart:

```sh
helm lint ./<chart>
helm template <release> ./<chart> --namespace <namespace>
```

Review rendered manifests for:

- All resources are namespaced to the intended namespace.
- No unexpected cluster-scoped resources are rendered.
- Secret values are referenced by name only.
- `BitwardenSecret` uses namespace-local `bw-auth-token`.
- Ingress uses `traefik` and `letsencrypt-prod`.
- PVC storage class, access mode, and size match the storage policy.
- Services stay `ClusterIP` unless otherwise approved.
- Containers have resource requests and limits.
