# idp

Helm chart for running Pocket ID as the cluster identity provider.

Default application version: Pocket ID `v2.6.2`.

## Contents

- [What This Chart Creates](#what-this-chart-creates)
- [Dependencies](#dependencies)
- [Generate Bitwarden Secrets](#generate-bitwarden-secrets)
- [Email Delivery](#email-delivery)
- [Bitwarden Secrets Manager](#bitwarden-secrets-manager)
- [Migrate From LLDAP](#migrate-from-lldap)
- [Install](#install)
- [Bootstrap Pocket ID](#bootstrap-pocket-id)
- [Create NetBird OIDC Client](#create-netbird-oidc-client)
- [Values](#values)

## What This Chart Creates

- Pocket ID at `https://auth.jeiang.dev`.
- A PersistentVolumeClaim for Pocket ID state.
- A `ClusterIP` Service for Pocket ID.
- A Kubernetes Ingress resource for Pocket ID with cert-manager annotations.
- A `BitwardenSecret` that syncs `idp-secrets` from Bitwarden Secrets Manager.
- Pocket ID email delivery through iCloud SMTP as `noreply@jeiang.dev`.
- Resource limits for Pocket ID.

Pocket ID is the source of truth for users and groups. This chart does not render LLDAP, LDAP sync settings, LDAP bind secrets, or NetBird resources for LDAP access.

## Dependencies

- Helm 3, `kubectl`, and `openssl` for generating initial secret values.
- Traefik installed with an IngressClass named `traefik`.
- cert-manager CRDs/controller installed and a `letsencrypt-prod` `ClusterIssuer`.
- A DNS record for `auth.jeiang.dev` pointing at the ingress load balancer.
- Bitwarden Secrets Manager operator CRDs.
- A `bw-auth-token` Secret in the `idp` namespace so the Bitwarden operator can sync `idp-secrets`.
- iCloud Custom Email Domain configured so `noreply@jeiang.dev` can send mail.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.

## Generate Bitwarden Secrets

Generate the values locally:

```fish
set POCKET_ID_ENCRYPTION_KEY (openssl rand -base64 32)
set POCKET_ID_STATIC_API_KEY (openssl rand -hex 32)
```

Generate an Apple app-specific password for Pocket ID and store it in Bitwarden Secrets Manager as the `pocket-id-smtp-password` value. The default Bitwarden secret ID for this value is `53cbe1aa-8d71-4d73-9743-b47500233cc2`.

Store each generated value in Bitwarden Secrets Manager and put the resulting Bitwarden secret IDs in `values.yaml` under `bitwardenSecrets.secretIds`. The chart syncs them into the Kubernetes Secret named `idp-secrets`.

Secret meanings:

- `pocket-id-encryption-key`: Pocket ID encryption key. Keep stable or encrypted data may become unreadable.
- `pocket-id-static-api-key`: Pocket ID static API key.
- `pocket-id-smtp-password`: Apple app-specific password used by Pocket ID to authenticate to iCloud SMTP.

## Email Delivery

Pocket ID sends email through iCloud SMTP by default:

```yaml
pocketId:
  smtp:
    enabled: true
    host: smtp.mail.me.com
    port: 587
    from: noreply@jeiang.dev
    user: jeiang
    tls: starttls
```

The chart uses `SMTP_PASSWORD_FILE` and mounts the Bitwarden-synced `pocket-id-smtp-password` key as a file. Do not put the Apple app-specific password directly in `values.yaml`.

The default email features enable verification emails and admin-sent one-time access emails. Unauthenticated email login codes stay disabled because they weaken the passkey login model.

User signups are enabled with admin-issued signup tokens:

```yaml
pocketId:
  signups:
    allowUserSignups: withToken
```

## Bitwarden Secrets Manager

The chart-managed `BitwardenSecret` is enabled by default. Create matching secrets in Bitwarden Secrets Manager, then set the organization ID and Bitwarden secret IDs:

```fish
helm upgrade --install idp ./idp \
  --namespace idp \
  --create-namespace \
  --set bitwardenSecrets.enabled=true \
  --set bitwardenSecrets.organizationId=replace-with-organization-uuid \
  --set bitwardenSecrets.secretIds.pocketIdEncryptionKey=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.pocketIdStaticApiKey=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.pocketIdSmtpPassword=53cbe1aa-8d71-4d73-9743-b47500233cc2
```

The Bitwarden machine-account token Secret must already exist in the `idp` namespace:

```fish
kubectl create namespace idp --dry-run=client -o yaml | kubectl apply -f -
kubectl -n idp get secret bw-auth-token
```

## Migrate From LLDAP

Use in-place adoption when upgrading an existing Pocket ID plus LLDAP install. Pocket ID should keep the users and groups that were already synced from LLDAP, then run without LDAP configured.

Before applying this chart:

```fish
kubectl -n idp logs deploy/idp-pocket-id --tail=200
kubectl -n idp get pvc idp-lldap
kubectl -n idp get pvc idp-pocket-id
```

In the Pocket ID admin UI, confirm the expected users and groups are present. Confirm at least one administrator can still access Pocket ID.

Back up Pocket ID before the upgrade. Use a storage snapshot if available, or copy the SQLite database from a running pod:

```fish
set POCKET_ID_POD (kubectl -n idp get pod \
  -l app.kubernetes.io/component=pocket-id \
  -o jsonpath='{.items[0].metadata.name}')

kubectl -n idp cp "$POCKET_ID_POD":/app/data/pocket-id.db /tmp/pocket-id.db.backup
```

Preserve the legacy LLDAP volume before the upgrade so rollback remains possible:

```fish
kubectl -n idp annotate pvc idp-lldap helm.sh/resource-policy=keep --overwrite
```

Keep the old LLDAP Bitwarden items temporarily, but remove them from chart-managed sync. The new chart no longer maps `lldap-jwt-secret`, `lldap-key-seed`, or `lldap-admin-password` into `idp-secrets`.

After upgrading, verify:

```fish
kubectl -n idp rollout status deploy/idp-pocket-id
kubectl -n idp logs deploy/idp-pocket-id --tail=100
```

Then verify login, admin access, and OIDC `groups` claims for Kubernetes and NetBird clients. After a successful verification window, manually delete the retained LLDAP PVC/PV and old LLDAP Bitwarden secret items.

## Install

```fish
helm lint ./idp
helm template idp ./idp --namespace idp
helm upgrade --install idp ./idp \
  --namespace idp \
  --create-namespace
```

Review the persistence defaults before installing. The chart uses dynamic provisioning through the Hetzner CSI-backed `hcloud-volumes` StorageClass:

```yaml
persistence:
  createPersistentVolumes: false
  storageClassName: hcloud-volumes
```

## Bootstrap Pocket ID

After Pocket ID is running, trigger an email verification message or send a one-time access code from the admin UI to verify iCloud SMTP delivery.

Generate a one-time access token for a user:

```fish
set POCKET_ID_POD (kubectl -n idp get pod \
  -l app.kubernetes.io/component=pocket-id \
  -o jsonpath='{.items[0].metadata.name}')

kubectl -n idp exec "$POCKET_ID_POD" -- \
  /app/pocket-id one-time-access-token your-user-or-email
```

Use the printed URL to log in at `https://auth.jeiang.dev` and register a passkey.

## Create NetBird OIDC Client

In Pocket ID, create an OIDC client for NetBird:

```text
Name: NetBird
Callback URL: https://netbird.jeiang.dev/nb-auth
Scopes: openid profile email groups
```

Copy the generated client ID and client secret into `netbird/values.yaml` if you configure NetBird to use this external IdP.

## Values

See [`VALUES.md`](./VALUES.md) for the local values documented with defaults and operational notes.
