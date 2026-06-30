# Chart Guidelines

## Scope

This directory contains values and support manifests for the upstream `victoria-metrics-k8s-stack` Helm chart. It does not own the upstream stack templates.

## Runtime Contract

- The chart is installed as release `monitoring` into the `monitoring` namespace.
- Grafana is public at `grafana.jeiang.dev` through Traefik and cert-manager.
- Grafana authenticates through Pocket ID using the OIDC client ID `a70e6d0d-360c-415f-b154-85ec7a6bc352`.
- Grafana OAuth roles come from Pocket ID groups: `monitoring_admin`, `monitoring_editor`, and `monitoring_reader`.
- The `grafana-oauth` Secret is expected to be synced by Bitwarden Secrets Manager from `grafana-oauth-bitwardensecret.yaml`.
- VictoriaMetrics and VictoriaLogs raw HTTP endpoints must not be exposed through public ingress. Expose them through NetBird resources in a later change.
- VMSingle and VLSingle use the RWO-only `hcloud-volumes` StorageClass.

## Editing Notes

- Do not commit the Grafana OAuth client secret.
- Keep the Grafana OAuth callback aligned with Pocket ID: `https://grafana.jeiang.dev/login/generic_oauth`.
- Keep `vmsingle.ingress`, `vlsingle.ingress`, and `vlagent.ingress` disabled unless an explicit access-control design is added.
- Do not add NetBird `NetworkResource` manifests here until the deferred NetBird exposure work is implemented.

## Validation

```sh
helm template monitoring vm/victoria-metrics-k8s-stack \
  --namespace monitoring \
  -f ./monitoring/values.yaml

kubectl apply --dry-run=client -f ./monitoring/grafana-oauth-bitwardensecret.yaml
```
