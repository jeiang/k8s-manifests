# Chart Guidelines

## Scope

This local Helm chart creates Pocket ID/OIDC group-based bootstrap RBAC and Kyverno policies for user namespace access.

## Runtime Contract

- `kubernetes-admin` is bound to `cluster-admin`.
- `kubernetes-access` users can create their personal namespace and username-prefixed namespaces.
- Kyverno generates an owner `admin` RoleBinding named `rbac-access-owner-admin` when an OIDC user creates an allowed namespace.
- Users may delegate only `admin` or `view` RoleBindings, only in their prefixed namespaces.
- Delegated User subjects are not validated against the IdP; delegated Group subjects must be explicitly allowed.
- Personal namespaces cannot be shared by non-admin users.
- The built-in k3s emergency identity `system:admin` / `system:masters` bypasses Kyverno restrictions.

## Editing Notes

- Kyverno and Kubernetes OIDC auth must exist before normal users can use this chart.
- Do not reintroduce chart-managed per-user certificate RBAC or kubeconfig generation.
- The `kubeconfigs/` directory holds vestigial per-user cert/key/kubeconfig files from a pre-OIDC access model; it is `.gitignore`'d (never committed) and safe to delete locally now that OIDC via Pocket ID is the only supported user auth path.
- Keep namespace lifecycle RBAC broad enough for Kubernetes authorization and keep Kyverno policies strict enough to enforce ownership.
- Verify all group subjects match exact Pocket ID group names emitted in the Kubernetes OIDC groups claim.
- Treat new global admin subjects, break-glass subjects, kube-system subjects, delegated roles, and allowed groups as high risk.

## Validation

```sh
helm lint ./rbac-access
helm template rbac-access ./rbac-access --namespace kube-system
```

Inspect rendered `ClusterPolicy`, `ClusterRoleBinding`, and kube-system `RoleBinding` resources carefully.
