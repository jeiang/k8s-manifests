# Chart Guidelines

## Scope

This directory contains plain Kubernetes manifests for the `github-deployer`
ServiceAccount used by the GitHub Actions Helm Deploy and Helm Uninstall
workflows. It is not a local Helm chart.

## Runtime Contract

- ServiceAccount `github-deployer` lives in `kube-system`.
- It is bound to `cluster-admin` via a ClusterRoleBinding.
- The `github-deployer-token` Secret holds the long-lived token consumed by the
  `DEPLOYER_KUBECONFIG` GitHub Actions secret.
- A cluster admin applies this manifest manually as a one-time bootstrap.

## Editing Notes

- Never commit a ServiceAccount token, kubeconfig, or the `DEPLOYER_KUBECONFIG`
  value. The `github-deployer-token` Secret is populated by the cluster, not by
  this file.
- Any pull request that changes the RBAC grant here must call out the change
  explicitly; cluster-admin is intentional and justified in `README.md`.
- Keep the Kyverno bypass in sync: the `github-deployer` User subject must stay
  in `breakGlass.subjects` in `../rbac-access/values.yaml`. Removing it here
  without removing it there (or vice versa) is a mismatch.

## Validation

```sh
kubectl diff --server-side -f ./deploy-access/github-deployer.yaml
```
