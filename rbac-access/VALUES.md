# rbac-access Values

These values configure the local RBAC and Kyverno access-control chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `globalAdmins.create` | `true` | Creates the global admin ClusterRoleBinding. |
| `globalAdmins.clusterRole` | `cluster-admin` | ClusterRole granted to global admin subjects. |
| `globalAdmins.subjects` | User `aidan` | Subjects that bypass namespace ownership restrictions. |
| `users` | `saeed`, `noel`, `gilliano`, `anari` | Users allowed to self-manage personal and prefixed namespaces. |
| `users[].groups` | `[]` | Certificate groups encoded when generating temporary credentials. |
| `users[].subjects` | User subject matching `users[].name` | Subjects granted namespace lifecycle RBAC. |
| `delegation.allowedGroups` | `[]` | Group subjects users may grant `admin` or `view` in prefixed namespaces. |
| `delegation.allowedClusterRoles` | `admin`, `view` | ClusterRoles users may delegate with RoleBindings. |
| `namespaceLifecycle.create` | `true` | Creates namespace lifecycle ClusterRole and binding. |
| `namespaceLifecycle.clusterRoleName` | `namespace-lifecycle` | Suffix for the lifecycle ClusterRole and ClusterRoleBinding. |
| `namespaceLifecycle.allowDeletePrefixed` | `true` | Allows users to delete their own prefixed namespaces. |
| `namespaceLifecycle.prefixSeparator` | `-` | Separator between username and namespace suffix. |
| `kubeSystem.admin.create` | `true` | Creates `kube-system-admin` RoleBinding in `kube-system`. |
| `kubeSystem.admin.clusterRole` | `admin` | ClusterRole used by `kube-system-admin`. |
| `kubeSystem.admin.subjects` | User `aidan` | Subjects with admin access to `kube-system`. |
| `kubeSystem.reader.create` | `true` | Creates `kube-system-reader` RoleBinding in `kube-system`. |
| `kubeSystem.reader.clusterRole` | `view` | ClusterRole used by `kube-system-reader`. |
| `kubeSystem.reader.subjects` | User `gilliano` | Subjects with read-only access to `kube-system`. |
| `kyverno.policies.create` | `true` | Creates Kyverno ClusterPolicies. |
| `kyverno.policies.failureAction` | `Enforce` | Kyverno validation failure action. |
| `kyverno.backgroundController.createClusterRoleBindings` | `true` | Grants Kyverno background controller permission to manage generated RoleBindings. |
| `kyverno.backgroundController.subjects` | `kyverno/kyverno-background-controller` | Kyverno background controller service accounts. |
| `credentials.renderUserList` | `false` | Internal switch used by `generate_kubeconfigs.fish`; do not enable for normal installs. |

## Notes

- Kyverno must be installed before this chart is applied.
- The chart intentionally does not create personal namespaces. Users create their own namespaces so Kyverno can generate owner RoleBindings for the authenticated username.
- Users can delegate access only in prefixed namespaces such as `saeed-website`, not in personal namespaces such as `saeed`.
- Add groups to `delegation.allowedGroups` before users may grant RoleBindings to those groups.
- Treat changes to `globalAdmins.subjects`, delegated roles, and kube-system subjects as high risk.
