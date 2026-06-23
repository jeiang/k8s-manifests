# Chart Guidelines

## Scope

This directory contains values for the upstream `bitwarden/sm-operator` Helm chart. It does not own templates, helpers, CRDs, or chart metadata.

## Runtime Contract

- The operator syncs `BitwardenSecret` resources into Kubernetes Secrets.
- The default target is Bitwarden Cloud US.
- Machine account tokens are created as Kubernetes Secrets outside this repository.
- Consumers expect per-namespace `bw-auth-token` Secrets where chart-managed `BitwardenSecret` resources are enabled.

## Editing Notes

- Never commit Bitwarden access tokens or synced secret values.
- Keep refresh interval values within Bitwarden's supported limits.
- Changes here can affect all charts that rely on `BitwardenSecret` resources.

## Validation

```sh
helm template sm-operator bitwarden/sm-operator \
  --namespace sm-operator-system \
  -f ./bitwarden-sm-operator/values.yaml \
  --devel
```

