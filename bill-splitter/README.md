# bill-splitter

Helm chart for deploying the bill splitter website behind Traefik.

Default application image: `ghcr.io/jeiang/bill-splitter:ba481839c2eb24aa1079e902827121dc81d2936f` (pinned to an immutable build sha, not `latest`).

## What This Chart Creates

- 1 bill splitter replica.
- A `ClusterIP` Service exposing HTTP on port `80`.
- A Kubernetes `Ingress` for `bill-split.jeiang.dev`.
- TLS using the `bill-splitter-tls` Secret.
- A Traefik `Middleware` that permanently redirects HTTP to HTTPS.
- Optional cert-manager `ClusterIssuer` creation.
- Resource requests of `25m` CPU and `32Mi` memory.
- Resource limits of `100m` CPU and `128Mi` memory.

## Dependencies

- Helm 3 and `kubectl`.
- Traefik installed with an IngressClass named `traefik`.
- Traefik CRDs installed, specifically `traefik.io/v1alpha1` `Middleware`.
- cert-manager CRDs and controller installed for `cert-manager.io/v1` resources and Ingress certificate annotations.
- An existing `letsencrypt-prod` `ClusterIssuer`, unless `certManager.clusterIssuer.create` is set to `true`.
- DNS for `bill-split.jeiang.dev` pointing at the Traefik load balancer before enabling TLS.

## Install

```sh
helm lint ./bill-splitter
helm template bill-splitter ./bill-splitter --namespace bill-splitter
helm upgrade --install bill-splitter ./bill-splitter \
  --namespace bill-splitter \
  --create-namespace
```

## Verify

```sh
kubectl -n bill-splitter get deploy,pods,svc,ingress
kubectl -n bill-splitter rollout status deployment/bill-splitter --timeout=5m
kubectl -n bill-splitter get secret bill-splitter-tls
```

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.

The default values expect cert-manager to use an existing `letsencrypt-prod` `ClusterIssuer`:

```yaml
certManager:
  enabled: true
  clusterIssuer:
    create: false
    name: letsencrypt-prod
```

Update `ingress.hosts` before installing if the website should serve different domains.
