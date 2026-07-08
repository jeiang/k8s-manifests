# hath

Helm chart for running `hath-rust`.

Default image: `ghcr.io/james58899/hath-rust:latest`.

## What This Chart Creates

- A single `hath-rust` Deployment.
- A `ClusterIP` Service exposing the configured H@H port inside the cluster.
- A TCP `hostPort` on port `8888` for direct node-level exposure.
- A Hetzner CSI-backed persistent volume claim mounted at `/hath`.
- A `Recreate` Deployment strategy for the RWO Hetzner volume.
- Persistent directories for cache, login data, downloads, and logs.
- An ephemeral `emptyDir` for temporary files at `/tmp/hath`.
- Metrics endpoint and optional HTTP/3 UDP port.

## Dependencies

- Helm 3 and `kubectl`.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.
- A dynamically provisioned `30Gi` PVC in the `hath` namespace.
- Copied files must be writable by UID/GID `1000`; this chart runs the Hath pod as UID/GID `1000`.
- Firewall rules allowing inbound TCP `8888` to the node running the Hath pod.

## Existing Data Restore

Existing installs cannot mutate the old `hath` PVC from `rclone-csi` to `hcloud-volumes`. If you already have a local backup, you can delete the old PVC, let this chart create a fresh `hcloud-volumes` PVC, let the application run once, and then upload the backup contents into the new PVC.

Do not commit one-off restore Jobs, copy pod manifests, local backup data, or live storage credentials to this repository.

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

Confirm the Deployment uses the `Recreate` strategy and the PVC uses `hcloud-volumes` with a `30Gi` request.

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.

Set any additional `hath-rust` options through the `hath` values or `hath.extraArgs`.
