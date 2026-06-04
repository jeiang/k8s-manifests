# blocky-dns

Helm chart for running Blocky as a public DNS service.

By default this chart creates:

- 2 Blocky replicas.
- A `LoadBalancer` Service exposing DNS on port `53` for both UDP and TCP.
- A ConfigMap-mounted Blocky `config.yml`.
- Resource limits of `500m` CPU and `350Mi` memory.

Install it with:

```sh
helm upgrade --install blocky-dns ./blocky-dns
```

Blocky needs at least one upstream DNS server in the default upstream group. Change `blocky.config` in `values.yaml` if you want different upstreams, blocklists, allowlists, or other Blocky settings.

This chart intentionally exposes DNS publicly. Public recursive DNS resolvers can be abused if they are not protected by firewall rules, ACLs, or rate limits at your load balancer or network edge.
