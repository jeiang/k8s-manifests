# Cluster Setup Instructions

Use these steps to authenticate to the cluster, create your namespaces, and manage access to your project namespaces.

## Prerequisites

Install these tools before continuing:

- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- [`krew`](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)
- [`kubectl oidc-login`](https://github.com/int128/kubelogin)

You also need:

- A browser for Pocket ID login.
- The Kubernetes API server URL from the cluster operator.
- The Kubernetes cluster CA data or CA certificate file from the cluster operator.
- The Kubernetes OIDC client ID: `44213aa3-11eb-401d-922c-c7f81c3a9e37`. The client is public and uses PKCE, so no client secret is required.

## Create A kubeconfig

Create a kubeconfig using the Pocket ID OIDC exec login. The full template and OS-specific commands are in [`AUTHENTICATION.md`](./AUTHENTICATION.md).

After creating `pocket-id.kubeconfig`, log in:

macOS/Linux:

```sh
KUBECONFIG=./pocket-id.kubeconfig kubectl auth whoami
```

Windows PowerShell:

```powershell
$env:KUBECONFIG = ".\pocket-id.kubeconfig"
kubectl auth whoami
```

The first run opens a browser. Sign in with Pocket ID.

Expected normal user output includes your username and `kubernetes-access`:

```text
Username   john
Groups     [kubernetes-access ... system:authenticated]
```

Cluster admins should see `kubernetes-admin`.

## First Steps

Create your personal namespace. For user `john`:

```sh
kubectl create namespace john
```

Create project namespaces with your username prefix:

```sh
kubectl create namespace john-website
```

Kyverno automatically creates an owner admin RoleBinding in allowed namespaces.

## Permissions

- Users in `kubernetes-access` can create their personal namespace and namespaces prefixed with their username.
- User `john` can create `john` and `john-*`.
- User `mike` can create `mike` and `mike-*`.
- User `tony` can create `tony` and `tony-*`.
- Users in `kubernetes-admin` are cluster admins.
- You can grant others read-only or editor/admin access to your prefixed namespaces.
- You cannot grant others access to your personal namespace through self-service.

## Grant Access

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

Use `view` for read-only access and `admin` for editor/admin access inside that namespace.

## Revoke Access

Delete the RoleBinding you created:

```sh
kubectl delete rolebinding mike-view --namespace john-website
kubectl delete rolebinding tony-admin --namespace john-website
```

## Basic Workload Rules

- Deploy workloads only into namespaces you own or have been granted access to.
- Keep Services as `ClusterIP` unless a cluster administrator approves otherwise.
- Use Traefik `Ingress` for public HTTP/HTTPS when approved.
- Use cert-manager `letsencrypt-prod` for public TLS.
- Store application secrets in Bitwarden Secrets Manager; do not commit literal secret values.
- Use `hcloud-volumes` for small `ReadWriteOnce` volumes.
- Use `rclone-csi` for larger, growth-prone, or `ReadWriteMany` volumes.
- Do not create cluster-scoped resources such as `ClusterRole`, `ClusterRoleBinding`, CRDs, or controllers unless a cluster administrator explicitly approves them.

## Useful Checks

Check who Kubernetes sees:

```sh
kubectl auth whoami
```

Check namespace creation:

```sh
kubectl auth can-i create namespaces
```

Check access in a namespace:

```sh
kubectl auth can-i get pods --namespace john-website
kubectl auth can-i create deployments --namespace john-website
```

## Troubleshooting

`Unauthorized` means Kubernetes rejected your login token. Log in again and confirm your token contains `preferred_username` and `groups`.

`Forbidden` means Kubernetes authenticated you, but RBAC did not allow the action. Check:

```sh
kubectl auth whoami
kubectl auth can-i <verb> <resource> --namespace <namespace>
```

If groups appear with a leading `-`, the cluster OIDC group prefix is wrong and must be fixed by an administrator.

If namespace creation is denied, confirm the namespace is exactly your username or starts with your username plus `-`.

If sharing access is denied, confirm the namespace is a prefixed namespace such as `john-website`, not your personal namespace `john`.
