# longhorn

Values for deploying Longhorn with the upstream `longhorn/longhorn` Helm chart.

## What This Values File Configures

- A `longhorn` StorageClass created by Longhorn.
- The `longhorn` StorageClass as the default storage class.
- `Retain` reclaim policy for safer data handling.
- `WaitForFirstConsumer` volume binding.
- Two replicas by default for Longhorn volumes.
- Longhorn UI exposed only as a `ClusterIP` Service.
- Resource requests and limits for Longhorn Manager.
- Resource settings for Longhorn-managed CSI components.

The upstream Longhorn chart version checked while creating this file was `1.12.0`.

## Dependencies

- Helm 3 and `kubectl`.
- Kubernetes `>=1.25`.
- Nodes prepared for Longhorn, including open-iscsi and required mount/NFS tooling for your distro.
- Enough schedulable storage under `/var/lib/longhorn` on each storage node.
- Privileged workloads allowed in the `longhorn-system` namespace.

## Install

Add the official Longhorn chart repository:

```fish
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

Review the rendered manifests:

```fish
helm template longhorn longhorn/longhorn \
  --namespace longhorn-system \
  -f ./longhorn/values.yaml
```

Install or upgrade:

```fish
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  -f ./longhorn/values.yaml \
  --wait
```

## Verify

```fish
kubectl -n longhorn-system get pods
kubectl get storageclass longhorn
kubectl -n longhorn-system rollout status daemonset/longhorn-manager --timeout=10m
kubectl -n longhorn-system rollout status deployment/longhorn-ui --timeout=10m
```

Access the UI with a port-forward:

```fish
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

Then open `http://localhost:8080`.

## Hath Persistence

The `hath` chart now defaults to:

```yaml
persistence:
  storageClassName: longhorn
```

Its cache, login data, downloads, and logs persist on the Longhorn PVC mounted at `/hath`. Its temp directory is `emptyDir`-backed at `/tmp/hath` and is not persisted.

## Values To Review

```yaml
persistence:
  defaultClassReplicaCount: 2
  reclaimPolicy: Retain

defaultSettings:
  defaultDataPath: /var/lib/longhorn
  defaultReplicaCount: '{"v1":"2","v2":"2"}'
```

Adjust replica counts for your cluster size and storage budget before installing.
