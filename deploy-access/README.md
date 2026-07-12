# deploy-access

Plain Kubernetes manifests for the `github-deployer` ServiceAccount that the
GitHub Actions Helm Deploy and Helm Uninstall workflows authenticate as.

## What This Directory Configures

- ServiceAccount `github-deployer` in `kube-system`.
- ClusterRoleBinding `github-deployer` binding it to the built-in
  `cluster-admin` ClusterRole.
- Long-lived token Secret `github-deployer-token`
  (`kubernetes.io/service-account-token`) that Kubernetes populates for the
  ServiceAccount.

## Why cluster-admin

The workflows install repository charts that create cluster-scoped resources:
ClusterRoles and ClusterRoleBindings, Kyverno `ClusterPolicy` objects,
cert-manager `ClusterIssuer` references, CRDs, and namespaces. Kubernetes RBAC
escalation prevention blocks a ServiceAccount from creating or binding
privileges it does not already hold, so any role narrower than
cluster-admin-equivalent breaks on chart-shipped RBAC. This grant is deliberate.
The mitigations are: `workflow_dispatch` is limited to collaborators with write
access, the token is rotatable (below), and a GitHub Environment approval gate
can be added later as further hardening.

## Apply

A cluster administrator applies this manually as a one-time bootstrap. It is not
installed by any workflow.

```sh
kubectl apply -f ./deploy-access/github-deployer.yaml
```

The `github-deployer` User must also be present in `breakGlass.subjects` in
`../rbac-access/values.yaml` (already committed) so Kyverno does not deny
`--create-namespace` deploys. After applying this file, re-run the rbac-access
chart once:

```sh
helm upgrade --install rbac-access ./rbac-access --namespace kube-system
```

### If the rbac-access upgrade is denied by Kyverno

Changing `breakGlass.subjects` (or `globalAdmins.subjects`) fails the upgrade
with:

```text
admission webhook "validate-policy.kyverno.svc" denied the request: changes of
immutable fields of a rule spec in a generate rule is disallowed
```

The bypass subjects render into the `exclude` block of the
`rbac-access-generate-namespace-owner` ClusterPolicy, which is a generate rule,
and Kyverno forbids updating the match/exclude fields of generate rules in
place. This is Kyverno's webhook validating the policy content, not an
authorization failure — switching to the k3s admin kubeconfig does not help.
Delete that one policy and re-run the upgrade so it is recreated with the new
spec:

```sh
kubectl delete clusterpolicy rbac-access-generate-namespace-owner
helm upgrade --install rbac-access ./rbac-access --namespace kube-system
```

The deletion is low-risk: Kyverno retains already-generated
`rbac-access-owner-admin` RoleBindings, and the policy has
`generateExisting: false` and `background: false`, so the only exposure is a
seconds-long window in which a brand-new namespace would not get its owner
RoleBinding auto-generated. Verify the bypass landed in every policy
afterwards:

```sh
kubectl get clusterpolicy -o yaml | grep -c github-deployer
# Expect 9, one per policy exclude block.
```

## Create the DEPLOYER_KUBECONFIG secret

Run these once from an admin workstation to assemble the kubeconfig the
workflows consume, then store it as the GitHub Actions secret
`DEPLOYER_KUBECONFIG`.

```sh
token="$(kubectl -n kube-system get secret github-deployer-token \
  -o jsonpath='{.data.token}' | base64 -d)"
ca="$(kubectl -n kube-system get secret github-deployer-token \
  -o jsonpath='{.data.ca\.crt}' | base64 -w0)"

cat > github-deployer.kubeconfig <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: legion
    cluster:
      server: https://node1.jeiang.dev:6443
      certificate-authority-data: ${ca}
users:
  - name: github-deployer
    user:
      token: ${token}
contexts:
  - name: github-deployer@legion
    context:
      cluster: legion
      user: github-deployer
current-context: github-deployer@legion
EOF
```

Verify the identity, set the GitHub secret, then delete the local file:

```sh
kubectl --kubeconfig ./github-deployer.kubeconfig auth whoami
# Expect: system:serviceaccount:kube-system:github-deployer

gh secret set DEPLOYER_KUBECONFIG < ./github-deployer.kubeconfig
rm ./github-deployer.kubeconfig
```

The cluster CA is public and also documented in `../docs/AUTHENTICATION.md`. The
API server is `https://node1.jeiang.dev:6443` and the cluster name is `legion`.

## Rotate the token

Delete the token Secret and re-apply so Kubernetes issues a fresh token, then
rebuild and re-upload `DEPLOYER_KUBECONFIG`:

```sh
kubectl -n kube-system delete secret github-deployer-token
kubectl apply -f ./deploy-access/github-deployer.yaml
```

Then repeat the "Create the DEPLOYER_KUBECONFIG secret" steps above.

## Verify

```sh
kubectl -n kube-system get serviceaccount github-deployer
kubectl get clusterrolebinding github-deployer
kubectl -n kube-system get secret github-deployer-token
```
