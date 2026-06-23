# idp

Helm chart for running Pocket ID with LLDAP.

Default application version: Pocket ID `v2.6.2`.

## What This Chart Creates

- Pocket ID at `https://auth.jeiang.dev`.
- Internal LDAP at `ldap://idp-lldap.idp.svc.cluster.local:3890`.
- PersistentVolumeClaims for Pocket ID and LLDAP state.
- `ClusterIP` Services for Pocket ID and LLDAP.
- A Kubernetes Ingress resource for Pocket ID with cert-manager annotations.
- A Pocket ID init container that waits for LLDAP's LDAP port before startup.
- An optional `BitwardenSecret` that syncs `idp-secrets` from Bitwarden Secrets Manager.
- An optional NetBird `NetworkResource` for the LLDAP Service when `netbird.enabled=true`.
- Resource limits for Pocket ID, LLDAP, and the Pocket ID wait init container.

## Dependencies

- Helm 3, `kubectl`, and `openssl` for secret generation.
- Traefik installed with an IngressClass named `traefik`.
- cert-manager CRDs/controller installed and a `letsencrypt-prod` `ClusterIssuer`.
- A DNS record for `auth.jeiang.dev` pointing at the ingress load balancer.
- A pre-created `idp-secrets` Secret with the keys listed below.
- Bitwarden Secrets Manager operator CRDs if `bitwardenSecrets.enabled=true`.
- Hetzner CSI installed with the RWO `hcloud-volumes` StorageClass.
- NetBird operator CRDs if `netbird.enabled=true`.

## Generate Secrets

Generate the values locally:

```fish
set LLDAP_JWT_SECRET (openssl rand -base64 48)
set LLDAP_KEY_SEED (openssl rand -base64 32)
set LLDAP_ADMIN_PASSWORD (openssl rand -base64 24)
set POCKET_ID_ENCRYPTION_KEY (openssl rand -base64 32)
set POCKET_ID_STATIC_API_KEY (openssl rand -hex 32)
```

Create the namespace and secret:

```fish
kubectl create namespace idp --dry-run=client -o yaml | kubectl apply -f -

kubectl -n idp create secret generic idp-secrets \
  --from-literal=lldap-jwt-secret="$LLDAP_JWT_SECRET" \
  --from-literal=lldap-key-seed="$LLDAP_KEY_SEED" \
  --from-literal=lldap-admin-password="$LLDAP_ADMIN_PASSWORD" \
  --from-literal=pocket-id-encryption-key="$POCKET_ID_ENCRYPTION_KEY" \
  --from-literal=pocket-id-static-api-key="$POCKET_ID_STATIC_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Secret meanings:

- `lldap-jwt-secret`: LLDAP web-session JWT signing secret. Keep stable.
- `lldap-key-seed`: LLDAP password-storage key seed. Keep stable after first deploy.
- `lldap-admin-password`: password for the LLDAP `admin` user and Pocket ID LDAP bind. Keep stable unless deliberately rotating it.
- `pocket-id-encryption-key`: Pocket ID encryption key. Keep stable or encrypted data may become unreadable.
- `pocket-id-static-api-key`: Pocket ID static API key.

## Bitwarden Secrets Manager

Instead of creating `idp-secrets` with `kubectl create secret`, enable the chart-managed `BitwardenSecret`. Create matching secrets in Bitwarden Secrets Manager, then set the organization ID and Bitwarden secret IDs:

```fish
helm upgrade --install idp ./idp \
  --namespace idp \
  --create-namespace \
  --set bitwardenSecrets.enabled=true \
  --set bitwardenSecrets.organizationId=replace-with-organization-uuid \
  --set bitwardenSecrets.secretIds.lldapJwtSecret=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.lldapKeySeed=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.lldapAdminPassword=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.pocketIdEncryptionKey=replace-with-secret-uuid \
  --set bitwardenSecrets.secretIds.pocketIdStaticApiKey=replace-with-secret-uuid
```

The Bitwarden machine-account token Secret must already exist in the `idp` namespace:

```fish
kubectl -n idp get secret bw-auth-token
```

## Install

```fish
helm lint ./idp
helm template idp ./idp --namespace idp
helm upgrade --install idp ./idp \
  --namespace idp \
  --create-namespace
```

The NetBird integration is disabled by default. Enable it after installing the shared NetBird router and operator resources:

```fish
helm dependency build ./idp

helm upgrade --install idp ./idp \
  --namespace idp \
  --create-namespace \
  --set netbird.enabled=true
```

With the default values, that creates a `NetworkResource` named `lldap` in the `idp` namespace for `lldap.idp.k8s.jeiang.vpn`.

Review the persistence defaults before installing. The chart uses dynamic provisioning through the Hetzner CSI-backed `hcloud-volumes` StorageClass:

```yaml
persistence:
  createPersistentVolumes: false
  storageClassName: hcloud-volumes
netbird:
  enabled: false
```

If this replaces a previous OpenLDAP-based install, the old `idp-ldap-data` and `idp-ldap-config` PVCs are no longer used. LLDAP now uses the `idp-lldap` PVC.

LLDAP is internal-only by default. The chart creates a `ClusterIP` Service and does not create an LLDAP Ingress unless `ingress.lldap.enabled=true` and `global.lldapHost` is set explicitly.

## Bootstrap LLDAP

Use a port-forward for first setup:

```fish
kubectl -n idp port-forward svc/idp-lldap 17170:80
```

Open `http://localhost:17170` and log in:

```text
Username: admin
Password: value of $LLDAP_ADMIN_PASSWORD
```

Create:

- A group named `_pocket_id_admins`.
- Your first user with a valid email address.
- Add that user to `_pocket_id_admins`.

LDAP connection details:

```text
URL: ldap://idp-lldap.idp.svc.cluster.local:3890
Bind DN: uid=admin,ou=people,dc=jeiang,dc=dev
Base DN: dc=jeiang,dc=dev
Password: idp-secrets/lldap-admin-password
```

## Bootstrap Pocket ID

Wait for Pocket ID to sync LDAP:

```fish
kubectl -n idp logs deploy/idp-pocket-id --tail=100
```

Generate a one-time access token for the LDAP user you created:

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
