# actual-budget

Values for deploying Actual Budget with the upstream `community-charts/actualbudget` Helm chart.

## What This Directory Configures

- Actual Budget behind Traefik at `https://budget.jeiang.dev`.
- cert-manager TLS using the `letsencrypt-prod` `ClusterIssuer`.
- A `ClusterIP` Service on port `5006`.
- A Hetzner CSI-backed persistent volume claim mounted at `/data`.
- A `Recreate` Deployment strategy for the RWO Hetzner volume.
- An init container that creates `/data/server-files` and `/data/user-files` before Actual starts.
- Password-based Actual Budget login.
- Conservative CPU and memory requests/limits.

## Dependencies

- Helm 3 and `kubectl`.
- Traefik installed with an IngressClass named `traefik`.
- cert-manager installed with a `letsencrypt-prod` `ClusterIssuer`.
- DNS for `budget.jeiang.dev` pointing at the Traefik load balancer.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.
- A dynamically provisioned `10Gi` PVC in the `actual-budget` namespace.
- Restored files must be writable by UID/GID `1000`; this values file runs the Actual Budget pod as UID/GID `1000`.

## Existing Data Restore

Existing installs cannot mutate the old `actual-budget-data` PVC from `rclone-csi` to `hcloud-volumes`. If you already have a local backup, you can delete the old PVC, let this chart create a fresh `hcloud-volumes` PVC, let the application run once, and then upload the backup contents into the new PVC.

Do not commit one-off restore Jobs, copy pod manifests, local backup data, or live storage credentials to this repository.

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

Confirm the Deployment uses the `Recreate` strategy and the PVC uses `hcloud-volumes` with a `10Gi` request before starting it against restored data.

If ingress is not ready yet, use a port-forward:

```fish
kubectl -n actual-budget port-forward svc/actual-budget 5006:5006
```

Then open `http://localhost:5006`.

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.

## Common Overrides

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
