# Chart Guidelines

## Scope

This local Helm chart creates namespaces, namespace admin bindings, and cluster admin bindings for named users.

## Runtime Contract

- `aidan` is bound to `cluster-admin`.
- Namespace users receive the built-in `admin` ClusterRole only in declared namespaces.
- Namespace prefix access is generated from declared namespace values; Kubernetes RBAC does not support wildcard namespace bindings.

## Editing Notes

- Verify all subjects match exact authenticated usernames, groups, or service accounts.
- Treat new cluster-wide bindings as high risk.
- When adding prefixed namespaces, declare every concrete namespace under values so role bindings are rendered.

## Validation

```sh
helm lint ./rbac-access
helm template test ./rbac-access --namespace kube-system
```

