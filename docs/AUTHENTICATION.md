# Kubernetes Authentication

Normal users authenticate to the cluster with Pocket ID/OIDC. The emergency non-OIDC access path is the built-in k3s admin kubeconfig.

## Dependencies

Install these on your workstation:

- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- [`krew`](https://krew.sigs.k8s.io/), the `kubectl` plugin manager
- [`kubectl oidc-login`](https://github.com/int128/kubelogin) from `kubelogin`
- A browser for the [Pocket ID](https://pocket-id.org/) login flow

The cluster operator must provide:

- Kubernetes API server URL.
- Kubernetes cluster CA data or CA certificate file.
- Pocket ID issuer URL: `https://auth.jeiang.dev`.
- Kubernetes OIDC client ID.
- Kubernetes OIDC client secret.

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

macOS/Linux:

```sh
cat > pocket-id.kubeconfig <<'EOF'
apiVersion: v1
kind: Config
clusters:
  - name: legion
    cluster:
      server: https://<kubernetes-api-server>:6443
      certificate-authority-data: <cluster-ca-data>
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
          - --oidc-client-id=<kubernetes-oidc-client-id>
          - --oidc-client-secret=<kubernetes-oidc-client-secret>
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
      server: https://<kubernetes-api-server>:6443
      certificate-authority-data: <cluster-ca-data>
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
          - --oidc-client-id=<kubernetes-oidc-client-id>
          - --oidc-client-secret=<kubernetes-oidc-client-secret>
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

## Log In

macOS/Linux:

```sh
KUBECONFIG=./pocket-id.kubeconfig kubectl auth whoami
```

Windows PowerShell:

```powershell
$env:KUBECONFIG = ".\pocket-id.kubeconfig"
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
