# Chart Guidelines

## Scope

This local Helm chart owns shared NetBird operator resources: the API token sync object, the shared `NetworkRouter`, and optional standalone `NetworkResource` objects. Workload-specific NetBird exposure should normally live in the workload chart through this chart as a subchart.

## Runtime Contract

- The shared router is named `k8s` in the `netbird` namespace.
- The NetBird DNS zone is `k8s.jeiang.vpn` and must already exist in NetBird.
- The NetBird operator API key Secret is `netbird-mgmt-api-key` with key `NB_API_KEY`.
- `networkResources.enabled` is disabled by default so this chart does not create workload resources unless explicitly configured.
- `operator-values.yaml` is the value override for the upstream NetBird operator chart.

## Editing Notes

- Keep shared router settings here; do not duplicate them in workload charts except as references.
- If the chart version changes, update local dependency versions in workload charts that consume it.
- Do not commit the NetBird API token.

## Validation

```sh
helm lint ./netbird-resources
helm template test ./netbird-resources --namespace netbird
```

