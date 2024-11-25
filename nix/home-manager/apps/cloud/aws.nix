{ config, inputs, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    ###################################"
    # AWS and other tools used with AWS
    ###################################"
    awscli2 # AWS CLI
    kubectl # Kubernetes CLI
    kubectx # Kubernetes CLI
    k9s # Kubernetes CLI
    kubernetes-helm # Helm
    argocd # ArgoCD CLI
  ];
}
