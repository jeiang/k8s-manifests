# hath

Helm chart for running `hath-rust`.

Default image: `ghcr.io/james58899/hath-rust:latest`.

## What This Chart Creates

- A single `hath-rust` Deployment.
- A `ClusterIP` Service exposing the configured H@H port inside the cluster.
- A TCP `hostPort` on port `8888` for direct node-level exposure.
- A rclone CSI-backed persistent volume claim mounted at `/hath`.
- Persistent directories for cache, login data, downloads, and logs.
- An ephemeral `emptyDir` for temporary files at `/tmp/hath`.
- Metrics endpoint and optional HTTP/3 UDP port.
- A `ServiceMonitor` for Prometheus Operator when metrics are enabled.

## Dependencies

- Helm 3 and `kubectl`.
- rclone CSI driver installed with the `rclone-csi` StorageClass, RWX-capable backend configuration, and a working `rclone-config` Secret.
- The `rclone-csi` StorageClass mount options set UID/GID `1000`; this chart runs the Hath pod as UID/GID `1000`.
- Firewall rules allowing inbound TCP `8888` to the node running the Hath pod.
- Prometheus Operator CRDs installed if `metrics.serviceMonitor.enabled=true`.

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
kubectl -n hath get servicemonitor hath
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
  enableMetrics: true
  enableH3: false

hostPort:
  enabled: true
  port: 8888
  hostIP: ""

service:
  type: ClusterIP
  port: 8888

persistence:
  enabled: true
  storageClassName: rclone-csi
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

metrics:
  serviceMonitor:
    enabled: true
    labels:
      release: monitoring
    interval: 30s
    path: /metrics
```

Set any additional `hath-rust` options through the `hath` values or `hath.extraArgs`.
