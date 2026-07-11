# github-redirect

Helm chart for a Traefik-only permanent (301) redirect from `github.jeiang.dev` to `https://github.com/jeiang`, preserving path and query (`github.jeiang.dev/foo` -> `https://github.com/jeiang/foo`).

This chart runs no workload. It only creates Traefik CRDs and a cert-manager `Certificate`.

## What This Chart Creates

- A cert-manager `Certificate` for `github.jeiang.dev` using the `letsencrypt-prod` `ClusterIssuer`.
- A Traefik `Middleware` using `redirectRegex` that permanently (301) redirects `https://github.jeiang.dev/<path>` to `https://github.com/jeiang/<path>`, preserving query strings.
- A Traefik `IngressRoute` for `github.jeiang.dev` on the `websecure` entryPoint that applies the redirect middleware and forwards to Traefik's built-in `noop@internal` service, so no backend Deployment, Service, or pod is ever created.

## Dependencies

- Helm 3 and `kubectl`.
- Traefik CRDs installed, specifically `traefik.io/v1alpha1` `Middleware` and `IngressRoute`.
- A Traefik entryPoint named `websecure`.
- cert-manager CRDs/controller installed, including `cert-manager.io/v1` `Certificate`.
- An existing `letsencrypt-prod` `ClusterIssuer`.
- DNS for `github.jeiang.dev` pointing at the Traefik load balancer.

## Install

```fish
helm lint ./github-redirect
helm template github-redirect ./github-redirect --namespace github-redirect
helm upgrade --install github-redirect ./github-redirect \
  --namespace github-redirect \
  --create-namespace
```

Point `github.jeiang.dev` at the Traefik load balancer before installing so the ACME HTTP-01 challenge can complete.

## Verify

```fish
kubectl -n github-redirect get certificate,middleware,ingressroute
curl -I https://github.jeiang.dev/foo
```

Expect a `301` response with `location: https://github.com/jeiang/foo`.

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.
