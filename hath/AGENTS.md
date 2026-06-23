# Chart Guidelines

## Scope

This local Helm chart deploys `hath-rust` with persistent cache storage and direct node-level TCP exposure.

## Runtime Contract

- The Service is `ClusterIP`.
- Public H@H traffic uses `hostPort` TCP `8888`; firewall rules must allow the selected node.
- Persistence uses the RWO-only `hcloud-volumes` StorageClass.
- Only one replica should run while the PVC is `ReadWriteOnce`.
- `ServiceMonitor` output requires Prometheus Operator CRDs.

## Editing Notes

- Keep PVC access mode as `ReadWriteOnce` unless the storage backend changes.
- Be careful changing `hostPort`; only one pod per node can bind a given host port.
- If replicas are ever increased, add placement constraints and ensure each pod has compatible storage.

## Validation

```sh
helm lint ./hath
helm template test ./hath --namespace hath
```

