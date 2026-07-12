# Deploy Pipeline

Two GitHub Actions workflows let write-access collaborators and cloud agents
deploy and uninstall this repository's Helm units without an interactive Pocket
ID login. Both authenticate as the `github-deployer` ServiceAccount.

- `.github/workflows/helm-deploy.yml` runs `helm upgrade --install`.
- `.github/workflows/helm-uninstall.yml` runs `helm uninstall`.
- `.github/deploy-targets.json` is the single source of truth that maps each
  deployable unit to its chart, release, namespace, and install flags. Both
  workflows read it with `jq`.

## Scope

The pipeline covers all 15 deployable units: the 9 local charts (`bill-splitter`,
`blocky-dns`, `github-redirect`, `hath`, `idp`, `netbird`, `netbird-resources`,
`rbac-access`, `website`) and the 6 upstream values-only units (`actual-budget`,
`bitwarden-sm-operator`, `crowdsec`, `monitoring`, `rclone-csi-driver`,
`netbird-operator`).

Out of scope, by design:

- `traefik/` — a k3s `HelmChartConfig` applied with `kubectl apply`, not Helm.
- Per-unit support manifests applied with `kubectl apply` (BitwardenSecrets,
  ConfigMaps, NetworkResources, VMServiceScrapes, cert-manager installs). Apply
  those manually per the unit READMEs.

## Deploy workflow

Run **Actions → Helm Deploy → Run workflow** with:

- `chart` — the unit to install or upgrade (choice of the 15 unit names).
- `extra_args` — extra helm arguments appended to the command, default empty.
  The string is word-split (`read -r -a`) and forwarded verbatim, for example
  `--set netbird.enabled=false`. This is intentional: dispatch already requires
  write access. Do not pass untrusted input.
- `dry_run` — when true, the command runs with `--dry-run=server --debug` and
  nothing is applied. The post-deploy status step is skipped. When false, the
  deploy runs with `--wait --timeout` (default `10m`, per-unit override in the
  mapping).

The deploy step adds the upstream repo when the unit needs one, runs
`helm dependency build` for units that declare a local dependency (`blocky-dns`),
then builds the helm argument list from the mapping: `--namespace`, optional
`--create-namespace`, `--version`, `--devel`, and `-f <values>`. On a real run
it also prints `helm status`, pods, and recent events for the namespace.

### Testing workflow changes on a branch

GitHub only dispatches `workflow_dispatch` workflows whose file exists on the
default branch. Once these workflows are on `main`, branch edits are testable
before merging: pick the branch in the **Run workflow** dropdown (or
`gh workflow run <file> --ref <branch>`), and the branch's version of the
workflow file and `.github/deploy-targets.json` is what runs. A brand-new
workflow file that exists only on a branch cannot be dispatched at all — it
must merge first. To validate cluster-side behavior before such a merge, run
the exact helm command the mapping would produce locally with the deployer
kubeconfig and `--dry-run=server`.

## Uninstall workflow

Run **Actions → Helm Uninstall → Run workflow** with:

- `chart` — the unit to uninstall.
- `confirm` — must equal the `chart` value exactly. The first step fails fast
  before checkout if they differ.

It resolves the release and namespace from the same mapping, warns and exits 0
if the release is not installed, otherwise runs
`helm uninstall <release> -n <namespace> --wait --timeout 10m`, then lists what
remains (`kubectl get all,pvc`).

It deliberately does **not** remove:

- Namespaces.
- PersistentVolumeClaims or PersistentVolumes (application data).
- CRDs installed by charts.
- `bw-auth-token` Secrets or any BitwardenSecret-synced Secret.
- `kubectl`-applied support manifests.

Clean those up manually when you are sure, for example:

```sh
kubectl delete pvc --all --namespace <namespace>
kubectl delete namespace <namespace>
```

## One-time auth setup

A cluster admin performs this once. Details and commands live in
`../deploy-access/README.md`.

1. Apply the ServiceAccount, ClusterRoleBinding, and token Secret:

   ```sh
   kubectl apply -f ./deploy-access/github-deployer.yaml
   ```

2. Re-run the rbac-access chart so the Kyverno bypass for `github-deployer`
   (already committed to `rbac-access/values.yaml`) takes effect. Do this before
   the first pipeline run, otherwise `--create-namespace` deploys are denied:

   ```sh
   helm upgrade --install rbac-access ./rbac-access --namespace kube-system
   ```

   Whenever `breakGlass.subjects` or `globalAdmins.subjects` change (including
   this setup), Kyverno's policy webhook may deny the upgrade with `changes of
   immutable fields of a rule spec in a generate rule is disallowed`, because
   the bypass subjects render into the exclude block of the
   `rbac-access-generate-namespace-owner` generate policy. This is not an
   authorization failure — an admin kubeconfig does not help. Delete that one
   policy and re-run the upgrade; generated RoleBindings are retained. Full
   explanation in `../deploy-access/README.md`:

   ```sh
   kubectl delete clusterpolicy rbac-access-generate-namespace-owner
   helm upgrade --install rbac-access ./rbac-access --namespace kube-system
   ```

3. Extract the token and cluster CA and assemble a kubeconfig:

   ```sh
   kubectl -n kube-system get secret github-deployer-token \
     -o jsonpath='{.data.token}' | base64 -d
   ```

   The API server is `https://node1.jeiang.dev:6443`, the cluster name is
   `legion`, and the CA data is in `AUTHENTICATION.md`. See
   `../deploy-access/README.md` for the full kubeconfig template.

4. Verify the identity, then set the GitHub Actions secret and delete the local
   file:

   ```sh
   kubectl --kubeconfig ./github-deployer.kubeconfig auth whoami
   # Expect: system:serviceaccount:kube-system:github-deployer
   gh secret set DEPLOYER_KUBECONFIG < ./github-deployer.kubeconfig
   rm ./github-deployer.kubeconfig
   ```

## Rotation

Delete the `github-deployer-token` Secret, re-apply
`deploy-access/github-deployer.yaml`, then rebuild and re-upload
`DEPLOYER_KUBECONFIG`. Full steps are in `../deploy-access/README.md`.

## Security notes

`github-deployer` is bound to `cluster-admin`. Repository charts create
ClusterRoles, ClusterRoleBindings, Kyverno `ClusterPolicy` objects, cert-manager
`ClusterIssuer` references, CRDs, and namespaces. Kubernetes RBAC escalation
prevention blocks a ServiceAccount from granting privileges it does not hold, so
any narrower role breaks on chart-shipped RBAC. The mitigations are: dispatch is
limited to write-access collaborators, the token is rotatable, and a GitHub
Environment approval gate can be added later. There is no Environment approval
gate today.

## Add a new deployable unit

Whenever you add, rename, or remove a unit, or change a unit README's install
command, update all of these together:

1. Read the unit README's documented `helm upgrade --install` command; it is the
   source of truth for release name, namespace, version pin, values file, and
   flags such as `--devel` or `--create-namespace`.
2. Add or edit the entry in `.github/deploy-targets.json`.
3. Add or edit the `chart` choice `options` in **both**
   `.github/workflows/helm-deploy.yml` and
   `.github/workflows/helm-uninstall.yml`. The choice lists and the mapping keys
   must match exactly.
4. Dispatch Helm Deploy with `dry_run: true` and confirm the rendered command.
5. Dispatch a real deploy.
