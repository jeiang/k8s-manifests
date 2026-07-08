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
- **Metrics are not scrapable in the currently pinned chart (`2.0.1`) — do not add a `VMServiceScrape` until this is fixed upstream.** Confirmed by diffing the chart's `templates/deployment.yaml`: released `2.0.1` hardcodes `--metrics-bind-address=127.0.0.1:8080` (loopback-only) and declares no `containerPort` at all, so the chart's own `metricsService` (`targetPort: https`) matches nothing. The `main` branch on `github.com/bitwarden/helm-charts` has already fixed this (`--metrics-bind-address=:{{ .Values.containers.manager.containerPort }}` plus a real `ports: - name: https` entry), but as of this note no chart release newer than `2.0.1` has shipped it. Adding a `VMServiceScrape` now would create a permanently-down scrape target, which trips this cluster's default `TargetDown` alert (`up == 0` for >10% of a job's targets for 10m) and would send a recurring, unactionable warning to the Discord alert channel every `repeat_interval`. Once a chart release past `2.0.1` ships the fix, bump the pinned version in `README.md`/`AGENTS.md` and add a `VMServiceScrape` (mirroring `crowdsec/crowdsec-vmservicescrape.yaml`) targeting the `https` port on `metricsService` — at that point it will actually work.

## Validation

```sh
helm template sm-operator bitwarden/sm-operator \
  --namespace sm-operator-system \
  -f ./bitwarden-sm-operator/values.yaml \
  --devel
```

