# Chart Guidelines

## Scope

This local Helm chart deploys `hath-rust` with persistent cache storage and direct node-level TCP exposure.

## Runtime Contract

- The Service is `ClusterIP`.
- Public H@H traffic uses `hostPort` TCP `8888`; firewall rules must allow the selected node.
- Persistence uses a chart-created PVC backed by the RWO-only `hcloud-volumes` StorageClass.
- The Deployment uses `Recreate` and one replica to avoid Hetzner volume multi-attach failures.
- The pod runs as UID/GID `1000`; restored data must remain writable by that identity.
- Keep one replica while `hostPort` is enabled.

## Editing Notes

- Existing installs with a local backup can delete the old rclone-backed PVC, let the chart create the hcloud PVC, run Hath once, and then restore the backup into the new PVC.
- Be careful changing `hostPort`; only one pod per node can bind a given host port.
- If replicas are ever increased, add placement constraints and ensure each pod has compatible storage.

## Validation

```sh
helm lint ./hath
helm template test ./hath --namespace hath
```
