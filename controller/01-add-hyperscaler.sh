HYPERSCALER="azure"

echo "export HYPERSCALER=$HYPERSCALER" >> .env

AZURE_TENANT_ID=$(gum input --placeholder "Azure Tenant ID" --value "$AZURE_TENANT_ID")

az login --tenant $AZURE_TENANT_ID

export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac --sdk-auth --role Owner --scopes /subscriptions/$SUBSCRIPTION_ID | tee azure-creds.json

kubectl --namespace crossplane-system create secret generic azure-creds --from-file creds=./azure-creds.json

kubectl apply --filename providers/azure-config.yaml

