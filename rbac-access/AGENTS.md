# Chart Guidelines

## Scope

This local Helm chart creates bootstrap RBAC and Kyverno policies for user namespace access.

## Runtime Contract

- `aidan` is bound to `cluster-admin`.
- Configured users can create their personal namespace and username-prefixed namespaces.
- Kyverno generates an owner `admin` RoleBinding named `rbac-access-owner-admin` when a user creates an allowed namespace.
- Users may delegate only `admin` or `view` RoleBindings, only in their prefixed namespaces, and only to configured User or Group subjects.
- Personal namespaces cannot be shared by non-global users.
- `gilliano` has `view` access in `kube-system` through `kube-system-reader`.

## Editing Notes

- Kyverno must exist before this chart is installed.
- Do not reintroduce static prefixed namespace RoleBinding generation.
- Keep namespace lifecycle RBAC broad enough for Kubernetes authorization and keep Kyverno policies strict enough to enforce ownership.
- Verify all subjects match exact authenticated usernames, groups, or service accounts.
- Treat new global admin subjects, kube-system subjects, delegated roles, and allowed groups as high risk.

## Validation

```sh
helm lint ./rbac-access
helm template rbac-access ./rbac-access --namespace kube-system
```

Inspect rendered `ClusterPolicy`, `ClusterRoleBinding`, and kube-system `RoleBinding` resources carefully.
