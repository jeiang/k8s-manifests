# rbac-access

Helm chart for user access bootstrap RBAC plus Kyverno-enforced namespace ownership.

## What This Chart Creates

- `aidan` as a cluster-wide global admin.
- Configured namespace users: `saeed`, `noel`, `gilliano`, and `anari`.
- A namespace lifecycle ClusterRoleBinding that lets configured users create and delete Namespace objects.
- Kyverno `ClusterPolicy` resources that restrict namespace lifecycle operations to each user's personal namespace or username-prefixed namespaces.
- Kyverno generation of `rbac-access-owner-admin` RoleBindings when users create allowed namespaces.
- Delegated RoleBinding validation so namespace owners can grant configured users or groups `admin` or `view` only in their prefixed namespaces.
- `kube-system-admin` and `kube-system-reader` RoleBindings in `kube-system`; `gilliano` is a kube-system reader.

This chart no longer creates a shared namespace or static namespace admin RoleBindings.

## Dependencies

- Helm 3 and `kubectl`.
- Kyverno installed before applying this chart.
- The installer must have permission to create `ClusterRole`, `ClusterRoleBinding`, `RoleBinding`, and Kyverno `ClusterPolicy` resources.
- The built-in `cluster-admin`, `admin`, and `view` ClusterRoles must exist.
- Values under `users`, `globalAdmins`, and `kubeSystem` must match identities recognized by cluster authentication.

## Install

```fish
helm lint ./rbac-access
helm template rbac-access ./rbac-access --namespace kube-system
helm upgrade --install rbac-access ./rbac-access \
  --namespace kube-system
```

## Verify

```fish
kubectl get clusterpolicy -l app.kubernetes.io/instance=rbac-access
kubectl get clusterrolebinding rbac-access-global-admins rbac-access-namespace-lifecycle
kubectl get rolebinding kube-system-admin kube-system-reader --namespace kube-system
```

After generating user credentials, verify behavior with impersonation or the generated kubeconfigs:

```fish
kubectl auth can-i create namespaces --as saeed
kubectl auth can-i get pods --namespace kube-system --as gilliano
kubectl auth can-i create pods --namespace kube-system --as gilliano
```

Kyverno admission should allow `saeed` to create `saeed` and `saeed-website`, deny `noel-website`, allow deletion of `saeed-website`, and deny deletion of `saeed`.

## Access Model

Each configured user can create their personal namespace, named exactly like their username, and namespaces prefixed by their username plus `namespaceLifecycle.prefixSeparator`.

Examples:

- `saeed`
- `saeed-website`
- `anari`
- `anari-lab`

When a user creates an allowed namespace, Kyverno generates a RoleBinding named `rbac-access-owner-admin` that grants that user the built-in `admin` ClusterRole in the namespace.

Users may delegate access only from prefixed namespaces, not from their personal namespace. Delegation is done with normal Kubernetes RoleBindings and is limited to configured User or Group subjects and the built-in `admin` or `view` ClusterRoles.

Emergency access uses the k3s admin kubeconfig.

## Credentials

See [`CREDENTIALS.md`](./CREDENTIALS.md) for temporary client-certificate kubeconfig generation. This is expected to be replaced later by an IdP-backed authentication flow.

## Values

See [`VALUES.md`](./VALUES.md) for defaults and operational notes.
