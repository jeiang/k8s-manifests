# hath Values

These values configure the local `hath-rust` Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `1` | Runs one Hath pod. |
| `image.repository` | `ghcr.io/james58899/hath-rust` | Hath image repository. |
| `image.tag` | `latest` | Hath image tag. |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy. |
| `hath.port` | `8888` | Application listening port. |
| `hath.cacheDir` | `/hath/cache` | Persistent cache directory. |
| `hath.dataDir` | `/hath/data` | Persistent data directory. |
| `hath.downloadDir` | `/hath/download` | Persistent download directory. |
| `hath.logDir` | `/hath/log` | Persistent log directory. |
| `hath.tempDir` | `/tmp/hath` | Ephemeral temp directory. |
| `hath.disableLogging` | `false` | Keeps logging enabled. |
| `hath.flushLog` | `false` | Leaves log flushing disabled. |
| `hath.maxConnection` | `0` | Uses application default connection limit. |
| `hath.disableIpOriginCheck` | `true` | Disables IP origin checks. |
| `hath.disableFloodControl` | `false` | Keeps flood control enabled. |
| `hath.proxy` | `""` | No upstream proxy. |
| `hath.forceBackgroundScan` | `false` | Does not force background scan. |
| `hath.quiet` | `0` | Normal application verbosity. |
| `hath.rpcServerIp` | `""` | Uses application default RPC bind behavior. |
| `hath.enableMetrics` | `true` | Enables metrics endpoint. |
| `hath.sniStrict` | `false` | Disables strict SNI checks. |
| `hath.enableH3` | `false` | Disables HTTP/3 by default. |
| `hath.extraArgs` | `[]` | Optional extra application arguments. |
| `hostPort.enabled` | `true` | Exposes the pod on the node network. |
| `hostPort.port` | `8888` | Node TCP port for public H@H traffic. |
| `hostPort.hostIP` | `""` | Binds all host IPs. |
| `service.type` | `ClusterIP` | Keeps service internal. |
| `service.annotations` | `{}` | Optional Service annotations. |
| `service.port` | `8888` | Internal service port. |
| `persistence.enabled` | `true` | Creates persistent storage. |
| `persistence.annotations` | `{}` | Optional PVC annotations. |
| `persistence.existingClaim` | `""` | Creates a PVC instead of using an existing one. |
| `persistence.storageClassName` | `rclone-csi` | Uses rclone-backed storage. |
| `persistence.accessModes` | `ReadWriteMany` | Requests RWX access. |
| `persistence.size` | `15Gi` | Requested persistent volume size. |
| `persistence.mountPath` | `/hath` | Persistent volume mount path. |
| `temp.sizeLimit` | `""` | Uses default `emptyDir` size behavior. |
| `resources.requests` | `cpu: 100m`, `memory: 256Mi` | Baseline scheduling request. |
| `resources.limits` | `cpu: "1"`, `memory: 1Gi` | Runtime resource cap. |
| `podSecurityContext` | `fsGroup: 1000`, `fsGroupChangePolicy: OnRootMismatch` | Matches rclone mount ownership. |
| `securityContext` | non-root UID/GID `1000`, drops all capabilities | Runs without privilege escalation. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |

## Notes

- Keep one replica while `hostPort.enabled=true` unless placement rules are added.
- Firewall rules must allow inbound TCP `8888` to the node running the pod.
