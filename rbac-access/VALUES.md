# rbac-access Values

These values configure the local RBAC Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `namespaces.create` | `true` | Creates namespaces declared by the chart. |
| `namespaces.additional` | `[]` | Extra concrete namespaces to create and bind. |
| `admin.create` | `true` | Creates the cluster admin binding. |
| `admin.clusterRole` | `cluster-admin` | ClusterRole granted to admin subjects. |
| `admin.subjects` | User `aidan` | Subjects bound to cluster admin. |
| `namespaceAccess.create` | `true` | Creates namespace admin bindings. |
| `namespaceAccess.clusterRole` | `admin` | ClusterRole granted inside each namespace. |
| `namespaceAccess.includeUserNamePrefix` | `true` | Adds prefixed namespaces for each declared user. |
| `namespaceAccess.userNamePrefixSeparator` | `-` | Separator used for prefixed namespaces. |
| `namespaceAccess.users` | `saeed`, `noel`, and `gilliano` | Namespace-scoped users, subjects, and namespace lists. |

## Notes

- Kubernetes RBAC does not support wildcard namespace bindings; every concrete namespace must be rendered by values.
- Treat changes to `admin.subjects` and `admin.clusterRole` as high risk.
