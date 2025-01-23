echo "## Which Hyperscaler do you want to use?" | gum format

HYPERSCALER=$(gum choose "google" "aws" "azure")

echo "export HYPERSCALER=$HYPERSCALER" >> .env

if [[ "$HYPERSCALER" == "google" ]]; then

    gcloud auth login

    PROJECT_ID=dot-$(date +%Y%m%d%H%M%S)

    echo "export PROJECT_ID=$PROJECT_ID" >> .env

    gcloud projects create ${PROJECT_ID}

    echo "## Open https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID and link a billing account" \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    echo "## Open https://console.cloud.google.com/marketplace/product/google/container.googleapis.com?project=$PROJECT_ID and *ENABLE* the API" \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    echo "## Open https://console.cloud.google.com/apis/library/sqladmin.googleapis.com?project=$PROJECT_ID and *ENABLE* the API" \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    export SA_NAME=devops-toolkit

    export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

    gcloud iam service-accounts create $SA_NAME \
        --project $PROJECT_ID

    export ROLE=roles/admin

    gcloud projects add-iam-policy-binding \
        --role $ROLE $PROJECT_ID --member serviceAccount:$SA

    gcloud iam service-accounts keys create gcp-creds.json \
        --project $PROJECT_ID --iam-account $SA

    kubectl --namespace crossplane-system \
        create secret generic gcp-creds \
        --from-file creds=./gcp-creds.json

    echo "
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  projectID: $PROJECT_ID
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: gcp-creds
      key: creds" | kubectl apply --filename -

elif [[ "$HYPERSCALER" == "aws" ]]; then

    AWS_ACCESS_KEY_ID=$(gum input --placeholder "AWS Access Key ID" --value "$AWS_ACCESS_KEY_ID")
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env
    
    AWS_SECRET_ACCESS_KEY=$(gum input --placeholder "AWS Secret Access Key" --value "$AWS_SECRET_ACCESS_KEY" --password)
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env

    AWS_ACCOUNT_ID=$(gum input --placeholder "AWS Account ID" --value "$AWS_ACCOUNT_ID")
    echo "export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> .env

    echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" >aws-creds.conf

    kubectl --namespace crossplane-system \
        create secret generic aws-creds \
        --from-file creds=./aws-creds.conf

    kubectl apply --filename providers/aws-config.yaml

else

    AZURE_TENANT_ID=$(gum input --placeholder "Azure Tenant ID" --value "$AZURE_TENANT_ID")

    az login --tenant $AZURE_TENANT_ID

    export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

    az ad sp create-for-rbac --sdk-auth --role Owner --scopes /subscriptions/$SUBSCRIPTION_ID | tee azure-creds.json

    kubectl --namespace crossplane-system create secret generic azure-creds --from-file creds=./azure-creds.json

    kubectl apply --filename providers/azure-config.yaml

    DB_NAME=silly-demo-db-$(date +%Y%m%d%H%M%S)

    echo "---
apiVersion: devopstoolkitseries.com/v1alpha1
kind: ClusterClaim
metadata:
  name: cluster-01
spec:
  id: cluster01
  compositionSelector:
    matchLabels:
      provider: azure
      cluster: aks
  parameters:
    nodeSize: small
    minNodeCount: 3
---
apiVersion: v1
kind: Secret
metadata:
  name: $DB_NAME-password
data:
  password: SVdpbGxOZXZlclRlbGxAMQ==
---
apiVersion: devopstoolkitseries.com/v1alpha1
kind: SQLClaim
metadata:
  name: silly-demo-db
spec:
  id: $DB_NAME
  compositionSelector:
    matchLabels:
      provider: azure
      db: postgresql
  parameters:
    version: \"11\"
    size: small
---
apiVersion: devopstoolkitseries.com/v1alpha1
kind: AppClaim
metadata:
  name: silly-demo
spec:
  id: silly-demo
  compositionSelector:
    matchLabels:
      type: backend-db
      location: remote
  parameters:
    namespace: production
    image: c8n.io/vfarcic/silly-demo:1.4.52
    port: 8080
    host: silly-demo.acme.com
    dbSecret:
      name: silly-demo-db
      namespace: a-team
    kubernetesProviderConfigName: cluster01" \
    | tee examples/azure-intro.yaml

fi

kubectl create namespace a-team

