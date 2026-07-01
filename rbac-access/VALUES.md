# rbac-access Values

These values configure the local OIDC RBAC and Kyverno access-control chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `globalAdmins.create` | `true` | Creates the global admin ClusterRoleBinding. |
| `globalAdmins.clusterRole` | `cluster-admin` | ClusterRole granted to global admin subjects. |
| `globalAdmins.subjects` | Group `kubernetes-admin` | OIDC subjects with full cluster access and Kyverno bypass. |
| `breakGlass.subjects` | User `system:admin`, User `system:kube-controller-manager`, User `system:serviceaccount:kube-system:namespace-controller`, Group `system:masters` | Built-in k3s emergency and Kubernetes namespace cleanup subjects that bypass Kyverno restrictions. |
| `oidc.groups.access` | `kubernetes-access` | Required group for normal namespace self-service and delegation. |
| `oidc.groups.admin` | `kubernetes-admin` | Documented admin group name; rendered through `globalAdmins.subjects`. |
| `oidc.groups.kubeSystemAdmin` | `kubernetes-kube-system-admin` | Documented kube-system admin group name. |
| `oidc.groups.kubeSystemReader` | `kubernetes-kube-system-reader` | Documented kube-system reader group name. |
| `delegation.allowedGroups` | `[]` | Group subjects users may grant `admin` or `view` in prefixed namespaces. |
| `delegation.allowedClusterRoles` | `admin`, `view` | ClusterRoles users may delegate with RoleBindings. |
| `namespaceLifecycle.create` | `true` | Creates namespace lifecycle ClusterRole and binding. |
| `namespaceLifecycle.clusterRoleName` | `namespace-lifecycle` | Suffix for the lifecycle ClusterRole and ClusterRoleBinding. |
| `namespaceLifecycle.allowDeletePrefixed` | `true` | Allows users to delete their own prefixed namespaces. |
| `namespaceLifecycle.prefixSeparator` | `-` | Separator between username and namespace suffix. |
| `namespaceLifecycle.subjects` | Group `kubernetes-access` | Subjects authorized by RBAC to create/delete Namespace objects. |
| `kubeSystem.admin.create` | `true` | Creates `kube-system-admin` RoleBinding in `kube-system`. |
| `kubeSystem.admin.clusterRole` | `admin` | ClusterRole used by `kube-system-admin`. |
| `kubeSystem.admin.subjects` | Group `kubernetes-kube-system-admin` | Subjects with admin access to `kube-system`. |
| `kubeSystem.reader.create` | `true` | Creates `kube-system-reader` RoleBinding in `kube-system`. |
| `kubeSystem.reader.clusterRole` | `view` | ClusterRole used by `kube-system-reader`. |
| `kubeSystem.reader.subjects` | Group `kubernetes-kube-system-reader` | Subjects with read-only access to `kube-system`. |
| `kyverno.policies.create` | `true` | Creates Kyverno ClusterPolicies. |
| `kyverno.policies.failureAction` | `Enforce` | Kyverno validation failure action. |
| `kyverno.backgroundController.createClusterRoleBindings` | `true` | Grants Kyverno background controller permission to manage generated RoleBindings and bind the built-in `admin` ClusterRole. |
| `kyverno.backgroundController.subjects` | `kyverno/kyverno-background-controller` | Kyverno background controller service accounts. |

## Notes

- Kyverno and Pocket ID/OIDC API server authentication must be configured before normal users can use this chart.
- The API server must use `oidc-groups-prefix=` so group names match these RBAC subjects exactly.
- The chart intentionally does not create personal namespaces. Users create their own namespaces so Kyverno can generate owner RoleBindings for the authenticated OIDC username.
- Users can delegate access only in prefixed namespaces such as `saeed-website`, not in personal namespaces such as `saeed`.
- User subjects in delegated RoleBindings are not validated against Pocket ID. Group subjects must be listed in `delegation.allowedGroups`.
- The chart removes chart-managed certificate user access, but does not disable client-certificate authentication at the k3s API server.
- Treat changes to `globalAdmins.subjects`, `breakGlass.subjects`, delegated roles, and kube-system subjects as high risk.
