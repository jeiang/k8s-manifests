# netbird

Helm chart for running a self-hosted NetBird management server on k3s.

Default images:

- `netbirdio/netbird-server:0.72.1`
- `netbirdio/dashboard:v2.39.0`
- `netbirdio/relay:0.72.1`

## What This Chart Creates

- 1 NetBird management/signal server.
- 1 NetBird dashboard.
- 2 external relay replicas.
- A `LoadBalancer` Service exposing STUN on UDP port `3478`.
- Traefik `IngressRoute` resources for HTTP, WebSocket, relay, and gRPC traffic at `https://netbird.jeiang.dev`.
- A cert-manager `Certificate` using the `letsencrypt-prod` `ClusterIssuer`.
- A PersistentVolumeClaim for NetBird server state.
- Resource limits for server, dashboard, and relay pods.

## Dependencies

- Helm 3, `kubectl`, and `openssl` for secret generation.
- Traefik CRDs installed, specifically `traefik.io/v1alpha1` `IngressRoute`.
- A Traefik entryPoint named `websecure`.
- cert-manager CRDs/controller installed, including `cert-manager.io/v1` `Certificate`.
- An existing `letsencrypt-prod` `ClusterIssuer`.
- DNS for `netbird.jeiang.dev` pointing at the Traefik load balancer.
- A load balancer path for UDP `3478` to the relay STUN Service.
- A default storage class or `persistence.storageClassName` set for the server PVC.
- A pre-created `netbird-secrets` Secret with the keys listed below.

## Generate Secrets

The chart expects a pre-created `netbird-secrets` Secret. Keep these values stable after the first install:

- `store-encryption-key`: base64-encoded 32-byte key for encrypting sensitive management data.
- `relay-auth-secret`: shared secret between the management server and relay pods.
- `idp-session-cookie-encryption-key`: 32-character hex embedded IdP session cookie encryption key.

Generate and create the Secret:

```fish
set NETBIRD_STORE_ENCRYPTION_KEY (openssl rand -base64 32)
set NETBIRD_RELAY_AUTH_SECRET (openssl rand -hex 32)
set NETBIRD_IDP_SESSION_COOKIE_ENCRYPTION_KEY (openssl rand -hex 16)

kubectl create namespace netbird --dry-run=client -o yaml | kubectl apply -f -

kubectl -n netbird create secret generic netbird-secrets \
  --from-literal=store-encryption-key="$NETBIRD_STORE_ENCRYPTION_KEY" \
  --from-literal=relay-auth-secret="$NETBIRD_RELAY_AUTH_SECRET" \
  --from-literal=idp-session-cookie-encryption-key="$NETBIRD_IDP_SESSION_COOKIE_ENCRYPTION_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Install

```sh
helm lint ./netbird
helm template netbird ./netbird --namespace netbird
helm upgrade --install netbird ./netbird \
  --namespace netbird \
  --create-namespace
```

Before installing, make sure `netbird.jeiang.dev` points at the Traefik load balancer and UDP `3478` reaches the relay STUN `LoadBalancer` Service. HTTP reverse proxies cannot proxy STUN traffic, so UDP `3478` must be reachable directly.

After installation, open `https://netbird.jeiang.dev` and complete NetBird's first-load owner setup.
