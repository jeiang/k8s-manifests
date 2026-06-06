{ pkgs, lib, config, inputs, ... }:

{
  packages = with pkgs; [
    openssl
    kubectl
    kubernetes-helm
    helm-ls
    yaml-language-server
  ];
}
