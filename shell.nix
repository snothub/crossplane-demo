{ pkgs ? import <nixpkgs> {} }:pkgs.mkShell {
  packages = with pkgs; [
    gum
    gh
    kind
    kubectl
    kubeseal
    yq-go
    jq
    azure-cli
    upbound
    teller
    crossplane-cli
    kubernetes-helm
  ];
}
