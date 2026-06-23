# netbird

Helm chart for running a self-hosted NetBird management server on k3s.

Default images:

- `netbirdio/netbird-server:0.72.1`
- `netbirdio/dashboard:v2.39.0`
- `netbirdio/relay:0.72.1`

## What This Chart Creates

- 1 NetBird management/signal server.
- 1 NetBird dashboard.
- 2 external relay replicas on separate nodes.
- Direct node exposure for STUN on UDP port `3478`.
- Traefik `IngressRoute` resources for HTTP, WebSocket, relay, and gRPC traffic at `https://netbird.jeiang.dev`.
- A cert-manager `Certificate` using the `letsencrypt-prod` `ClusterIssuer`.
- A PersistentVolumeClaim for NetBird server state.
- A `BitwardenSecret` that syncs `netbird-secrets` from Bitwarden Secrets Manager.
- A `ServiceMonitor` for NetBird server metrics.
- Resource limits for server, dashboard, relay, and server init containers.

## Dependencies

- Helm 3, `kubectl`, and `openssl` for generating initial secret values.
- Traefik CRDs installed, specifically `traefik.io/v1alpha1` `IngressRoute`.
- A Traefik entryPoint named `websecure`.
- cert-manager CRDs/controller installed, including `cert-manager.io/v1` `Certificate`.
- An existing `letsencrypt-prod` `ClusterIssuer`.
- DNS for `netbird.jeiang.dev` pointing at the Traefik load balancer.
- DNS for `stun.netbird.jeiang.dev` pointing at the public IPv4 and IPv6 addresses of the two labeled STUN relay nodes.
- Hetzner firewall rules allowing inbound UDP `3478` to those two STUN relay nodes.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.
- Bitwarden Secrets Manager operator CRDs.
- A `bw-auth-token` Secret in the `netbird` namespace so the Bitwarden operator can sync `netbird-secrets`.
- Prometheus Operator CRDs installed if `metrics.serviceMonitor.enabled=true`.

## Generate Bitwarden Secrets

The chart expects `netbird-secrets` to be synced from Bitwarden Secrets Manager. Keep these values stable after the first install:

- `store-encryption-key`: base64-encoded 32-byte key for encrypting sensitive management data.
- `relay-auth-secret`: shared secret between the management server and relay pods.
- `idp-session-cookie-encryption-key`: 32-character hex embedded IdP session cookie encryption key.

Generate the values locally:

```fish
set NETBIRD_STORE_ENCRYPTION_KEY (openssl rand -base64 32)
set NETBIRD_RELAY_AUTH_SECRET (openssl rand -hex 32)
set NETBIRD_IDP_SESSION_COOKIE_ENCRYPTION_KEY (openssl rand -hex 16)

```

Store each generated value in Bitwarden Secrets Manager and put the resulting Bitwarden secret IDs in `values.yaml` under `bitwardenSecrets.secretIds`.

## Bitwarden Secrets Manager

The chart-managed `BitwardenSecret` is enabled by default. Create matching secrets in Bitwarden Secrets Manager, then set the organization ID and Bitwarden secret IDs:

```fish
helm upgrade --install netbird ./netbird \
  --namespace netbird \
  --create-namespace \
  --set bitwardenSecrets.enabled=true \
  --set bitwardenSecrets.organizationId=replace-with-organization-uuid \
  --set bitwardenSecrets.secretIds.storeEncryptionKey=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.relayAuthSecret=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.idpSessionCookieEncryptionKey=replace-with-secret-uuid
```

The Bitwarden machine-account token Secret must already exist in the `netbird` namespace:

```fish
kubectl create namespace netbird --dry-run=client -o yaml | kubectl apply -f -
kubectl -n netbird get secret bw-auth-token
```

## Install

```fish
helm lint ./netbird
helm template netbird ./netbird --namespace netbird
helm upgrade --install netbird ./netbird \
  --namespace netbird \
  --create-namespace
```

Before installing, make sure `netbird.jeiang.dev` points at the Traefik load balancer and `stun.netbird.jeiang.dev` points at the public addresses of the two nodes labeled for STUN relay placement. HTTP reverse proxies and Hetzner Cloud Load Balancers cannot proxy UDP STUN traffic, so UDP `3478` is exposed directly on the selected nodes through host networking.

Label exactly two nodes for relay placement:

```fish
kubectl label node legion-node1 netbird.io/stun=true
kubectl label node legion-node2 netbird.io/stun=true
```

The relay Deployment uses required pod anti-affinity, so the two relay replicas cannot run on the same host. If fewer than two labeled schedulable nodes are available, one relay pod will stay Pending.

After installation, open `https://netbird.jeiang.dev` and complete NetBird's first-load owner setup.

## Verify

```fish
kubectl -n netbird get deploy,pods,svc,pvc,servicemonitor
kubectl -n netbird rollout status deployment/netbird-server --timeout=5m
kubectl -n netbird rollout status deployment/netbird-dashboard --timeout=5m
kubectl -n netbird rollout status deployment/netbird-relay --timeout=5m
kubectl -n netbird get pods -l app.kubernetes.io/component=relay -o wide
```

## Values To Review

```yaml
server:
  metricsPort: 9090

relay:
  replicaCount: 2
  stunHost: stun.netbird.jeiang.dev
  stunPort: 3478
  hostNetwork:
    enabled: true
  nodeSelector:
    netbird.io/stun: "true"
  antiAffinity:
    enabled: true

metrics:
  serviceMonitor:
    enabled: true
    labels:
      release: monitoring
    interval: 30s
    path: /metrics
```
