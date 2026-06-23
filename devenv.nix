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
}
