# Chart Guidelines

## Scope

This local Helm chart deploys the bill splitter website container, service, ingress, HTTPS redirect middleware, and optional cert-manager `ClusterIssuer`.

## Runtime Contract

- Public hosts are configured in `ingress.hosts`.
- Traefik is the expected IngressClass.
- TLS uses `bill-splitter-tls` and the existing `letsencrypt-prod` `ClusterIssuer` by default.
- The Service is `ClusterIP`; public traffic comes through Traefik.
- The container is expected to serve HTTP on port `80`.

## Editing Notes

- Keep image tag changes explicit and reviewable.
- Do not enable `certManager.clusterIssuer.create` without checking ACME email, server, and ingress class.
- Update DNS before adding public hosts.

## Validation

```sh
helm lint ./bill-splitter
helm template bill-splitter ./bill-splitter --namespace bill-splitter
```
