# netbird Values

These values configure the local self-hosted NetBird Helm chart.

| Value | Default | Purpose |
| --- | --- | --- |
| `global.host` | `netbird.jeiang.dev` | Public management hostname. |
| `global.publicUrl` | `https://netbird.jeiang.dev` | Public management URL. |
| `secrets.existingSecret` | `netbird-secrets` | Kubernetes Secret consumed by NetBird workloads. |
| `secrets.keys` | store encryption, relay auth, IdP cookie, proxy token, and CrowdSec bouncer key names | Maps Secret keys to application settings. |
| `bitwardenSecrets.enabled` | `true` | Renders a `BitwardenSecret` for `netbird-secrets`. |
| `bitwardenSecrets.organizationId` | `af918704-c223-4f10-a245-b4640144f2d9` | Bitwarden organization ID. |
| `bitwardenSecrets.authToken.secretName` | `bw-auth-token` | Namespace-local Bitwarden machine account token Secret. |
| `bitwardenSecrets.authToken.secretKey` | `token` | Token key inside `bw-auth-token`. |
| `bitwardenSecrets.secretIds` | UUIDs for NetBird secrets | Bitwarden Secrets Manager item IDs synced into `netbird-secrets`. |
| `server.replicaCount` | `1` | Runs one management server pod. |
| `server.image` | `netbirdio/netbird-server:0.73.2`, `IfNotPresent` | Management server image settings. |
| `server.port` | `80` | Management HTTP port. |
| `server.metricsPort` | `9090` | Metrics port. |
| `server.healthPort` | `9000` | Health check port. |
| `server.logLevel` | `info` | Management server log level. |
| `server.dataDir` | `/var/lib/netbird` | Persistent server state directory. |
| `server.dnsDomain` | `jeiang.vpn` | NetBird private DNS domain. |
| `server.credentialsTTL` | `24h` | Peer credential lifetime. |
| `server.renderConfig.resources` | `10m/16Mi` request, `50m/64Mi` limit | Config-render init container resources. |
| `server.resources` | `100m/256Mi` request, `750m/768Mi` limit | Server resource settings. |
| `dashboard.replicaCount` | `1` | Runs one dashboard pod. |
| `dashboard.image` | `netbirdio/dashboard:v2.80.0`, `IfNotPresent` | Dashboard image settings. |
| `dashboard.port` | `80` | Dashboard HTTP port. |
| `dashboard.resources` | `50m/64Mi` request, `250m/256Mi` limit | Dashboard resource settings. |
| `relay.replicaCount` | `1` | Runs one relay pod for the single advertised relay address. |
| `relay.image` | `netbirdio/relay:0.73.2`, `IfNotPresent` | Relay image settings. |
| `relay.port` | `8080` | Relay service port. |
| `relay.stunHost` | `stun.netbird.jeiang.dev` | Public STUN hostname. |
| `relay.stunPort` | `3478` | Public STUN UDP port. |
| `relay.exposedAddress` | `rels://netbird.jeiang.dev:443` | Relay address advertised to clients. |
| `relay.enableStun` | `true` | Enables STUN. |
| `relay.hostNetwork.enabled` | `true` | Uses host networking for STUN. |
| `relay.logLevel` | `info` | Relay log level. |
| `relay.nodeSelector` | `netbird.io/stun: "true"` | Schedules relay pods on labeled nodes. |
| `relay.antiAffinity.enabled` | `true` | Keeps relay replicas on separate nodes. |
| `relay.affinity` | `{}` | Optional additional affinity. |
| `relay.resources` | `100m/128Mi` request, `500m/512Mi` limit | Relay resource settings. |
| `proxy.enabled` | `true` | Enables NetBird reverse proxy. |
| `proxy.replicaCount` | `1` | Runs one proxy pod. |
| `proxy.image` | `netbirdio/reverse-proxy:0.73.2`, `IfNotPresent` | Proxy image settings. |
| `proxy.domain` | `proxy.jeiang.dev` | Proxy base hostname. |
| `proxy.wildcardDomain` | `*.proxy.jeiang.dev` | Wildcard proxy hostname. |
| `proxy.wildcardDomainRegexp` | `^.+\.proxy\.jeiang\.dev$` | SNI match expression for wildcard routes. |
| `proxy.port` | `8443` | Proxy TLS port. |
| `proxy.managementAddress` | `""` | Uses chart-generated management address. |
| `proxy.allowInsecure` | `true` | Allows cluster-internal HTTP to management. |
| `proxy.acmeCertificates` | `true` | Lets the proxy manage certificates. |
| `proxy.acmeChallengeType` | `tls-alpn-01` | ACME challenge type. |
| `proxy.certificateDirectory` | `/certs` | Proxy certificate storage path. |
| `proxy.proxyProtocol.enabled` | `true` | Accepts PROXY protocol from Traefik so proxy logs and access policy see the original client IP. |
| `proxy.proxyProtocol.version` | `2` | PROXY protocol version Traefik sends to the NetBird proxy backend. |
| `proxy.proxyProtocol.trustedProxies` | `10.42.0.0/16` | Upstream proxy CIDRs trusted by NetBird; this should include Traefik pod IPs. |
| `proxy.crowdsec.enabled` | `false` | Enables CrowdSec IP reputation checks for the reverse proxy. |
| `proxy.crowdsec.apiUrl` | `http://crowdsec-service.crowdsec.svc.cluster.local:8080` | CrowdSec LAPI URL used by the NetBird proxy. |
| `proxy.crowdsec.apiKeySecretKey` | `crowdsec-bouncer-key` | Secret key containing the CrowdSec bouncer API key. |
| `proxy.uid` | `"1000"` | Proxy process UID. |
| `proxy.gid` | `"1000"` | Proxy process GID. |
| `proxy.logLevel` | `info` | Proxy log level. |
| `proxy.certsInit` | `busybox:1.36` with small resources | Init container for certificate directory permissions. |
| `proxy.persistence.enabled` | `true` | Persists proxy ACME certificates. |
| `proxy.persistence.size` | `1Gi` | Proxy certificate PVC size. |
| `proxy.persistence.storageClassName` | `hcloud-volumes` | Uses Hetzner RWO storage. |
| `proxy.resources` | `100m/128Mi` request, `500m/512Mi` limit | Proxy resource settings. |
| `service.type` | `ClusterIP` | Keeps main services internal behind Traefik. |
| `service.stun.type` | `ClusterIP` | Keeps STUN service internal; relay uses host networking for public UDP. |
| `service.stun.annotations` | `{}` | Optional STUN Service annotations. |
| `service.stun.externalTrafficPolicy` | `Cluster` | Service traffic policy if the STUN service type changes. |
| `ingress.enabled` | `true` | Creates Traefik routes. |
| `ingress.className` | `traefik` | Uses Traefik ingress class. |
| `ingress.entryPoint` | `websecure` | Uses Traefik secure entryPoint. |
| `ingress.tls.enabled` | `true` | Enables TLS for management routes. |
| `ingress.tls.secretName` | `netbird-tls` | Management TLS Secret. |
| `ingress.certManager.enabled` | `true` | Creates cert-manager certificate resources. |
| `ingress.certManager.clusterIssuer` | `letsencrypt-prod` | Certificate issuer. |
| `persistence.enabled` | `true` | Creates server persistent storage. |
| `persistence.size` | `10Gi` | Server PVC size. |
| `persistence.storageClassName` | `hcloud-volumes` | Uses Hetzner RWO storage. |
| `nodeSelector` | `{}` | Optional node placement constraints. |
| `tolerations` | `[]` | Optional taint tolerations. |
| `affinity` | `{}` | Optional pod affinity rules. |

## Notes

- DNS and firewall settings for STUN are outside the chart and must match `relay.stunHost`, `relay.stunPort`, and the relay node label.
- Do not scale relay behind the same advertised `relay.exposedAddress` without relay-aware stickiness or distinct advertised relay addresses. Relay peer availability is local to each relay process, so split peers can see `peer not available` timeouts.
- Server and proxy storage stay on `hcloud-volumes` because the default volumes are small RWO volumes.
- Secret values must remain in Bitwarden Secrets Manager.
