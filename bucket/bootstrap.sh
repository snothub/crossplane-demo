# run this script as bash
# in case of  $'\r': command not found error, run command below first
# sed -i 's/\r$//' ./bootstrap.sh

echo "running $0..."
nsmon=monitoring
nsistio=istio-system
promport=80
helminit=0

############################################################
# Bootstrap                                                     #
############################################################
Bootstrap()
{

    Helm
    ArgoCd

}


############################################################
# Github                                                     #
############################################################
Github()
{
    echo "Installing secret..."
    kubectl apply -f github.yaml
}

############################################################
# ArgoCd                                                     #
############################################################
ArgoCd()
{
    # install argocd
    kubectl create namespace argocd

    kubectl label namespace argocd istio-injection=enabled
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    kubectl rollout status deployment/argocd-server -n argocd
    kubectl rollout status deployment/argocd-dex-server -n argocd
}


############################################################
# Helm                                                     #
############################################################
Helm()
{
    if [ "$helminit" == "0" ] 
    then
        # add helm charts
        helm repo add prometheus https://prometheus-community.github.io/helm-charts
        helm repo add kiali https://kiali.org/helm-charts
        helm repo add istio https://istio-release.storage.googleapis.com/charts
        helm repo add grafana https://grafana.github.io/helm-charts
        helm repo update
        helminit="1"
    fi
}

############################################################
# Uninstall                                                     #
# 
# NOTE: In case of hanging deletion of namespace istio, try below command
# kubectl patch kialis.kiali.io kiali -n istio-system -p '{"metadata":{"finalizers":null}}' --type=merge
# 
############################################################
Uninstall()
{
    while true; do
        read -p "Are you sure you want to un-install the cluster (y/n)? " yn
        case $yn in
            [Yy]*)
                echo "Uninstalling..."
                kubectl delete ns argocd
                echo "Finished."
                exit;;
            [Nn]*)
                echo "Cancelled."
                exit;;
            * ) echo "Please type Y or N.";;
        esac
    done
}


Bootstrap
