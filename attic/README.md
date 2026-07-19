# Attic

Helm chart for the OIDC-enabled [`jeiang/attic`](https://github.com/jeiang/attic)
fork, backed by Mega S4 and exposed at `https://attic.jeiang.dev/`.

The image is pinned to the multi-architecture Nix build at
`ghcr.io/jeiang/attic:7e0a356cf10ed1a6b4bb5b565faed8be35d5607e`.
That commit supports OIDC token exchange and ships a database migration that
adds indexes on `cache.deleted_at` and `object.store_path_hash`, so scale the
Deployment to zero before upgrading to it (see below). It does not use a
Dockerfile: the fork's container workflow builds `attic-server-image` from
`flake/packages.nix`.

## Architecture and prerequisites

The chart creates one Attic server, a `ClusterIP` Service on port `8080`, a
Traefik Ingress with `letsencrypt-prod` TLS, and an optional `BitwardenSecret`.
The workload is stateless: Attic objects live in Mega S4 and cache metadata
lives in an external Supabase-hosted PostgreSQL database, so the Deployment
uses the default `RollingUpdate` strategy and needs no volume.

The PostgreSQL connection URL contains credentials and is delivered only
through the synced Secret as `ATTIC_SERVER_DATABASE_URL`; the rendered
`server.toml` deliberately omits `database.url`. Database heartbeat queries
are enabled (`server.database.heartbeat: true`) so broken connections to the
remote database are detected instead of failing the next request. Pod egress
is IPv4-only (the nodes are dual-stack, the pod network is not), so the URL
must point at a Supabase host reachable over IPv4 — the Supavisor **session**
pooler (port `5432`) or the paid IPv4 add-on, not the IPv6-only direct host.
Do not use the transaction-mode pooler on port `6543`: the server uses
prepared statements, which transaction pooling does not support reliably.

The server is limited to two concurrent NAR uploads so upload, compression,
and allocator memory fit within the pod's `512Mi` limit. The fork's global
limit of ten concurrent chunk uploads and its default connection-pool sizing
remain appropriate and are left unset.
Attic application targets log at `debug` while dependencies remain at `info`,
using `server.logFilter: info,attic_server=debug` and the standard `RUST_LOG`
filter consumed by `atticd`.

Before installing, provide:

- A Mega S4 bucket and S3 application key. Defaults assume region
  `eu-central-1`, endpoint `https://s3.eu-central-1.s4.mega.io`, and bucket
  `attic`; change `server.storage.bucket` if the created bucket differs. Attic
  automatically uses path-style addressing for a custom S3 endpoint.
- A Supabase PostgreSQL database (us-east) reachable over IPv4, with a
  dedicated database (or schema) for Attic. The server runs its own
  migrations on startup; the connecting role must be able to create tables.
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

Create four Bitwarden Secrets Manager entries containing:

1. The Mega S4 access key ID.
2. The Mega S4 secret access key.
3. The base64 PKCS#1 private key from above.
4. The Supabase PostgreSQL connection URL, in the form
   `postgresql://<user>:<password>@<ipv4-capable-host>:5432/<database>`.
   Use the session pooler host; URL-encode any special characters in the
   password.

Set `bitwardenSecrets.enabled: true`, the Bitwarden organization ID, and those
four entry IDs in `values.yaml` (`bitwardenSecrets.secretIds.databaseUrl` is
the new one; rendering fails while it is empty). The IDs identify external
secrets; do not put credential values in the file. The resulting Kubernetes
Secret is `attic-secrets` with keys `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64`, and
`ATTIC_SERVER_DATABASE_URL`.

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
denies access unless every configured claim matches. Its rule trusts immutable
repository owner ID `31970261` (`jeiang`) and protected refs in any repository
owned by that account. It grants pull/push on `default`, with no delete or cache
administration permissions (`cc`, `cr`, `cq`, `cd`). Repositories owned by an
organization or another user do not match, even when `jeiang` can contribute.

A second rule matches immutable repository owner ID `31970261` without
restricting the repository, ref, or branch-protection status, but grants only
pull access to `default`. Pull-request and unprotected-ref workflows in any
repository owned by `jeiang` can therefore consume the cache without being able
to modify it. Attic merges matching grants, so protected refs receive pull/push
from the stricter rule while retaining no delete or administration permissions.

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
the claim to `ref_protected: "false"`; the immutable owner ID and protected
status are the authorization boundary.

Use numeric `repository_id` to narrow any future repository-specific rules. Add
explicit `ref` and `ref_protected: "true"` claims before granting push.
Repository or owner names are mutable and are not an adequate authorization
boundary.

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
   nix profile install 'github:jeiang/attic/828b7ba583afae9523cda1c66d466ea430ea0160#attic-client'
   ```

2. Give each applicable job (or its workflow, if intentionally shared by all
   jobs) only the required permissions:

   ```yaml
   permissions:
     contents: read
     id-token: write
   ```

3. Set `ATTIC_SERVER=https://attic.jeiang.dev/` and
   `ATTIC_CACHE=default`. Replace token login with the fork's OIDC flow:

   ```yaml
   - name: Configure Attic cache
     if: github.event_name == 'push' && github.ref == 'refs/heads/main'
     run: |
       attic login --set-default ci "$ATTIC_SERVER" --oidc github-actions
       attic use "$ATTIC_CACHE"
   ```

4. Apply that same `if` condition to Attic pushes and any cache-only step. Jobs
   must continue normally without `ATTIC_CACHE` when the condition is false.
   The configured server rule permits protected refs in repositories owned by
   `jeiang`; pull-request refs and unprotected branches are intentionally
   excluded. Supporting PRs would require a separate, narrowly reviewed
   read-only rule rather than broadening this one.

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
  - run: nix profile install 'github:jeiang/attic/828b7ba583afae9523cda1c66d466ea430ea0160#attic-client'
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

The fork's CI pins its own client (`ATTIC_CLIENT_PIN` in the workflow files)
to the same commit as this chart's server image. Routine commits do not need
a pin bump; bump both together on major client-relevant updates — a new
upload protocol, additional server features the client must speak, or
security fixes — and pre-seed the cache with the newly pinned client build
so CI does not compile it from source.

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

When the incoming image contains a database migration (chart `0.2.1`'s index
migration, and any future migrating release), stop the running server first so
the old pod does not serve traffic against a schema mid-migration under the
default `RollingUpdate` strategy:

```sh
kubectl -n attic scale deployment/attic --replicas=0
```

The subsequent `helm upgrade` restores the chart's `replicaCount`. The server
runs its migrations on startup.

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

## Migrating from the SQLite deployment

Attic has no built-in SQLite-to-PostgreSQL migration. Starting against an
empty Supabase database means the server recreates the schema and the
`default` cache must be re-initialized (next section); previously uploaded
store paths are forgotten, and their objects remain orphaned in the Mega
bucket where garbage collection can no longer see them. For a clean start,
snapshot the old Hetzner volume, empty (or recreate) the `attic` bucket, and
re-run cache initialization. Copying existing rows with a tool such as
`pgloader` is possible in principle but is not a supported or tested path;
the fresh start loses only cache/dedup history, not source data.

Reset sequence, with the old deployment stopped first so nothing writes
mid-wipe:

```sh
kubectl -n attic scale deployment/attic --replicas=0
# Snapshot the Hetzner volume backing the old SQLite PVC in the Hetzner
# console (or via `hcloud volume` tooling) before destroying anything.
```

Empty the bucket with the same Mega S4 credentials stored in Bitwarden,
read into the environment without echoing into shell history:

```fish
read --silent --prompt-str 'Mega S4 access key ID: ' --export AWS_ACCESS_KEY_ID
read --silent --prompt-str 'Mega S4 secret access key: ' --export AWS_SECRET_ACCESS_KEY
aws s3 rm s3://attic --recursive \
  --endpoint-url https://s3.ca-montreal.megas4.com \
  --region ca-montreal
aws s3 ls s3://attic --recursive \
  --endpoint-url https://s3.ca-montreal.megas4.com \
  --region ca-montreal
set --erase AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
```

The final `ls` must print nothing. Then deploy chart `0.2.0` and continue
with cache initialization below.

## Initialize the cache

After the first rollout, mint a short-lived bootstrap token from the running
server. The pinned fork supports these exact flags:

```sh
kubectl -n attic exec deployment/attic -- \
  /bin/atticadm -f /etc/attic/server.toml make-token \
  --sub bootstrap \
  --validity '15 minutes' \
  --pull default \
  --push default \
  --create-cache default \
  --configure-cache default
```

Copy the printed token into a temporary local variable, create the cache, then
erase it:

```fish
read --silent --prompt-str 'Short-lived Attic bootstrap token: ' ATTIC_BOOTSTRAP_TOKEN
echo
attic login --set-default bootstrap https://attic.jeiang.dev/ "$ATTIC_BOOTSTRAP_TOKEN"
attic cache create default
set --erase ATTIC_BOOTSTRAP_TOKEN
```

Keep the token local and out of GitHub. Do not add `cc` to the CI rule merely to
bootstrap the cache. Remove the `bootstrap` client login after initialization if
the local client keeps the expired token.

Before testing OIDC, confirm all of these are true:

- GitHub reports `main` as protected.
- `default` already exists.
- All five applicable jobs install the pinned fork client.
- Those jobs have `contents: read` and `id-token: write`.
- Token login has been replaced by the guarded OIDC login/use steps above.

Then verify OIDC from a protected `main` push workflow:

```sh
attic login --set-default ci "$ATTIC_SERVER" --oidc github-actions
attic use default
```

## Verify and troubleshoot

```sh
kubectl -n attic get bitwardensecret,secret,deploy,pods,svc,ingress
kubectl -n attic rollout status deployment/attic --timeout=5m
kubectl -n attic logs deployment/attic
kubectl -n attic get certificate attic-tls
curl -fsS https://attic.jeiang.dev/
```

- `CreateContainerConfigError` usually means `attic-secrets` or one of its
  four mapped keys is missing.
- Database connection failures at startup usually mean the Supabase URL uses
  the IPv6-only direct host (pod egress is IPv4-only), the password needs
  URL-encoding, or Supabase network restrictions block the cluster egress
  address. Prepared-statement errors mean the URL points at the
  transaction-mode pooler (port `6543`); switch to the session pooler on
  `5432`.
- S3 authorization errors usually mean the Mega key lacks bucket access, the
  bucket/region differs from `values.yaml`, or the endpoint is wrong.
- TLS problems require checking DNS, the Ingress, Certificate, and
  `letsencrypt-prod` events.
- An OIDC `403` usually means one of the verified claims does not match. Check
  repository owner ID `31970261`, protected-ref status, and the canonical
  audience; do not loosen the server rule to make the error vanish.
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
dump the PostgreSQL database (`pg_dump` against the Supabase database, or
Supabase's own scheduled backups). Bucket data without the database is not a
complete backup, and the database without objects cannot restore cache
contents. Both can be backed up online; no scale-down is required.

`helm uninstall attic --namespace attic` does not delete the Supabase
database, Mega bucket, Bitwarden entries, TLS Secret, or namespace. Delete
those only after verifying the backup and retention requirements.

The retained PVC from the pre-0.2.0 SQLite deployment (`attic`, on
`hcloud-volumes`) is no longer referenced by the chart. Keep its Hetzner
volume snapshot until the PostgreSQL deployment is verified, then delete the
PVC manually.
