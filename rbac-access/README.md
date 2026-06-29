# rbac-access

Helm chart for Pocket ID/OIDC group-based Kubernetes access plus Kyverno-enforced namespace ownership.

## What This Chart Creates

- `kubernetes-admin` as the cluster-wide admin group.
- `kubernetes-access` as the normal user group that can self-manage owned namespaces.
- Optional `kubernetes-kube-system-admin` and `kubernetes-kube-system-reader` access in `kube-system`.
- Kyverno `ClusterPolicy` resources that restrict normal users to their personal namespace or username-prefixed namespaces.
- Kyverno generation of `rbac-access-owner-admin` RoleBindings when OIDC users create allowed namespaces.
- Delegated RoleBinding validation so namespace owners can grant configured roles to User subjects, and only explicitly allowed Group subjects, in their prefixed namespaces.

This chart does not create per-user certificate RBAC. The only intended non-OIDC access path is the emergency k3s admin kubeconfig.

## Dependencies

- Helm 3 and `kubectl`.
- Kyverno installed before applying this chart.
- Pocket ID configured as a Kubernetes OIDC issuer.
- The Kubernetes API server must map the OIDC username claim to the Pocket ID username, for example `saeed`.
- The Kubernetes API server must map the OIDC groups claim to Pocket ID group names.
- The API server must not prefix OIDC groups; use `oidc-groups-prefix=` so RBAC sees `kubernetes-admin`, not `-kubernetes-admin`.
- The built-in `cluster-admin`, `admin`, and `view` ClusterRoles must exist.

## Required IdP Groups

Create these groups in LLDAP/Pocket ID:

- `kubernetes-access`: normal Kubernetes users.
- `kubernetes-admin`: global cluster admins.
- `kubernetes-kube-system-reader`: read-only `kube-system` access, if needed.
- `kubernetes-kube-system-admin`: scoped admin access to `kube-system`, if needed.

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

Check rendered RBAC does not grant chart-managed access to individual users:

```fish
helm template rbac-access ./rbac-access --namespace kube-system
```

After OIDC is configured, verify:

```fish
kubectl auth whoami
kubectl auth can-i create namespaces
kubectl auth can-i get pods --namespace kube-system
```

Kyverno admission should allow OIDC user `saeed` in `kubernetes-access` to create `saeed` and `saeed-website`, deny `noel-website`, allow deletion of `saeed-website`, and deny deletion of `saeed`.

## Access Model

Each OIDC user in `kubernetes-access` can create their personal namespace, named exactly like their Kubernetes username, and namespaces prefixed by their username plus `namespaceLifecycle.prefixSeparator`.

Examples:

- `saeed`
- `saeed-website`
- `anari`
- `anari-lab`

When a user creates an allowed namespace, Kyverno generates a RoleBinding named `rbac-access-owner-admin` that grants that user the built-in `admin` ClusterRole in the namespace.

Users may delegate access only from prefixed namespaces, not from their personal namespace. Delegation is done with normal Kubernetes RoleBindings. User subjects are allowed without IdP lookup; Group subjects must be listed under `delegation.allowedGroups`.

Emergency access uses the built-in k3s admin kubeconfig, normally authenticated as `system:admin` in `system:masters`.

See [`../AUTHENTICATION.md`](../AUTHENTICATION.md) for workstation kubeconfig setup.

## Migration Notes

- Stop generating per-user client certificate kubeconfigs.
- Revoke or delete previously generated user kubeconfig files outside this repository.
- Apply this chart to remove chart-managed per-user certificate RBAC grants.
- This chart does not disable Kubernetes client certificate authentication globally. Disabling client-cert authentication for all non-k3s users is a k3s/API-server configuration task outside this chart.

## Values

See [`VALUES.md`](./VALUES.md) for defaults and operational notes.
