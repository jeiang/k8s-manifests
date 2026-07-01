# Chart Guidelines

## Scope

This directory contains values and support manifests for the upstream `crowdsec/crowdsec` Helm chart. It does not own the upstream chart templates.

## Runtime Contract

- CrowdSec runs in the `crowdsec` namespace.
- LAPI stays internal at `crowdsec-service.crowdsec.svc.cluster.local:8080`.
- AppSec stays internal at `crowdsec-appsec-service.crowdsec.svc.cluster.local:7422`.
- LAPI and AppSec metrics stay internal on port `6060` and are scraped with VictoriaMetrics `VMServiceScrape`.
- Traefik WAF integration uses a bouncer key generated from CrowdSec and stored in Bitwarden Secrets Manager.
- NetBird reverse proxy IP reputation uses a separate bouncer key generated from CrowdSec and stored in Bitwarden Secrets Manager.
- Do not commit bouncer keys, CrowdSec console enrollment keys, or API credentials.

## Editing Notes

- Keep this as a values-only upstream chart directory unless a local chart is explicitly needed.
- Keep LAPI, AppSec, and metrics endpoints unexposed publicly.
- Keep `container_runtime=containerd` for k3s.
- Keep Traefik acquisition scoped to `kube-system` `traefik-*` pods unless Traefik is moved.
- If changing service labels, update `crowdsec-vmservicescrape.yaml`.
- If changing AppSec service names or ports, update the Traefik dynamic config instructions in `README.md`.

## Validation

```sh
helm template crowdsec crowdsec/crowdsec --namespace crowdsec -f ./crowdsec/values.yaml
kubectl diff --server-side -f ./crowdsec/crowdsec-vmservicescrape.yaml
kubectl diff --server-side -f ./crowdsec/traefik-crowdsec-dynamic-bitwardensecret.yaml
```
