# rclone-csi-driver

Values and support manifests for deploying the upstream `veloxpack/csi-driver-rclone` Helm chart.

The upstream chart is installed from:

```text
oci://ghcr.io/veloxpack/charts/csi-driver-rclone
```

The CSI driver name is `rclone.csi.veloxpack.io`.

## Contents

- [What This Directory Configures](#what-this-directory-configures)
- [Dependencies](#dependencies)
- [Bitwarden Configuration](#bitwarden-configuration)
- [Install](#install)
- [Verify](#verify)
- [Values](#values)
- [References](#references)

## What This Directory Configures

- The upstream rclone CSI controller and node driver.
- k3s/NixOS kubelet path `/var/lib/kubelet`.
- A non-default `StorageClass` named `rclone-csi`.
- `StorageClass` parameters that read rclone configuration from the `rclone-csi/rclone-config` Secret.
- rclone mount ownership set to UID `1000` and GID `1000`.
- A `BitwardenSecret` manifest that syncs the rclone `configData` key into that Secret.
- Conservative resource requests and limits.

## Dependencies

- Helm 3 and `kubectl`.
- Nodes with FUSE support available.
- Bitwarden Secrets Manager operator installed if using `rclone-config-bitwardensecret.yaml`.
- A Bitwarden machine-account token Secret named `bw-auth-token` in the `rclone-csi` namespace.
- A Bitwarden Secrets Manager item containing the full rclone config file content.
- Network access from nodes to the configured rclone backend.

## Bitwarden Configuration

Create one Bitwarden Secrets Manager secret whose value is the complete rclone configuration. Example value for an S3-compatible backend:

```ini
[s3]
type = s3
provider = AWS
access_key_id = REPLACE_ME
secret_access_key = REPLACE_ME
region = us-east-1
```

Update `rclone-config-bitwardensecret.yaml`:

- `spec.organizationId`: your Bitwarden organization ID.
- `spec.map[0].bwSecretId`: the Bitwarden secret ID containing the rclone config text.

The synced Kubernetes Secret must contain this key:

```yaml
configData: |
  [s3]
  ...
```

The `StorageClass` sets the non-secret values:

```yaml
remote: s3
remotePath: k8s/${pvc.metadata.namespace}/${pvc.metadata.name}
```

Change `storageClass.parameters.remote` if the rclone remote section name is not `[s3]`.

## Install

Create the namespace and Bitwarden auth token Secret:

```fish
kubectl create namespace rclone-csi --dry-run=client -o yaml | kubectl apply -f -

read --silent --prompt-str 'Bitwarden machine account token: ' BW_AUTH_TOKEN
echo

kubectl -n rclone-csi create secret generic bw-auth-token \
  --from-literal=token="$BW_AUTH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

set --erase BW_AUTH_TOKEN
```

Sync the rclone configuration from Bitwarden:

```fish
kubectl apply -f ./rclone-csi-driver/rclone-config-bitwardensecret.yaml
kubectl -n rclone-csi get bitwardensecret rclone-config
kubectl -n rclone-csi get secret rclone-config
```

The upstream chart version checked while creating this file was `0.4.11`.

Render the chart:

```fish
helm template csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone \
  --namespace rclone-csi \
  --version 0.4.11 \
  -f ./rclone-csi-driver/values.yaml
```

Install or upgrade:

```fish
helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone \
  --namespace rclone-csi \
  --create-namespace \
  --version 0.4.11 \
  -f ./rclone-csi-driver/values.yaml \
  --wait
```

## Verify

```fish
kubectl -n rclone-csi get pods
kubectl get csidriver rclone.csi.veloxpack.io
kubectl get storageclass rclone-csi
```

Create a test claim:

```fish
kubectl create namespace rclone-test --dry-run=client -o yaml | kubectl apply -f -

kubectl -n rclone-test apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rclone-test
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: rclone-csi
  resources:
    requests:
      storage: 1Gi
EOF

kubectl -n rclone-test get pvc rclone-test
```

Mount the claim in a test pod:

```fish
kubectl -n rclone-test apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: rclone-test
spec:
  securityContext:
    fsGroup: 1000
  restartPolicy: Never
  containers:
    - name: shell
      image: busybox:1.36
      command: ["sh", "-c", "echo hello > /mnt/rclone/hello.txt && cat /mnt/rclone/hello.txt && sleep 3600"]
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
      volumeMounts:
        - name: data
          mountPath: /mnt/rclone
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: rclone-test
EOF

kubectl -n rclone-test logs pod/rclone-test
```

Clean up the test resources:

```fish
kubectl -n rclone-test delete pod rclone-test
kubectl -n rclone-test delete pvc rclone-test
```

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.

## References

- Upstream repository: https://github.com/veloxpack/csi-driver-rclone
- Rclone config docs: https://rclone.org/docs/
- Rclone backends: https://rclone.org/overview/
