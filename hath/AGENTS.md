# Chart Guidelines

## Scope

This local Helm chart deploys `hath-rust` with persistent cache storage and direct node-level TCP exposure.

## Runtime Contract

- The Service is `ClusterIP`.
- Public H@H traffic uses `hostPort` TCP `8888`; firewall rules must allow the selected node.
- Persistence uses a copied `hath-hcloud` PVC backed by the RWO-only `hcloud-volumes` StorageClass.
- The Deployment uses `Recreate` and one replica to avoid Hetzner volume multi-attach failures.
- The pod runs as UID/GID `1000`; copied data must remain writable by that identity.
- Keep one replica while `hostPort` is enabled.

## Editing Notes

- Hath requires its data directory to exist before startup. Existing installs must copy data into `hath-hcloud` before the chart is upgraded to mount it.
- Be careful changing `hostPort`; only one pod per node can bind a given host port.
- If replicas are ever increased, add placement constraints and ensure each pod has compatible storage.

## Validation

```sh
helm lint ./hath
helm template test ./hath --namespace hath
```
