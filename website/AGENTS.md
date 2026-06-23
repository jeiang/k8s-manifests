# Chart Guidelines

## Scope

This local Helm chart deploys the static website container, service, ingress, HTTPS redirect middleware, and optional cert-manager `ClusterIssuer`.

## Runtime Contract

- Public hosts are configured in `ingress.hosts`.
- Traefik is the expected IngressClass.
- TLS uses `website-tls` and the existing `letsencrypt-prod` `ClusterIssuer` by default.
- The Service is `ClusterIP`; public traffic comes through Traefik.

## Editing Notes

- Keep image tag changes explicit and reviewable.
- Do not enable `certManager.clusterIssuer.create` without checking ACME email, server, and ingress class.
- Update DNS before adding public hosts.

## Validation

```sh
helm lint ./website
helm template test ./website --namespace website
```

