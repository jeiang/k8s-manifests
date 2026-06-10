# longhorn

Values for deploying Longhorn with the upstream `longhorn/longhorn` Helm chart.

## What This Values File Configures

- The upstream Longhorn chart's built-in `longhorn` StorageClass creation.
- `ext4` as the default filesystem for Longhorn volumes.
- Best-effort data locality and replica auto-balance.
- Two replicas by default for Longhorn volumes.
- Longhorn UI ingress disabled.
- Longhorn upgrade checks disabled.

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
  defaultFsType: ext4
  defaultClassReplicaCount: 2
  defaultDataLocality: best-effort
  defaultReplicaAutoBalance: best-effort

defaultSettings:
  defaultDataPath: /var/lib/longhorn
  defaultReplicaCount: '{"v1":"2","v2":"2"}'
  storageOverProvisioningPercentage: "100"
  storageMinimalAvailablePercentage: "20"
```

Adjust replica counts for your cluster size and storage budget before installing.
