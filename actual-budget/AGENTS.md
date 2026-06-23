# Chart Guidelines

## Scope

This directory contains values for the upstream `community-charts/actualbudget` Helm chart. It does not own templates, helpers, or chart metadata.

## Runtime Contract

- Actual Budget is exposed through Traefik at `budget.jeiang.dev`.
- TLS uses the existing `letsencrypt-prod` `ClusterIssuer`.
- The service stays `ClusterIP`; public access is through ingress only.
- Persistence uses the `rclone-csi` StorageClass with `ReadWriteMany`.
- The pod runs as UID/GID `1000` to match the rclone CSI mount options.
- The init container creates `/data/server-files` and `/data/user-files` on empty rclone volumes before the app starts.

## Editing Notes

- Keep overrides compatible with the upstream chart's values schema.
- Do not add Kubernetes Secret values to this directory.
- Keep the persistent storage default on `rclone-csi`; do not inline rclone credentials in this values file. Treat RWX safety as backend-dependent.

## Validation

```sh
helm template actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  -f ./actual-budget/values.yaml
```
