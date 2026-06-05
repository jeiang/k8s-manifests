# idp

Helm chart for running Pocket ID with LLDAP.

Default application version: Pocket ID `v2.6.2`.

By default this chart creates:

- Pocket ID at `https://auth.jeiang.dev`
- LLDAP at `https://lldap.jeiang.dev`
- Internal LDAP at `ldap://idp-lldap.idp.svc.cluster.local:3890`
- PersistentVolumes and PersistentVolumeClaims for Pocket ID and LLDAP state.
- A `ClusterIP` Service for Pocket ID.
- A `ClusterIP` Service for LLDAP HTTP and LDAP ports.
- Ingress TLS using the `idp-tls` Secret.

The Ingresses request cert-manager certificates with the `letsencrypt-prod` `ClusterIssuer`. Make sure `auth.jeiang.dev` and `lldap.jeiang.dev` point at the ingress load balancer before installing or upgrading.

## Generate Secrets

Generate the values locally:

```sh
LLDAP_JWT_SECRET="$(openssl rand -base64 48)"
LLDAP_KEY_SEED="$(openssl rand -base64 32)"
LLDAP_ADMIN_PASSWORD="$(openssl rand -base64 24)"
POCKET_ID_ENCRYPTION_KEY="$(openssl rand -base64 32)"
POCKET_ID_STATIC_API_KEY="$(openssl rand -hex 32)"
```

Create the namespace and secret:

```sh
kubectl create namespace idp --dry-run=client -o yaml | kubectl apply -f -

kubectl -n idp create secret generic idp-secrets \
  --from-literal=lldap-jwt-secret="$LLDAP_JWT_SECRET" \
  --from-literal=lldap-key-seed="$LLDAP_KEY_SEED" \
  --from-literal=lldap-admin-password="$LLDAP_ADMIN_PASSWORD" \
  --from-literal=pocket-id-encryption-key="$POCKET_ID_ENCRYPTION_KEY" \
  --from-literal=pocket-id-static-api-key="$POCKET_ID_STATIC_API_KEY"
```

Secret meanings:

- `lldap-jwt-secret`: LLDAP web-session JWT signing secret. Keep stable.
- `lldap-key-seed`: LLDAP password-storage key seed. Keep stable after first deploy.
- `lldap-admin-password`: password for the LLDAP `admin` user and Pocket ID LDAP bind. Keep stable unless deliberately rotating it.
- `pocket-id-encryption-key`: Pocket ID encryption key. Keep stable or encrypted data may become unreadable.
- `pocket-id-static-api-key`: Pocket ID static API key.

## Install

```sh
helm upgrade --install idp ./idp \
  --namespace idp \
  --create-namespace
```

If this replaces a previous OpenLDAP-based install, the old `idp-ldap-data` and `idp-ldap-config` PVCs are no longer used. LLDAP now uses the `idp-lldap` PVC.

Review the persistence defaults before installing. The chart creates hostPath-backed PersistentVolumes under `/var/lib/idp` with `Retain` reclaim policy:

```yaml
persistence:
  createPersistentVolumes: true
  storageClassName: ""
  reclaimPolicy: Retain
  hostPathBase: /var/lib/idp
```

## Bootstrap LLDAP

Use a port-forward for first setup:

```sh
kubectl -n idp port-forward svc/idp-lldap 17170:80
```

Open:

```text
http://localhost:17170
```

Login:

```text
Username: admin
Password: value of $LLDAP_ADMIN_PASSWORD
```

Create:

- A group named `_pocket_id_admins`
- Your first user with a valid email address
- Add that user to `_pocket_id_admins`

LDAP connection details:

```text
URL: ldap://idp-lldap.idp.svc.cluster.local:3890
Bind DN: uid=admin,ou=people,dc=jeiang,dc=dev
Base DN: dc=jeiang,dc=dev
Password: idp-secrets/lldap-admin-password
```

## Bootstrap Pocket ID

Wait for Pocket ID to sync LDAP:

```sh
kubectl -n idp logs deploy/idp-pocket-id --tail=100
```

Generate a one-time access token for the LDAP user you created:

```sh
POCKET_ID_POD="$(kubectl -n idp get pod \
  -l app.kubernetes.io/component=pocket-id \
  -o jsonpath='{.items[0].metadata.name}')"

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

Copy the generated client ID and client secret into `netbird/values.yaml`.
