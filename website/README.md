# website

Helm chart for deploying the website container behind Traefik.

Default application image: `ghcr.io/jeiang/website:sha-6ac94e3`.

## What This Chart Creates

- 1 website replica.
- A `ClusterIP` Service exposing HTTP on port `80`.
- A Kubernetes `Ingress` for the hosts in `ingress.hosts`.
- TLS using the `website-tls` Secret.
- A Traefik `Middleware` that permanently redirects HTTP to HTTPS.
- Optional cert-manager `ClusterIssuer` creation.
- Resource limits of `250m` CPU and `128Mi` memory.

## Dependencies

- Helm 3 and `kubectl`.
- Traefik installed with an IngressClass named `traefik`.
- Traefik CRDs installed, specifically `traefik.io/v1alpha1` `Middleware`.
- cert-manager CRDs and controller installed for `cert-manager.io/v1` resources and Ingress certificate annotations.
- An existing `letsencrypt-prod` `ClusterIssuer`, unless `certManager.clusterIssuer.create` is set to `true`.
- DNS records for every `ingress.hosts` entry pointing at the Traefik load balancer before enabling TLS.

## Install

```sh
helm lint ./website
helm template website ./website --namespace website
helm upgrade --install website ./website \
  --namespace website \
  --create-namespace
```

The default values expect cert-manager to use an existing `letsencrypt-prod` `ClusterIssuer`:

```yaml
certManager:
  enabled: true
  clusterIssuer:
    create: false
    name: letsencrypt-prod
```

If the cluster does not already have that issuer, either create it separately or set `certManager.clusterIssuer.create: true` and confirm the email, ACME server, and Traefik ingress class are correct.

Update `ingress.hosts` before installing if the website should serve different domains.
