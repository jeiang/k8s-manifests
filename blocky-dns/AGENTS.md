# Chart Guidelines

## Scope

This local Helm chart deploys Blocky as an internal DNS resolver. It owns the Deployment, ConfigMap, Service, HPA, and optional NetBird `NetworkResource` subchart values.

## Runtime Contract

- The Kubernetes Service is `ClusterIP` and exposes DNS on TCP and UDP port `53`.
- The HPA is enabled by default and requires metrics-server or another metrics provider.
- Remote blocklists require outbound HTTPS from the pod.
- The NetBird integration is enabled by default (`netbird.enabled=true`) and requires the shared `NetworkRouter/k8s` in the `netbird` namespace to already exist; set `netbird.enabled=false` to opt out.
- When NetBird is enabled, the local dependency alias is `netbird` and it should render only workload-specific `NetworkResource` objects.

## Editing Notes

- Run `helm dependency build ./blocky-dns` after changing dependency metadata or before rendering with `netbird.enabled=true`.
- Keep Blocky config in `values.yaml` as a literal block unless templating is intentionally added.
- Do not expose DNS publicly from this chart unless the public access model is deliberately changed.

## Validation

```sh
helm lint ./blocky-dns
helm template test ./blocky-dns --namespace dns
helm template test ./blocky-dns --namespace dns --set netbird.enabled=true
```

