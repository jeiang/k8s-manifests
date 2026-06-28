# rclone-csi-driver Values

These values override the upstream `oci://ghcr.io/veloxpack/charts/csi-driver-rclone` chart for this cluster.

| Value | Default | Purpose |
| --- | --- | --- |
| `driver.name` | `rclone.csi.veloxpack.io` | CSI driver name. |
| `kubeletDir` | `/var/lib/kubelet` | k3s/NixOS kubelet directory. |
| `controller.replicas` | `1` | Runs one controller replica. |
| `controller.logLevel` | `3` | Controller log verbosity. |
| `controller.resources.csiProvisioner` | `10m/20Mi` request, `400Mi` memory limit | CSI provisioner resources. |
| `controller.resources.livenessProbe` | `10m/20Mi` request, `100Mi` memory limit | Controller liveness probe resources. |
| `controller.resources.rclone` | `10m/20Mi` request, `200Mi` memory limit | Controller rclone sidecar resources. |
| `node.logLevel` | `3` | Node driver log verbosity. |
| `node.metrics.enabled` | `false` | Disables node metrics. |
| `node.metrics.service.enabled` | `false` | Does not expose a metrics Service. |
| `node.metrics.dashboard.enabled` | `false` | Does not create a metrics dashboard. |
| `node.rc.enabled` | `false` | Disables rclone remote control. |
| `node.rc.service.enabled` | `false` | Does not expose remote control Service. |
| `node.cache.enabled` | `false` | Disables chart-managed cache. |
| `node.resources.livenessProbe` | `10m/20Mi` request, `100Mi` memory limit | Node liveness probe resources. |
| `node.resources.nodeDriverRegistrar` | `10m/20Mi` request, `100Mi` memory limit | Node driver registrar resources. |
| `node.resources.rclone` | `10m/20Mi` request, `300Mi` memory limit | Node rclone resources. |
| `storageClass.create` | `true` | Creates the rclone StorageClass. |
| `storageClass.name` | `rclone-csi` | StorageClass name used by workloads. |
| `storageClass.annotations` | `{}` | Optional StorageClass annotations. |
| `storageClass.parameters.remote` | `pixeldrain` | rclone remote section name from the secret config. |
| `storageClass.parameters.remotePath` | `k8s/${pvc.metadata.namespace}/${pvc.metadata.name}` | Backend path template per PVC. |
| `storageClass.parameters.csi.storage.k8s.io/provisioner-secret-name` | `rclone-config` | Secret used by the provisioner. |
| `storageClass.parameters.csi.storage.k8s.io/provisioner-secret-namespace` | `rclone-csi` | Provisioner Secret namespace. |
| `storageClass.parameters.csi.storage.k8s.io/node-publish-secret-name` | `rclone-config` | Secret used when mounting on nodes. |
| `storageClass.parameters.csi.storage.k8s.io/node-publish-secret-namespace` | `rclone-csi` | Node publish Secret namespace. |
| `storageClass.reclaimPolicy` | `Retain` | Keeps backend data after PVC deletion. |
| `storageClass.volumeBindingMode` | `Immediate` | Binds volumes immediately. |
| `storageClass.mountOptions` | UID/GID `1000`, `allow-other`, full VFS cache, `10G` max cache, `1m` dir cache | rclone mount behavior and ownership. |

## Notes

- Do not inline rclone credentials in values. The `rclone-config` Secret should be synced from Bitwarden.
- `storageClass.parameters.remote` must match the section name in the rclone config.
