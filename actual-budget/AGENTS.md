# Chart Guidelines

## Scope

This directory contains values for the upstream `community-charts/actualbudget` Helm chart. It does not own templates, helpers, or chart metadata.

## Runtime Contract

- Actual Budget is exposed through Traefik at `budget.jeiang.dev`.
- TLS uses the existing `letsencrypt-prod` `ClusterIssuer`.
- The service stays `ClusterIP`; public access is through ingress only.
- Persistence uses the RWO-only `hcloud-volumes` StorageClass with `ReadWriteOnce`.

## Editing Notes

- Keep overrides compatible with the upstream chart's values schema.
- Do not add Kubernetes Secret values to this directory.
- Keep the persistent storage default on `hcloud-volumes`; do not switch to RWX semantics unless the storage backend changes.

## Validation

```sh
helm template actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  -f ./actual-budget/values.yaml
```

