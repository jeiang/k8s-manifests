# idp Values

These values configure the local Pocket ID and LLDAP Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `global.domain` | `jeiang.dev` | Base domain used by the stack. |
| `global.pocketIdHost` | `auth.jeiang.dev` | Public Pocket ID hostname. |
| `global.lldapHost` | `""` | Optional public LLDAP hostname when LLDAP ingress is enabled. |
| `secrets.existingSecret` | `idp-secrets` | Kubernetes Secret consumed by the workloads. |
| `secrets.keys` | Pocket ID, LLDAP, LDAP bind, and SMTP key names | Maps Secret keys to application settings. |
| `bitwardenSecrets.enabled` | `true` | Renders a `BitwardenSecret` for `idp-secrets`. |
| `bitwardenSecrets.organizationId` | `af918704-c223-4f10-a245-b4640144f2d9` | Bitwarden organization ID. |
| `bitwardenSecrets.authToken.secretName` | `bw-auth-token` | Namespace-local Bitwarden machine account token Secret. |
| `bitwardenSecrets.authToken.secretKey` | `token` | Token key inside `bw-auth-token`. |
| `bitwardenSecrets.secretIds` | UUIDs for LLDAP, Pocket ID, and SMTP secrets | Bitwarden Secrets Manager item IDs synced into `idp-secrets`. |
| `pocketId.replicaCount` | `1` | Runs one Pocket ID pod. |
| `pocketId.image` | `ghcr.io/pocket-id/pocket-id:v2.6.2`, `IfNotPresent` | Pocket ID container image settings. |
| `pocketId.waitForLldap.image` | `busybox:1.36`, `IfNotPresent` | Init container image used to wait for LDAP. |
| `pocketId.waitForLldap.resources` | `10m/16Mi` request, `50m/32Mi` limit | Init container resource settings. |
| `pocketId.port` | `1411` | Pocket ID container port. |
| `pocketId.smtp` | iCloud SMTP at `smtp.mail.me.com:587`, from `noreply@jeiang.dev`, user `jeiang`, `starttls` | Email delivery settings. |
| `pocketId.email` | verification and admin one-time access enabled; login notifications and unauthenticated codes disabled | Email feature switches. |
| `pocketId.signups.allowUserSignups` | `withToken` | Allows admin-issued signup tokens. |
| `pocketId.ldap.enabled` | `true` | Enables LDAP sync from LLDAP. |
| `pocketId.ldap.bindDn` | `uid=admin,ou=people,dc=jeiang,dc=dev` | LDAP bind DN. |
| `pocketId.ldap.baseDn` | `dc=jeiang,dc=dev` | LDAP base DN. |
| `pocketId.ldap.usersFilter` | `(objectClass=person)` | LDAP user filter. |
| `pocketId.ldap.groupsFilter` | `(objectClass=groupOfUniqueNames)` | LDAP group filter. |
| `pocketId.ldap.adminGroupName` | `_pocket_id_admins` | LDAP group mapped to Pocket ID admins. |
| `pocketId.ldap.attributes` | `entryUUID`, `uid`, `mail`, `givenName`, `sn`, `cn`, `uniqueMember` mappings | LDAP attribute mapping. |
| `pocketId.resources` | `100m/128Mi` request, `500m/512Mi` limit | Pocket ID resource settings. |
| `lldap.image` | `lldap/lldap:stable`, `IfNotPresent` | LLDAP container image settings. |
| `lldap.baseDn` | `dc=jeiang,dc=dev` | LLDAP base DN. |
| `lldap.uid` | `"1000"` | LLDAP process UID. |
| `lldap.gid` | `"1000"` | LLDAP process GID. |
| `lldap.timezone` | `UTC` | LLDAP timezone. |
| `lldap.ports.ldap` | `3890` | LLDAP LDAP port. |
| `lldap.ports.http` | `17170` | LLDAP web UI port. |
| `lldap.resources` | `100m/128Mi` request, `500m/512Mi` limit | LLDAP resource settings. |
| `service.pocketId` | `ClusterIP` port `80` | Internal Pocket ID service. |
| `service.lldap` | `ClusterIP`, LDAP `3890`, HTTP `80` | Internal LLDAP service. |
| `ingress.enabled` | `true` | Creates Pocket ID ingress. |
| `ingress.className` | `traefik` | Uses Traefik ingress. |
| `ingress.annotations` | `cert-manager.io/cluster-issuer: letsencrypt-prod` | Requests cert-manager TLS. |
| `ingress.tls.enabled` | `true` | Enables TLS. |
| `ingress.tls.secretName` | `idp-tls` | TLS Secret name. |
| `ingress.lldap.enabled` | `false` | Keeps LLDAP internal-only. |
| `persistence.createPersistentVolumes` | `false` | Uses dynamic provisioning instead of static PVs. |
| `persistence.storageClassName` | `hcloud-volumes` | Uses Hetzner RWO storage. |
| `persistence.reclaimPolicy` | `Retain` | Retains static PVs if that mode is enabled. |
| `persistence.hostPathBase` | `/var/lib/idp` | Static hostPath base if static PVs are enabled. |
| `persistence.pocketId.size` | `5Gi` | Pocket ID PVC size. |
| `persistence.lldap.size` | `2Gi` | LLDAP PVC size. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |
| `netbird.enabled` | `false` | Disables optional NetBird resource rendering by default. |
| `netbird.bitwardenSecrets.netbirdApi.enabled` | `false` | Prevents this chart from owning the shared NetBird API Secret. |
| `netbird.networkRouter.enabled` | `false` | Prevents this chart from owning the shared NetBird router. |
| `netbird.networkRouter.name` | `k8s` | References the shared router name. |
| `netbird.networkRouter.namespace` | `netbird` | References the shared router namespace. |
| `netbird.networkResources.enabled` | `true` | Allows workload-specific NetBird resources when the subchart is enabled. |
| `netbird.networkResources.resources` | `lldap` in namespace `idp` for group `lldap_admin` | Exposes LLDAP through NetBird. |

## Notes

- Secret values must remain in Bitwarden Secrets Manager; do not put literal secret values in `values.yaml`.
- `hcloud-volumes` is appropriate here because the default PVCs are small and RWO.
