# Cluster

The target cluster is k3s on Hetzner Cloud nodes running NixOS.

## Platform Baseline

Expected node-level setup:

- Configure each node's Hetzner public IPv4 as a `/32` address and public IPv6 as a `/64` address in NixOS/systemd-networkd.
- Keep private cluster traffic on the Hetzner private network interface and use that interface for Flannel.
- Use IPv4-only pod and service CIDRs for Kubernetes networking.
- Disable k3s ServiceLB so Hetzner Cloud Controller Manager owns `LoadBalancer` Services.
- Disable the embedded k3s cloud controller and set the kubelet cloud provider to `external` before installing `hcloud-cloud-controller-manager`.
- Install the Hetzner CSI driver for Hetzner Cloud Volumes, backed by a `kube-system/hcloud` Secret containing a read/write Hetzner Cloud API token.

Important k3s flags for this platform:

```sh
--flannel-iface=<hetzner-private-interface>
--disable=servicelb
--disable-cloud-controller
--kubelet-arg=cloud-provider=external
--cluster-cidr=10.42.0.0/16
--service-cidr=10.43.0.0/16
```

The Hetzner Cloud Controller Manager should own node provider IDs and cloud-discovered node addresses. Hetzner public IPv4s belong in node OS networking, but k3s node external addresses should generally be left to the external cloud controller.

## Hetzner Components

Install the Hetzner components after the k3s nodes are up:

```fish
kubectl -n kube-system create secret generic hcloud \
  --from-literal=token=REPLACE_ME_HCLOUD_TOKEN \
  --from-literal=network=REPLACE_ME_HETZNER_NETWORK_ID_OR_NAME

helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud

helm upgrade --install hccm hcloud/hcloud-cloud-controller-manager \
  --namespace kube-system \
  --set networking.enabled=true \
  --set networking.clusterCIDR=10.42.0.0/16 \
  --wait

helm upgrade --install hcloud-csi hcloud/hcloud-csi \
  --namespace kube-system \
  --set node.kubeletDir=/var/lib/kubelet \
  --wait
```

## Storage Policy

Most small repository PVCs should use the Hetzner CSI-backed `hcloud-volumes` StorageClass. Treat it as `ReadWriteOnce` only; Hetzner Cloud Volumes are node-attached block volumes and do not support RWX.

Use `hcloud-volumes` for small RWO volumes, roughly less than `20Gi`, when the workload can run safely on one node at a time.

Use `rclone-csi` for volumes that are larger than `20Gi`, expected to grow beyond `20Gi`, or require `ReadWriteMany`/multi-pod access. Workloads that explicitly use rclone-backed storage set `storageClassName` or `storageClass` to `rclone-csi`.

Verify storage classes before installing workloads that create PVCs:

```fish
kubectl get storageclass hcloud-volumes
kubectl get storageclass rclone-csi
```

## External Cluster Components

These components are expected to exist but are not defined as local Helm charts here:

- Hetzner Cloud Controller Manager from `hcloud/hcloud-cloud-controller-manager`, installed in `kube-system` with networking enabled for the cluster CIDR.
- Hetzner CSI from `hcloud/hcloud-csi`, installed in `kube-system` with `node.kubeletDir=/var/lib/kubelet`.
- cert-manager and a production `letsencrypt-prod` `ClusterIssuer`.
- k3s bundled Traefik, configured by `traefik/traefik-helmchartconfig.yaml`.
- Bitwarden Secrets Manager operator when charts render `BitwardenSecret` resources.
- NetBird Kubernetes operator when charts render `NetworkRouter` or `NetworkResource` resources.
- Rclone CSI driver from `oci://ghcr.io/veloxpack/charts/csi-driver-rclone` when rclone-backed PVCs are needed; local values live in `rclone-csi-driver/`.
