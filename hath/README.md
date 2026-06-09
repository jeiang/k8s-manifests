# hath

Helm chart for running `hath-rust`.

Default image: `ghcr.io/james58899/hath-rust:latest`.

## What This Chart Creates

- A single `hath-rust` Deployment.
- A `LoadBalancer` Service exposing the configured H@H port.
- A Longhorn-backed RWX persistent volume claim mounted at `/hath`.
- Persistent directories for cache, login data, downloads, and logs.
- An ephemeral `emptyDir` for temporary files at `/tmp/hath`.
- Optional metrics endpoint and HTTP/3 UDP port.

## Dependencies

- Helm 3 and `kubectl`.
- Longhorn installed with a `longhorn` StorageClass, or another storage class set with `persistence.storageClassName`.
- Longhorn RWX support available on the storage nodes.
- A cluster load balancer implementation and firewall rules that allow public access to the configured H@H port.
- Network/firewall rules appropriate for the configured H@H port.

## Install

Review and edit `values.yaml` before first install. At minimum, confirm the port and persistence size:

```fish
helm lint ./hath
helm template hath ./hath --namespace hath
```

Install or upgrade:

```fish
helm upgrade --install hath ./hath \
  --namespace hath \
  --create-namespace \
  --wait
```

## Verify

```fish
kubectl -n hath get deploy,pods,svc,pvc
kubectl -n hath rollout status deployment/hath --timeout=5m
kubectl -n hath logs deploy/hath --tail=100
```

## Values To Review

```yaml
hath:
  port: 8888
  cacheDir: /hath/cache
  dataDir: /hath/data
  downloadDir: /hath/download
  logDir: /hath/log
  tempDir: /tmp/hath
  enableMetrics: false
  enableH3: false

persistence:
  enabled: true
  storageClassName: longhorn
  accessModes:
    - ReadWriteMany
  size: 15Gi

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: "2"
    memory: 2Gi
```

Set any additional `hath-rust` options through the `hath` values or `hath.extraArgs`.
