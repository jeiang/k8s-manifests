{ pkgs, lib, config, inputs, ... }:

{
  packages = with pkgs; [
    kubectl
    kubernetes-helm
    helm-ls
    yaml-language-server
  ];
}
