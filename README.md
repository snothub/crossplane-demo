Create an Azure service principal 

Follow the Azure documentation to find your Subscription ID from the Azure Portal.

Using the Azure command-line and provide your Subscription ID create a service principal and authentication file.

az ad sp create-for-rbac \
--sdk-auth \
--role Owner \
--scopes /subscriptions/<subscription id>


Save your Azure JSON output as azure-credentials.json


Create a Kubernetes secret with the Azure credentials 
A Kubernetes generic secret has a name and contents. Use kubectl create secret to generate the secret object named azure-secret in the crossplane-system namespace.

Use the --from-file= argument to set the value to the contents of the azure-credentials.json file.

kubectl create secret \
generic azure-secret-forte \
-n crossplane-system \
--from-file=creds=./azure-credentials.json

View the secret with kubectl describe secret



After creating a new cluster:

az account set --subscription 98138d28-11c8-4986-b8ed-eba050316c32
az aks get-credentials --resource-group ds-dev-aks --name apps-cluster --overwrite-existing
argocd cluster add apps-cluster --name apps-cluster

Get FQDN of new cluster
kubectl get kubernetescluster -o custom-columns=NAME:.status.atProvider.nodeResourceGroup,ADDR:.status.atProvider.fqdn