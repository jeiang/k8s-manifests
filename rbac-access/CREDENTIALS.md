# Temporary User Credentials

This chart currently mirrors the local client-certificate setup. It should be replaced by IdP-backed authentication later.

## Generate kubeconfigs

Run the generator with a kubeconfig that can create and approve Kubernetes client certificate CSRs:

```fish
./rbac-access/generate_kubeconfigs.fish \
  --context <admin-context> \
  --output-dir ./rbac-access/kubeconfigs
```

The script reads configured users from `values.yaml` and any repeated `--values` files. It writes a key, certificate, and kubeconfig for each user. Each kubeconfig uses the user's personal namespace as its default namespace.

If a user has `users[].groups`, the script encodes those groups as certificate organization (`O`) fields.

## Install order

1. Install Kyverno.
2. Install or upgrade this chart.
3. Generate kubeconfigs.
4. Give each user only their own kubeconfig file.
5. Have users create their personal namespace or a prefixed namespace with `kubectl create namespace`.

## Emergency access

Use the k3s admin kubeconfig for emergency cluster access. Do not depend on generated user kubeconfigs for break-glass operations.
