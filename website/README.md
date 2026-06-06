# website

Helm chart for deploying the website container behind Traefik.

By default this chart creates:

- 1 website replica running `ghcr.io/jeiang/website:sha-6ac94e3`.
- A `ClusterIP` Service exposing HTTP on port `80`.
- An Ingress for `pinard.co.tt` using the `traefik` ingress class.
- TLS using the `website-tls` Secret.
- A Traefik `Middleware` that permanently redirects HTTP to HTTPS.

Install it with:

```sh
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

If the cluster does not already have that issuer, either create it separately or set `certManager.clusterIssuer.create: true` and confirm the email, ACME server, and Traefik ingress class are correct for the cluster.

Update `ingress.hosts` before installing if the website should serve additional domains:

```yaml
ingress:
  hosts:
    - pinard.co.tt
```

Make sure every host points at the Traefik load balancer before enabling TLS, otherwise ACME HTTP-01 validation will fail.
