AZURE_TENANT_ID=$(gum input --placeholder "Azure Tenant ID" --value "$AZURE_TENANT_ID")
AZURE_TENANT_NAME=$(gum input --placeholder "Provide a short alias for tenant" --value "$AZURE_TENANT_NAME")

az login --tenant $AZURE_TENANT_ID

export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac --sdk-auth --role Owner --scopes /subscriptions/$SUBSCRIPTION_ID | tee azure-creds-$AZURE_TENANT_NAME.json

kubectl --namespace crossplane-system create secret generic azure-creds-$AZURE_TENANT_NAME --dry-run=client --from-file creds=./azure-creds-$AZURE_TENANT_NAME.json -o json | kubeseal | tee sealedsecrets/azure-sealedcreds-$AZURE_TENANT_NAME.yaml
kubectl apply -f sealedsecrets/
rm azure-creds-$AZURE_TENANT_NAME.json

helm upgrade --install --set config.name=$AZURE_TENANT_NAME pr-config ./providerconfig 

