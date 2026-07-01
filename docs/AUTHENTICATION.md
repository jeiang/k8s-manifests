# Kubernetes Authentication

Normal users authenticate to the cluster with Pocket ID/OIDC. The emergency non-OIDC access path is the built-in k3s admin kubeconfig.

## Dependencies

Install these on your workstation:

- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- [`krew`](https://krew.sigs.k8s.io/), the `kubectl` plugin manager
- [`kubectl oidc-login`](https://github.com/int128/kubelogin) from `kubelogin`
- A browser for the [Pocket ID](https://pocket-id.org/) login flow

The cluster operator must provide:

- Kubernetes API server URL: `https://node1.jeiang.dev:6443`.
- Kubernetes cluster CA data or CA certificate file.
- Pocket ID issuer URL: `https://auth.jeiang.dev`.
- Kubernetes OIDC client ID: `44213aa3-11eb-401d-922c-c7f81c3a9e37`.

The Kubernetes OIDC client is configured as a public client. `kubectl oidc-login` uses PKCE for the browser flow, so no client secret is required.

## Install Tools

macOS with [Homebrew](https://brew.sh/):

```sh
brew install kubectl
brew install int128/kubelogin/kubelogin
```

macOS or Linux with Krew's [manual installation steps](https://krew.sigs.k8s.io/docs/user-guide/setup/install/):

```sh
(
  set -x
  cd "$(mktemp -d)"
  OS="$(uname | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')"
  KREW="krew-${OS}_${ARCH}"
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
  tar zxvf "${KREW}.tar.gz"
  ./"${KREW}" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
kubectl krew install oidc-login
```

Add Krew to your shell profile after installing it:

```sh
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.zshrc
```

For Bash, use `~/.bashrc` instead of `~/.zshrc`.

Windows with Krew's [manual installation steps](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) in PowerShell:

```powershell
$Krew = "krew-windows_amd64"
$Temp = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ([System.IO.Path]::GetRandomFileName())
Set-Location $Temp
Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/krew/releases/latest/download/$Krew.zip" -OutFile "$Krew.zip"
Expand-Archive "$Krew.zip" -DestinationPath .
.\$Krew.exe install krew

$KrewBin = "$env:USERPROFILE\.krew\bin"
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$KrewBin", "User")
$env:Path = "$env:Path;$KrewBin"
kubectl krew install oidc-login
```

Verify the plugin:

```sh
kubectl oidc-login --help
```

## Create a kubeconfig

Create a kubeconfig file with your cluster details and Pocket ID exec login.

Kubernetes uses your Pocket ID username as your Kubernetes username. That username is also your namespace ownership prefix. For example, user `john` means someone whose Pocket ID username is exactly `john`; that user owns the namespace `john` and namespaces prefixed with `john-`, such as `john-website`.

macOS/Linux:

```sh
cat > pocket-id.kubeconfig <<'EOF'
apiVersion: v1
kind: Config
clusters:
  - name: legion
    cluster:
      server: https://node1.jeiang.dev:6443
      certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJlRENDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyTTNNdGMyVnkKZG1WeUxXTmhRREUzT0RJeE9UQTNPRE13SGhjTk1qWXdOakl6TURNMU9UUXpXaGNOTXpZd05qSXdNRE0xT1RRegpXakFqTVNFd0h3WURWUVFEREJock0zTXRjMlZ5ZG1WeUxXTmhRREUzT0RJeE9UQTNPRE13V1RBVEJnY3Foa2pPClBRSUJCZ2dxaGtqT1BRTUJCd05DQUFRTWhadHlYdXZ0V1l5UlVVaGNWWlhqNjhqalRwRGJSNklkTlRLNDJKRGMKaDYxWVZ3eEJPRHRZdGx6WjY3aG1CTktsNkx4NUdocnQ0dmJLbnBpcEUrMkNvMEl3UURBT0JnTlZIUThCQWY4RQpCQU1DQXFRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVTE0eDM0ZkFSeXVZbjcyLzlQZkIwCnV0NUNoNkF3Q2dZSUtvWkl6ajBFQXdJRFNRQXdSZ0loQU4vb2pWcnFtcDRrckpSVVJIWGNRczNvcTlzOXdONnIKaVFabEdpVW9RTDl2QWlFQXFLYllaYSt0bC9TRDdMdTd5Z2Vpb3h3NnA0RitkSC82N2VvOE81SlRuNEU9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
users:
  - name: pocket-id
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: kubectl
        args:
          - oidc-login
          - get-token
          - --oidc-issuer-url=https://auth.jeiang.dev
          - --oidc-client-id=44213aa3-11eb-401d-922c-c7f81c3a9e37
          - --oidc-extra-scope=profile
          - --oidc-extra-scope=email
          - --oidc-extra-scope=groups
contexts:
  - name: pocket-id@legion
    context:
      cluster: legion
      user: pocket-id
current-context: pocket-id@legion
EOF
```

Windows PowerShell:

```powershell
@"
apiVersion: v1
kind: Config
clusters:
  - name: legion
    cluster:
      server: https://node1.jeiang.dev:6443
      certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJlRENDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyTTNNdGMyVnkKZG1WeUxXTmhRREUzT0RJeE9UQTNPRE13SGhjTk1qWXdOakl6TURNMU9UUXpXaGNOTXpZd05qSXdNRE0xT1RRegpXakFqTVNFd0h3WURWUVFEREJock0zTXRjMlZ5ZG1WeUxXTmhRREUzT0RJeE9UQTNPRE13V1RBVEJnY3Foa2pPClBRSUJCZ2dxaGtqT1BRTUJCd05DQUFRTWhadHlYdXZ0V1l5UlVVaGNWWlhqNjhqalRwRGJSNklkTlRLNDJKRGMKaDYxWVZ3eEJPRHRZdGx6WjY3aG1CTktsNkx4NUdocnQ0dmJLbnBpcEUrMkNvMEl3UURBT0JnTlZIUThCQWY4RQpCQU1DQXFRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVTE0eDM0ZkFSeXVZbjcyLzlQZkIwCnV0NUNoNkF3Q2dZSUtvWkl6ajBFQXdJRFNRQXdSZ0loQU4vb2pWcnFtcDRrckpSVVJIWGNRczNvcTlzOXdONnIKaVFabEdpVW9RTDl2QWlFQXFLYllaYSt0bC9TRDdMdTd5Z2Vpb3h3NnA0RitkSC82N2VvOE81SlRuNEU9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
users:
  - name: pocket-id
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: kubectl
        args:
          - oidc-login
          - get-token
          - --oidc-issuer-url=https://auth.jeiang.dev
          - --oidc-client-id=44213aa3-11eb-401d-922c-c7f81c3a9e37
          - --oidc-extra-scope=profile
          - --oidc-extra-scope=email
          - --oidc-extra-scope=groups
contexts:
  - name: pocket-id@legion
    context:
      cluster: legion
      user: pocket-id
current-context: pocket-id@legion
"@ | Set-Content -Encoding utf8 pocket-id.kubeconfig
```

The `profile` and `groups` scopes are required. Without `profile`, the ID token may not contain `preferred_username`. Without `groups`, Kubernetes will not see `kubernetes-access` or `kubernetes-admin`.

## Install the kubeconfig

If this is your only Kubernetes cluster, move the generated kubeconfig to the default location.

macOS/Linux:

```sh
mkdir -p ~/.kube
mv pocket-id.kubeconfig ~/.kube/config
chmod 600 ~/.kube/config
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.kube"
Move-Item .\pocket-id.kubeconfig "$env:USERPROFILE\.kube\config"
```

If you already have clusters, users, or contexts in your kubeconfig, merge this kubeconfig into the existing default file instead of replacing it.

macOS/Linux:

```sh
mkdir -p ~/.kube
KUBECONFIG="$HOME/.kube/config:./pocket-id.kubeconfig" kubectl config view --flatten > /tmp/merged-kubeconfig
mv /tmp/merged-kubeconfig ~/.kube/config
chmod 600 ~/.kube/config
kubectl config use-context pocket-id@legion
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.kube"
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config;.\pocket-id.kubeconfig"
kubectl config view --flatten | Set-Content -Encoding utf8 "$env:TEMP\merged-kubeconfig"
Move-Item -Force "$env:TEMP\merged-kubeconfig" "$env:USERPROFILE\.kube\config"
Remove-Item Env:\KUBECONFIG
kubectl config use-context pocket-id@legion
```

## Log In

macOS/Linux:

```sh
kubectl auth whoami
```

Windows PowerShell:

```powershell
kubectl auth whoami
```

The first command opens a browser. Sign in with Pocket ID.

Expected admin output includes:

```text
Username   jeiang
Groups     [kubernetes-admin ... system:authenticated]
```

Expected normal user output includes:

```text
Username   saeed
Groups     [kubernetes-access ... system:authenticated]
```

The `Username` value is the namespace prefix Kubernetes and Kyverno use. If the output says `Username john`, create `john` and `john-*` namespaces. Do not use your email address, display name, or Pocket ID subject UUID as the namespace prefix.

## Verify Access

Admin users:

```sh
kubectl auth can-i '*' '*' --all-namespaces
kubectl get namespaces
```

Normal users:

```sh
kubectl auth can-i create namespaces
kubectl create namespace <username>
kubectl create namespace <username>-website
```

Replace `<username>` with the exact value from `kubectl auth whoami`. For example, if `kubectl auth whoami` shows `Username john`, run `kubectl create namespace john` and `kubectl create namespace john-website`.

Kyverno should deny namespaces owned by another username:

```sh
kubectl create namespace other-user-test
```

## Troubleshooting

If `kubectl` returns `Unauthorized`, inspect the k3s journal on a server node and decode the ID token from the login plugin. The token must contain:

```json
{
  "preferred_username": "your-username",
  "groups": ["kubernetes-access"]
}
```

If `kubectl auth whoami` shows groups prefixed with `-`, the cluster is using the wrong API server group prefix. Set:

```yaml
kube-apiserver-arg:
  - oidc-groups-prefix=
```

If authentication works but RBAC denies access, confirm the user is in the required Pocket ID group:

- `kubernetes-access` for normal namespace self-service.
- `kubernetes-admin` for full cluster admin.
- `kubernetes-kube-system-reader` for read-only `kube-system`.
- `kubernetes-kube-system-admin` for scoped admin access to `kube-system`.
