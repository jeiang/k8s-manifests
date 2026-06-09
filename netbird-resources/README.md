# netbird-resources

Helm chart for NetBird operator routing resources.

## What This Chart Creates

- A `NetworkRouter` named `k8s` in the `netbird` namespace.
- A `NetworkResource` for the `blocky-dns` Service in the `dns` namespace.
- A `NetworkResource` for the `idp-lldap` Service in the `idp` namespace.

The NetBird operator uses these resources to expose Kubernetes services to your NetBird network. With the default DNS zone, the expected service records are:

- `blocky-dns.dns.k8s.jeiang.vpn`
- `idp-lldap.idp.k8s.jeiang.vpn`

## Dependencies

- Helm 3 and `kubectl`.
- NetBird Kubernetes operator installed.
- NetBird operator CRDs for `NetworkRouter` and `NetworkResource`.
- A custom NetBird DNS zone matching `networkRouter.dnsZoneRef.name`.
- Existing `blocky-dns` Service in the `dns` namespace.
- Existing `idp-lldap` Service in the `idp` namespace.

Before creating a `NetworkRouter`, create the DNS zone in the NetBird dashboard. The NetBird documentation requires this zone to exist before the operator can register it.

## Install Operator

Install cert-manager if it is not already installed. NetBird recommends it so the Kubernetes API can communicate with the operator admission webhooks:

```fish
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
```

Create the NetBird namespace and API token Secret. Replace `~/nb-pat.secret` with the path to your NetBird personal access token:

```fish
kubectl create namespace netbird --dry-run=client -o yaml | kubectl apply -f -

kubectl -n netbird create secret generic netbird-mgmt-api-key \
  --from-literal=NB_API_KEY=(cat ~/nb-pat.secret) \
  --dry-run=client -o yaml | kubectl apply -f -
```

Install the upstream NetBird operator chart with the self-hosted management URL set to `https://netbird.jeiang.dev`:

```fish
helm upgrade --install netbird-operator oci://ghcr.io/netbirdio/helm-charts/netbird-operator \
  --namespace netbird \
  --create-namespace \
  --set managementURL=https://netbird.jeiang.dev \
  --set netbirdAPI.keyFromSecret.name=netbird-mgmt-api-key \
  --set netbirdAPI.keyFromSecret.key=NB_API_KEY
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
helm template netbird-resources ./netbird-resources --namespace netbird \
  --set networkRouter.dnsZoneRef.name=k8s.jeiang.vpn
```

Validate and install:

```fish
helm lint ./netbird-resources

helm upgrade --install netbird-resources ./netbird-resources \
  --namespace netbird \
  --create-namespace \
  --set networkRouter.dnsZoneRef.name=k8s.jeiang.vpn
```

## Verify

```fish
kubectl -n netbird get networkrouter k8s
kubectl -n dns get networkresource blocky-dns
kubectl -n idp get networkresource lldap

kubectl -n netbird describe networkrouter k8s
kubectl -n dns describe networkresource blocky-dns
kubectl -n idp describe networkresource lldap
```

## Values To Review

```yaml
networkRouter:
  name: k8s
  namespace: netbird
  dnsZoneRef:
    name: k8s.jeiang.vpn

networkResources:
  groups:
    - name: All
  resources:
    - name: blocky-dns
      namespace: dns
      serviceRef:
        name: blocky-dns
    - name: lldap
      namespace: idp
      serviceRef:
        name: idp-lldap
```
