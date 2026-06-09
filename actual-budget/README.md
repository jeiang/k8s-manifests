# actual-budget

Values for deploying Actual Budget with the upstream `community-charts/actualbudget` Helm chart.

## What This Values File Configures

- Actual Budget behind Traefik at `https://budget.jeiang.dev`.
- cert-manager TLS using the `letsencrypt-prod` `ClusterIssuer`.
- A `ClusterIP` Service on port `5006`.
- A persistent volume claim with `10Gi` of storage.
- Password-based Actual Budget login.
- Conservative CPU and memory requests/limits.

## Dependencies

- Helm 3 and `kubectl`.
- Traefik installed with an IngressClass named `traefik`.
- cert-manager installed with a `letsencrypt-prod` `ClusterIssuer`.
- DNS for `budget.jeiang.dev` pointing at the Traefik load balancer.
- A default storage class, or set `persistence.storageClass` in `values.yaml`.

## Install

Add the chart repository:

```fish
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update
```

Review the rendered manifests:

```fish
helm template actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  -f ./actual-budget/values.yaml
```

Install or upgrade:

```fish
helm upgrade --install actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  --create-namespace \
  -f ./actual-budget/values.yaml \
  --wait
```

## Verify

```fish
kubectl -n actual-budget get deploy,pods,svc,ingress,pvc
kubectl -n actual-budget rollout status deployment/actual-budget --timeout=5m
kubectl -n actual-budget get ingress actual-budget
```

If ingress is not ready yet, use a port-forward:

```fish
kubectl -n actual-budget port-forward svc/actual-budget 5006:5006
```

Then open `http://localhost:5006`.

## Common Overrides

Use a specific storage class:

```fish
helm upgrade --install actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  --create-namespace \
  -f ./actual-budget/values.yaml \
  --set persistence.storageClass=your-storage-class \
  --wait
```

Change the public hostname:

```fish
helm upgrade --install actual-budget community-charts/actualbudget \
  --namespace actual-budget \
  --create-namespace \
  -f ./actual-budget/values.yaml \
  --set ingress.hosts[0].host=budget.example.com \
  --set ingress.tls[0].hosts[0]=budget.example.com \
  --wait
```

## References

- Actual Budget: https://actualbudget.org
- Chart usage: https://community-charts.github.io/docs/charts/actualbudget/usage
- Chart source: https://github.com/community-charts/helm-charts
