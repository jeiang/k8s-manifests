# netbird-resources

Helm chart for NetBird operator routing resources.

## Contents

- [What This Chart Creates](#what-this-chart-creates)
- [Dependencies](#dependencies)
- [Install Operator](#install-operator)
- [Install](#install)
- [Verify](#verify)
- [Values](#values)

## What This Chart Creates

- A `NetworkRouter` named `k8s` in the `netbird` namespace.
- A `BitwardenSecret` that syncs the NetBird operator API token Secret.
- Optional `NetworkResource` objects when `networkResources.enabled=true`.

The NetBird operator uses these resources to expose Kubernetes services to your NetBird network. The shared router and API token live in this chart. Workload-specific `NetworkResource` objects are owned by the workload charts that expose those Services:

- `blocky-dns` can create `blocky-dns.dns.k8s.jeiang.vpn` when installed with `--set netbird.enabled=true`.

## Dependencies

- Helm 3 and `kubectl`.
- NetBird Kubernetes operator installed.
- NetBird operator CRDs for `NetworkRouter` and `NetworkResource`.
- A custom NetBird DNS zone matching `networkRouter.dnsZoneRef.name`.
- Bitwarden Secrets Manager operator CRDs.
- A `bw-auth-token` Secret in the `netbird` namespace so the Bitwarden operator can sync `netbird-mgmt-api-key`.

Before creating a `NetworkRouter`, create the DNS zone in the NetBird dashboard. The NetBird documentation requires this zone to exist before the operator can register it.

## Install Operator

Install cert-manager if it is not already installed. NetBird recommends it so the Kubernetes API can communicate with the operator admission webhooks:

```fish
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
```

Create the NetBird namespace:

```fish
kubectl create namespace netbird --dry-run=client -o yaml | kubectl apply -f -
```

Store the NetBird personal access token in Bitwarden Secrets Manager and set `bitwardenSecrets.netbirdApi.secretId` to that Bitwarden secret ID. Apply the `BitwardenSecret` before installing the NetBird operator resources:

```fish
helm template netbird-resources ./netbird-resources \
  --namespace netbird \
  --set networkRouter.enabled=false \
  --set networkResources.enabled=false \
  --set bitwardenSecrets.netbirdApi.enabled=true \
  --set bitwardenSecrets.netbirdApi.organizationId=replace-with-organization-uuid \
  --set bitwardenSecrets.netbirdApi.secretId=replace-with-secret-uuid \
  | kubectl apply -f -
```

The Bitwarden machine-account token Secret must already exist in the `netbird` namespace:

```fish
kubectl -n netbird get secret bw-auth-token
```

Install the upstream NetBird operator chart with the self-hosted management URL set to `https://netbird.jeiang.dev`:

```fish
helm upgrade --install netbird-operator oci://ghcr.io/netbirdio/helm-charts/netbird-operator \
  --namespace netbird \
  --create-namespace \
  -f ./netbird-resources/operator-values.yaml \
  --wait \
  --timeout=10m
```

Verify the operator and CRDs are present:

```fish
kubectl -n netbird rollout status deployment/netbird-operator --timeout=5m
kubectl get crd networkrouters.netbird.io
kubectl get crd networkresources.netbird.io
kubectl -n netbird get deploy,pods
```

See the upstream NetBird routing peer documentation:

https://docs.netbird.io/manage/integrations/kubernetes/routing-peer

## Install

Review the DNS zone before installing:

```fish
helm template netbird-resources ./netbird-resources --namespace netbird
```

Validate and install:

```fish
helm lint ./netbird-resources

helm upgrade --install netbird-resources ./netbird-resources \
  --namespace netbird \
  --create-namespace
```

Install workload-specific NetBird resources by enabling the subchart in each workload chart:

```fish
helm dependency build ./blocky-dns
helm upgrade --install blocky-dns ./blocky-dns \
  --namespace dns \
  --create-namespace \
  --set netbird.enabled=true
```

## Verify

```fish
kubectl -n netbird get networkrouter k8s
kubectl -n dns get networkresource blocky-dns

kubectl -n netbird describe networkrouter k8s
kubectl -n dns describe networkresource blocky-dns
```

## Values

See [`VALUES.md`](./VALUES.md) for the local chart values documented with defaults and operational notes. The upstream operator override lives in [`operator-values.yaml`](./operator-values.yaml).
