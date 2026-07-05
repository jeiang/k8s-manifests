# hath

Helm chart for running `hath-rust`.

Default image: `ghcr.io/james58899/hath-rust:latest`.

## What This Chart Creates

- A single `hath-rust` Deployment.
- A `ClusterIP` Service exposing the configured H@H port inside the cluster.
- A TCP `hostPort` on port `8888` for direct node-level exposure.
- A pre-created Hetzner CSI-backed persistent volume claim named `hath-hcloud` mounted at `/hath`.
- A `Recreate` Deployment strategy for the RWO Hetzner volume.
- Persistent directories for cache, login data, downloads, and logs.
- An ephemeral `emptyDir` for temporary files at `/tmp/hath`.
- Metrics endpoint and optional HTTP/3 UDP port.

## Dependencies

- Helm 3 and `kubectl`.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.
- A `30Gi` PVC named `hath-hcloud` in the `hath` namespace, populated with the existing Hath data before the Deployment starts.
- Copied files must be writable by UID/GID `1000`; this chart runs the Hath pod as UID/GID `1000`.
- Firewall rules allowing inbound TCP `8888` to the node running the Hath pod.

## Existing Data Migration

Existing installs cannot mutate the old `hath` PVC from `rclone-csi` to `hcloud-volumes`. Create `hath-hcloud` outside this chart, stop Hath, copy the old PVC contents into the new PVC, and verify the data directory is present before upgrading this release. Hath requires that data to exist before startup.

Do not commit one-off copy Jobs, copy pod manifests, or live storage credentials to this repository.

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

Confirm the Deployment mounts `hath-hcloud` and uses the `Recreate` strategy before starting it against migrated data.

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.

Set any additional `hath-rust` options through the `hath` values or `hath.extraArgs`.
