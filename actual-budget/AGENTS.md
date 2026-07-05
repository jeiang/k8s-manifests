# Chart Guidelines

## Scope

This directory contains values for the upstream `community-charts/actualbudget` Helm chart. It does not own templates, helpers, or chart metadata.

## Runtime Contract

- Actual Budget is exposed through Traefik at `budget.jeiang.dev`.
- TLS uses the existing `letsencrypt-prod` `ClusterIssuer`.
- The service stays `ClusterIP`; public access is through ingress only.
- Persistence uses a copied `actual-budget-hcloud` PVC backed by the RWO-only `hcloud-volumes` StorageClass.
- The Deployment uses `Recreate` and one replica to avoid Hetzner volume multi-attach failures.
- The pod runs as UID/GID `1000`; copied data must remain writable by that identity.
- The init container creates `/data/server-files` and `/data/user-files` on empty volumes before the app starts.

## Editing Notes

- Keep overrides compatible with the upstream chart's values schema.
- Do not add Kubernetes Secret values to this directory.
- Existing installs must copy data into `actual-budget-hcloud` before the chart is upgraded to mount it.
- Do not add one-off migration Jobs, copy pods, or live storage credentials to this directory.

## Validation

```sh
helm template actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  -f ./actual-budget/values.yaml
```
