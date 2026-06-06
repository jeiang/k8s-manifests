# netbird

Helm chart for running a self-hosted NetBird management server on k3s.

Default application version: `v0.71.4`.

By default this chart creates:

- A NetBird management/signal server using `netbirdio/netbird-server:0.71.4`.
- A NetBird dashboard using `netbirdio/dashboard:v2.38.1`.
- 2 external relay replicas using `netbirdio/relay:0.71.4`.
- A `LoadBalancer` Service exposing STUN on UDP port `3478`.
- Traefik `IngressRoute` resources for HTTP, WebSocket, relay, and gRPC traffic at `https://netbird.jeiang.dev`.
- A cert-manager `Certificate` using the `letsencrypt-prod` `ClusterIssuer`.
- A PersistentVolumeClaim for NetBird server state.

The chart expects a pre-created `netbird-secrets` Secret. Keep these values stable after the first install:

- `store-encryption-key`: base64-encoded 32-byte key for encrypting sensitive management data.
- `relay-auth-secret`: shared secret between the management server and relay pods.
- `idp-session-cookie-encryption-key`: embedded IdP session cookie encryption key.

Generate and create the Secret:

```fish
set NETBIRD_STORE_ENCRYPTION_KEY (openssl rand -base64 32)
set NETBIRD_RELAY_AUTH_SECRET (openssl rand -hex 32)
set NETBIRD_IDP_SESSION_COOKIE_ENCRYPTION_KEY (openssl rand -hex 32)

kubectl create namespace netbird --dry-run=client -o yaml | kubectl apply -f -

kubectl -n netbird create secret generic netbird-secrets \
  --from-literal=store-encryption-key="$NETBIRD_STORE_ENCRYPTION_KEY" \
  --from-literal=relay-auth-secret="$NETBIRD_RELAY_AUTH_SECRET" \
  --from-literal=idp-session-cookie-encryption-key="$NETBIRD_IDP_SESSION_COOKIE_ENCRYPTION_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Install it with:

```sh
helm upgrade --install netbird ./netbird \
  --namespace netbird \
  --create-namespace
```

Before installing, make sure `netbird.jeiang.dev` points at the Traefik load balancer and UDP `3478` reaches the relay STUN `LoadBalancer` Service. HTTP reverse proxies cannot proxy STUN traffic, so UDP `3478` must be reachable directly.

After installation, open `https://netbird.jeiang.dev` and complete NetBird's first-load owner setup.
