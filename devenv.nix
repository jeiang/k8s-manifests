{ pkgs, lib, config, inputs, ... }:
{
  packages = with pkgs; [
    openssl
    bws
    kubectl
    kubernetes-helm
    helm-ls
    yaml-language-server
    hcloud
  ];

  enterShell = ''
    if git rev-parse --git-dir >/dev/null 2>&1; then
      git config core.hooksPath .githooks
    fi
  '';
}
