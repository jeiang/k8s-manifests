# Chart Guidelines

## Scope

This directory contains values and support manifests for the upstream `oci://ghcr.io/veloxpack/charts/csi-driver-rclone` Helm chart. It does not own the driver templates.

## Runtime Contract

- The CSI driver name is `rclone.csi.veloxpack.io`.
- The chart is installed into the `rclone-csi` namespace.
- The k3s/NixOS kubelet directory is `/var/lib/kubelet`.
- The `rclone-csi` StorageClass reads sensitive rclone config from the `rclone-csi/rclone-config` Secret.
- The `rclone-config` Secret is expected to be synced by Bitwarden Secrets Manager from `rclone-config-bitwardensecret.yaml`.
- The StorageClass is not the default storage class.
- rclone mounts are presented as UID `1000` and GID `1000`; workloads using this StorageClass should run with matching pod/container security contexts when they need write access.

## Editing Notes

- Do not commit rclone credentials or inline `configData` containing secrets.
- Keep `remote` aligned with the section name in the rclone config, for example `[s3]` and `remote: s3`.
- Keep secret references in the StorageClass aligned with the BitwardenSecret output Secret name and namespace.
- Rclone-backed volumes depend on the remote backend semantics; do not assume the same consistency or locking behavior as block storage.

## Validation

```sh
helm template csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone \
  --namespace rclone-csi \
  -f ./rclone-csi-driver/values.yaml
```
