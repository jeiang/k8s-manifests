# Attic

Helm chart for the OIDC-enabled [`jeiang/attic`](https://github.com/jeiang/attic)
fork, backed by Mega S4 and exposed at `https://attic.jeiang.dev/`.

The image is pinned to the multi-architecture Nix build at
`ghcr.io/jeiang/attic:586bcd9af71218c9b7f784bd22fa65b5c763d1c8`.
That commit supports OIDC token exchange. It does not use a Dockerfile: the
fork's container workflow builds `attic-server-image` from `flake/packages.nix`.

## Architecture and prerequisites

The chart creates one Attic server, a `ClusterIP` Service on port `8080`, a
Traefik Ingress with `letsencrypt-prod` TLS, a retained `5Gi`
`hcloud-volumes` RWO claim for SQLite, and an optional `BitwardenSecret`.
Attic objects live in Mega S4; only the SQLite metadata database lives on the
volume. The Deployment uses `Recreate` so upgrades cannot trigger a Hetzner
volume multi-attach failure.

Before installing, provide:

- A Mega S4 bucket and S3 application key. Defaults assume region
  `eu-central-1`, endpoint `https://s3.eu-central-1.s4.mega.io`, and bucket
  `attic`; change `server.storage.bucket` if the created bucket differs. Attic
  automatically uses path-style addressing for a custom S3 endpoint.
- The Bitwarden Secrets Manager operator and an `attic/bw-auth-token` Secret.
- Traefik, cert-manager, and the existing `letsencrypt-prod` ClusterIssuer.
- DNS for `attic.jeiang.dev` pointing to Traefik's load balancer.
- A selected Kubernetes node labeled for the Attic workload:

  ```sh
  kubectl label node <node-name> workload.jeiang.dev/attic=true --overwrite
  ```

  The Deployment's default node selector requires this label. Confirm the
  chosen node is ready before deploying with `kubectl get nodes -o wide`.

## Create credentials

Generate a PKCS#1 RSA private key and store its single-line base64 form in
Bitwarden Secrets Manager. Keep the PEM and encoded key out of this repository:

```sh
openssl genrsa -traditional -out attic-token-rs256.pem 4096
base64 < attic-token-rs256.pem | tr -d '\n'
```

Create three Bitwarden Secrets Manager entries containing:

1. The Mega S4 access key ID.
2. The Mega S4 secret access key.
3. The base64 PKCS#1 private key from above.

Set `bitwardenSecrets.enabled: true`, the Bitwarden organization ID, and those
three entry IDs in `values.yaml`. The IDs identify external secrets; do not put
credential values in the file. The resulting Kubernetes Secret is
`attic-secrets` with keys `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and
`ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64`.

Create the namespace-local operator bootstrap Secret before Helm waits for the
Deployment. Read the machine-account token without putting it in shell history:

```fish
kubectl create namespace attic --dry-run=client -o yaml | kubectl apply -f -
read --silent --prompt-str 'Bitwarden machine account token: ' BW_AUTH_TOKEN
echo
kubectl -n attic create secret generic bw-auth-token \
  --from-literal=token="$BW_AUTH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
set --erase BW_AUTH_TOKEN
```

Alternatively, create `attic-secrets` out of band and leave
`bitwardenSecrets.enabled: false`. Never pass secret values with Helm `--set`:
they can be recorded in Helm release state and shell history.

## GitHub Actions OIDC

The enabled `github-actions` provider follows the fork's exact schema and
denies access unless every configured claim matches. Its initial rule trusts
only immutable repository ID `1297481441` (`jeiang/attic`), protected
`refs/heads/main`, and grants pull/push on `attic-ci`. It grants none of the
cache administration permissions (`cc`, `cr`, `cq`, `cd`) and no delete access.

This rule is deliberately fail-closed. GitHub's public branch API currently
reports `jeiang/attic` `main` as `protected: false`, so no current workflow can
match `ref_protected: "true"`. Before removing the static token or expecting
OIDC login to work, add branch protection or a repository ruleset that protects
`main`, then verify it:

```sh
gh api repos/jeiang/attic/branches/main \
  --jq '{name: .name, protected: .protected}'
```

The required result is `{"name":"main","protected":true}`. Do not change
the claim to `ref_protected: "false"`; the immutable repository ID, exact ref,
and protected status are the authorization boundary.

Add repositories as additional entries under `oidc.githubActions.rules`. Use
the numeric `repository_id`, an explicit ref, and `ref_protected: "true"`;
repository names and other mutable claims are not an adequate boundary. The
`jeiang/k8s-manifests` repository ID is `1258439963` if this repository later
needs its own rule.

### Migrate the fork workflows

OIDC is **not currently active** in the fork's cache-using workflows.
`build.yml` configures Attic in the `build`, `tests`, `nix-matrix`, and
`nix-matrix-job` jobs, and `lint.yml` configures it in the `lint` job. Those
jobs currently call `.github/install-attic-ci.sh`, which installs a client from
hard-coded upstream `staging.attic.rs` store paths, performs token login, and
does not request `id-token: write`. That older client may not recognize
`--oidc`.

Migrate every one of those five jobs as a single change:

1. Stop calling `.github/install-attic-ci.sh`. Install the OIDC-capable client
   pinned to the same reviewed fork commit as the server:

   ```sh
   nix profile install 'github:jeiang/attic/586bcd9af71218c9b7f784bd22fa65b5c763d1c8#attic-client'
   ```

2. Give each applicable job (or its workflow, if intentionally shared by all
   jobs) only the required permissions:

   ```yaml
   permissions:
     contents: read
     id-token: write
   ```

3. Set `ATTIC_SERVER=https://attic.jeiang.dev/` and
   `ATTIC_CACHE=attic-ci`. Replace token login with the fork's OIDC flow:

   ```yaml
   - name: Configure Attic cache
     if: github.event_name == 'push' && github.ref == 'refs/heads/main'
     run: |
       attic login --set-default ci "$ATTIC_SERVER" --oidc github-actions
       attic use "$ATTIC_CACHE"
   ```

4. Apply that same `if` condition to Attic pushes and any cache-only step. Jobs
   must continue normally without `ATTIC_CACHE` when the condition is false.
   The configured server rule permits only protected pushes whose ref is
   exactly `refs/heads/main`; pull-request refs and unprotected branches are
   intentionally excluded. Supporting PRs would require a separate, narrowly
   reviewed read-only rule rather than broadening this one.

5. Only after branch protection reports `true` and an OIDC run succeeds,
   remove the old token from job environments and repository/environment
   secrets. No `ATTIC_TOKEN` is needed after migration.

For reference, the resulting authenticated steps use:

```yaml
permissions:
  contents: read
  id-token: write

steps:
  - uses: actions/checkout@v7
  - run: nix profile install 'github:jeiang/attic/586bcd9af71218c9b7f784bd22fa65b5c763d1c8#attic-client'
  - if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    run: |
      attic login --set-default ci "$ATTIC_SERVER" --oidc github-actions
      attic use "$ATTIC_CACHE"
  - if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    run: attic push "$ATTIC_CACHE" result
```

The fork workflow edits are intentionally outside this Kubernetes chart. This
runbook describes them but does not imply the current fork workflows support
OIDC. GitHub OIDC grants access to an existing cache; it does not create one.

Pocket ID uses a public PKCE client with `http://127.0.0.1:*/callback` as its
registered callback. Set that client's ID as `oidc.pocketId.audience`; an empty
audience is rejected when the provider is enabled.

The default Pocket ID rules use the `attic_role` custom claim across all caches:

- `admin` has pull, push, delete, cache creation, cache configuration, retention
  configuration, and cache destruction permissions.
- `writer` has pull and push permissions.
- `reader` has pull permission.

Configure Pocket ID to include exactly one of those scalar claim values in the
ID token. Identities with a missing or different `attic_role` value receive no
Attic permissions. Then log in with:

```sh
attic login --set-default pocketid https://attic.jeiang.dev/ --oidc pocketid
```

## Validate and install

Review the bucket name and Bitwarden IDs, then run:

```sh
helm lint ./attic
helm template attic ./attic --namespace attic
helm upgrade --install attic ./attic \
  --namespace attic \
  --create-namespace
```

The repository's **Helm Deploy** workflow can run the same install after
`bw-auth-token`, Bitwarden entries, the bucket, and DNS exist.

## Initialize the cache

After the first rollout, mint a short-lived bootstrap token from the running
server. The pinned fork supports these exact flags:

```sh
kubectl -n attic exec deployment/attic -- \
  /bin/atticadm -f /etc/attic/server.toml make-token \
  --sub bootstrap \
  --validity '15 minutes' \
  --pull attic-ci \
  --push attic-ci \
  --create-cache attic-ci \
  --configure-cache attic-ci
```

Copy the printed token into a temporary local variable, create the cache, then
erase it:

```fish
read --silent --prompt-str 'Short-lived Attic bootstrap token: ' ATTIC_BOOTSTRAP_TOKEN
echo
attic login --set-default bootstrap https://attic.jeiang.dev/ "$ATTIC_BOOTSTRAP_TOKEN"
attic cache create attic-ci
set --erase ATTIC_BOOTSTRAP_TOKEN
```

Keep the token local and out of GitHub. Do not add `cc` to the CI rule merely to
bootstrap the cache. Remove the `bootstrap` client login after initialization if
the local client keeps the expired token.

Before testing OIDC, confirm all of these are true:

- GitHub reports `main` as protected.
- `attic-ci` already exists.
- All five applicable jobs install the pinned fork client.
- Those jobs have `contents: read` and `id-token: write`.
- Token login has been replaced by the guarded OIDC login/use steps above.

Then verify OIDC from a protected `main` push workflow:

```sh
attic login --set-default ci "$ATTIC_SERVER" --oidc github-actions
attic use attic-ci
```

## Verify and troubleshoot

```sh
kubectl -n attic get bitwardensecret,secret,pvc,deploy,pods,svc,ingress
kubectl -n attic rollout status deployment/attic --timeout=5m
kubectl -n attic logs deployment/attic
kubectl -n attic get certificate attic-tls
curl -fsS https://attic.jeiang.dev/
```

- `CreateContainerConfigError` usually means `attic-secrets` or one of its
  three mapped keys is missing.
- S3 authorization errors usually mean the Mega key lacks bucket access, the
  bucket/region differs from `values.yaml`, or the endpoint is wrong.
- TLS problems require checking DNS, the Ingress, Certificate, and
  `letsencrypt-prod` events.
- An OIDC `403` usually means one of the verified claims does not match. Check
  the repository ID, exact `refs/heads/main` ref, branch protection status, and
  canonical audience; do not loosen the server rule to make the error vanish.
- OIDC login is expected to be skipped on pull requests and unprotected branch
  pushes. Those jobs should run without the Attic cache.
- If `attic login` rejects `--oidc`, the job is still using the old
  `.github/install-attic-ci.sh` staging client instead of the pinned fork
  client.
- Leave `ingress.crowdsecMiddleware` empty initially. Traefik AppSec performs
  request-body inspection and can reject or limit large NAR uploads; enable
  `crowdsec-appsec@file` only after testing representative pushes and reviewing
  middleware body-size settings. The global IP bouncer remains independent.

## Backup and uninstall

Back up both parts of the service together: copy/version the Mega bucket and
snapshot the Hetzner volume containing `/data/attic.db` while Attic is stopped
so SQLite is consistent. Bucket data without the database is not a complete
backup, and the database without objects cannot restore cache contents.

```sh
kubectl -n attic scale deployment/attic --replicas=0
# Snapshot the PVC's Hetzner volume, and back up the Mega S4 bucket.
kubectl -n attic scale deployment/attic --replicas=1
```

`helm uninstall attic --namespace attic` retains the PVC because it has
`helm.sh/resource-policy: keep`. It also does not delete the Mega bucket,
Bitwarden entries, TLS Secret, or namespace. Delete those only after verifying
the backup and retention requirements.
