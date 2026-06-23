# bitwarden-sm-operator

Values for deploying the Bitwarden Secrets Manager Kubernetes Operator with the upstream `bitwarden/sm-operator` Helm chart.

## What This Values File Configures

- One Bitwarden Secrets Manager operator replica.
- Secret synchronization every `300` seconds.
- Bitwarden Cloud `US` region by default.
- A `ClusterIP` metrics Service on port `8443`.
- Restricted seccomp profile enabled.
- CPU and memory requests/limits for the operator manager.

The upstream Bitwarden chart version checked while creating this file was `2.0.1`, with app version `2.0.0`.

## Dependencies

- Helm 3 and `kubectl`.
- An active Bitwarden organization with Secrets Manager enabled.
- A Bitwarden Secrets Manager machine account and access token.
- Kubernetes permissions to install CRDs, RBAC, Deployments, Services, and `BitwardenSecret` resources.
- Network egress from the operator pod to Bitwarden Cloud, or to your self-hosted Bitwarden API and identity URLs.

Repository policy: all application and workload secrets should be stored in Bitwarden Secrets Manager and synced with `BitwardenSecret` resources. The only Kubernetes Secrets created directly in normal operation are `kube-system/hcloud` for Hetzner components and per-namespace `bw-auth-token` Secrets that let this operator read Bitwarden items.

## Install

Add the official Bitwarden chart repository:

```fish
helm repo add bitwarden https://charts.bitwarden.com/
helm repo update
```

Review the rendered manifests:

```fish
helm template sm-operator bitwarden/sm-operator \
  --namespace sm-operator-system \
  -f ./bitwarden-sm-operator/values.yaml \
  --devel
```

Install or upgrade:

```fish
helm upgrade --install sm-operator bitwarden/sm-operator \
  --namespace sm-operator-system \
  --create-namespace \
  -f ./bitwarden-sm-operator/values.yaml \
  --devel \
  --wait
```

## Verify

```fish
kubectl -n sm-operator-system get deploy,pods,svc
kubectl -n sm-operator-system rollout status deployment/sm-operator-controller-manager --timeout=5m
kubectl get crd bitwardensecrets.k8s.bitwarden.com
```

## Create An Auth Token Secret

Create the machine-account access token Secret in each namespace where you deploy `BitwardenSecret` resources. This avoids storing the token in this repository.

```fish
set BW_NAMESPACE default
read --silent --prompt-str 'Bitwarden machine account token: ' BW_AUTH_TOKEN
echo

kubectl create namespace $BW_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

kubectl -n $BW_NAMESPACE create secret generic bw-auth-token \
  --from-literal=token="$BW_AUTH_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

set --erase BW_AUTH_TOKEN
```

## Deploy A BitwardenSecret

Set these values from Bitwarden Secrets Manager:

```fish
set BW_NAMESPACE default
set BW_ORG_ID replace-with-organization-uuid
set BW_SECRET_ID replace-with-secret-uuid
```

Create a `BitwardenSecret` that syncs one Bitwarden secret into a Kubernetes Secret named `app-secrets`:

```fish
string join \n \
  'apiVersion: k8s.bitwarden.com/v1' \
  'kind: BitwardenSecret' \
  'metadata:' \
  '  name: app-secrets' \
  'spec:' \
  "  organizationId: \"$BW_ORG_ID\"" \
  '  secretName: app-secrets' \
  '  onlyMappedSecrets: true' \
  '  map:' \
  "    - bwSecretId: $BW_SECRET_ID" \
  '      secretKeyName: APP_SECRET' \
  '  authToken:' \
  '    secretName: bw-auth-token' \
  '    secretKey: token' \
  | kubectl -n $BW_NAMESPACE apply -f -
```

Verify the synced Kubernetes Secret:

```fish
kubectl -n $BW_NAMESPACE get bitwardensecret app-secrets
kubectl -n $BW_NAMESPACE get secret app-secrets
```

This repository also includes saved `BitwardenSecret` manifests for the charts that consume Kubernetes Secrets:

- `idp/templates/bitwardensecret.yaml` for `idp-secrets`.
- `netbird/templates/bitwardensecret.yaml` for `netbird-secrets`.
- `netbird-resources/templates/bitwardensecret-netbird-api.yaml` for `netbird-mgmt-api-key`.

## Values To Review

```yaml
settings:
  bwSecretsManagerRefreshInterval: 300
  cloudRegion: US
  bwApiUrlOverride: ""
  bwIdentityUrlOverride: ""
  replicas: 1

containers:
  manager:
    resources:
      requests:
        cpu: 10m
        memory: 64Mi
      limits:
        cpu: 500m
        memory: 128Mi
```

For self-hosted Bitwarden, set `settings.cloudRegion` to an empty string and configure `settings.bwApiUrlOverride` and `settings.bwIdentityUrlOverride`.

## References

- Bitwarden operator docs: https://bitwarden.com/help/secrets-manager-kubernetes-operator/
- Bitwarden Helm charts: https://charts.bitwarden.com/
