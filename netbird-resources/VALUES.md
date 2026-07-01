# netbird-resources Values

These values configure shared NetBird operator resources.

## Chart Values

| Value | Default | Purpose |
| --- | --- | --- |
| `nameOverride` | `""` | Optional chart name override. |
| `fullnameOverride` | `""` | Optional full resource name override. |
| `bitwardenSecrets.netbirdApi.enabled` | `true` | Renders the `BitwardenSecret` for the NetBird API key. |
| `bitwardenSecrets.netbirdApi.namespace` | `netbird` | Namespace for the synced API key Secret. |
| `bitwardenSecrets.netbirdApi.organizationId` | `af918704-c223-4f10-a245-b4640144f2d9` | Bitwarden organization ID. |
| `bitwardenSecrets.netbirdApi.secretName` | `netbird-mgmt-api-key` | Kubernetes Secret created by the Bitwarden operator. |
| `bitwardenSecrets.netbirdApi.secretKeyName` | `NB_API_KEY` | Secret key expected by the NetBird operator. |
| `bitwardenSecrets.netbirdApi.secretId` | `1824f6b7-989d-40c1-abe5-b46500292bf7` | Bitwarden secret ID containing the NetBird API key. |
| `bitwardenSecrets.netbirdApi.authToken.secretName` | `bw-auth-token` | Namespace-local Bitwarden machine account token Secret. |
| `bitwardenSecrets.netbirdApi.authToken.secretKey` | `token` | Token key inside `bw-auth-token`. |
| `networkRouter.enabled` | `true` | Creates the shared `NetworkRouter`. |
| `networkRouter.name` | `k8s` | Router resource name. |
| `networkRouter.namespace` | `netbird` | Router namespace. |
| `networkRouter.annotations` | `{}` | Optional router annotations. |
| `networkRouter.dnsZoneRef.name` | `k8s.jeiang.vpn` | NetBird DNS zone reference. |
| `networkRouter.extraSpec` | `{}` | Optional additional router spec fields. |
| `networkResources.enabled` | `false` | Does not create standalone `NetworkResource` objects by default. |
| `networkResources.groups` | `[]` | Optional default groups for standalone network resources. |
| `networkResources.resources` | `[]` | Optional standalone network resources. |

## Operator Values

These values override the upstream `ghcr.io/netbirdio/helm-charts/netbird-operator` chart through `operator-values.yaml`.

| Value | Default | Purpose |
| --- | --- | --- |
| `managementURL` | `https://netbird.jeiang.dev` | Points the operator at the self-hosted NetBird management URL. |
| `netbirdAPI.keyFromSecret.name` | `netbird-mgmt-api-key` | Kubernetes Secret containing the NetBird API key. |
| `netbirdAPI.keyFromSecret.key` | `NB_API_KEY` | Secret key read by the operator. |
| `operator.resources.requests` | `cpu: 50m`, `memory: 64Mi` | Operator scheduling request. |
| `operator.resources.limits` | `cpu: 150m`, `memory: 128Mi` | Operator resource cap. |

## Notes

- The NetBird DNS zone must already exist before the router is useful.
- Workload-specific NetBird exposure normally belongs in workload charts, not in this shared chart.
