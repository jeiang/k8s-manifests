# idp Values

These values configure the local Pocket ID Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `global.domain` | `jeiang.dev` | Base domain used by the stack. |
| `global.pocketIdHost` | `auth.jeiang.dev` | Public Pocket ID hostname. |
| `secrets.existingSecret` | `idp-secrets` | Kubernetes Secret consumed by Pocket ID. |
| `secrets.keys.pocketIdEncryptionKey` | `pocket-id-encryption-key` | Secret key containing the Pocket ID encryption key. |
| `secrets.keys.pocketIdStaticApiKey` | `pocket-id-static-api-key` | Secret key containing the Pocket ID static API key. |
| `secrets.keys.pocketIdSmtpPassword` | `pocket-id-smtp-password` | Secret key containing the SMTP password. |
| `bitwardenSecrets.enabled` | `true` | Renders a `BitwardenSecret` for `idp-secrets`. |
| `bitwardenSecrets.organizationId` | `af918704-c223-4f10-a245-b4640144f2d9` | Bitwarden organization ID. |
| `bitwardenSecrets.authToken.secretName` | `bw-auth-token` | Namespace-local Bitwarden machine account token Secret. |
| `bitwardenSecrets.authToken.secretKey` | `token` | Token key inside `bw-auth-token`. |
| `bitwardenSecrets.secretIds.pocketIdEncryptionKey` | `d617ec9e-e4b2-4be1-b2e6-b465002842e5` | Bitwarden item ID synced as the Pocket ID encryption key. |
| `bitwardenSecrets.secretIds.pocketIdStaticApiKey` | `3c30732f-f3e3-4f68-bbbe-b46500284379` | Bitwarden item ID synced as the Pocket ID static API key. |
| `bitwardenSecrets.secretIds.pocketIdSmtpPassword` | `53cbe1aa-8d71-4d73-9743-b47500233cc2` | Bitwarden item ID synced as the SMTP password when SMTP is enabled. |
| `pocketId.replicaCount` | `1` | Runs one Pocket ID pod. |
| `pocketId.image` | `ghcr.io/pocket-id/pocket-id:v2.6.2`, `IfNotPresent` | Pocket ID container image settings. |
| `pocketId.port` | `1411` | Pocket ID container port. |
| `pocketId.smtp` | iCloud SMTP at `smtp.mail.me.com:587`, from `noreply@jeiang.dev`, user `jeiang`, `starttls` | Email delivery settings. |
| `pocketId.email` | verification and admin one-time access enabled; login notifications and unauthenticated codes disabled | Email feature switches. |
| `pocketId.signups.allowUserSignups` | `withToken` | Allows admin-issued signup tokens. |
| `pocketId.resources` | `50m/64Mi` request, `250m/256Mi` limit | Pocket ID resource settings. |
| `service.pocketId` | `ClusterIP` port `80` | Internal Pocket ID service. |
| `ingress.enabled` | `true` | Creates Pocket ID ingress. |
| `ingress.className` | `traefik` | Uses Traefik ingress. |
| `ingress.annotations` | `cert-manager.io/cluster-issuer: letsencrypt-prod` | Requests cert-manager TLS. |
| `ingress.tls.enabled` | `true` | Enables TLS. |
| `ingress.tls.secretName` | `idp-tls` | TLS Secret name. |
| `persistence.createPersistentVolumes` | `false` | Uses dynamic provisioning instead of static PVs. |
| `persistence.storageClassName` | `hcloud-volumes` | Uses Hetzner RWO storage. |
| `persistence.reclaimPolicy` | `Retain` | Retains static PVs if that mode is enabled. |
| `persistence.hostPathBase` | `/var/lib/idp` | Static hostPath base if static PVs are enabled. |
| `persistence.pocketId.size` | `5Gi` | Pocket ID PVC size. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |

## Notes

- Secret values must remain in Bitwarden Secrets Manager; do not put literal secret values in `values.yaml`.
- `hcloud-volumes` is appropriate here because the default PVC is small and RWO.
- Pocket ID is the source of truth for users and groups. LDAP settings were intentionally removed from this chart.
