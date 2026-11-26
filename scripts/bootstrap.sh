#!/usr/bin/env bash
set -euo pipefail

: "${INFRA_REPO:?INFRA_REPO=<owner>/peaceapp-infra}"
APP_REPOS="${APP_REPOS:-PeaceApp-UPC-17433/identity-service PeaceApp-UPC-17433/incident-service PeaceApp-UPC-17433/trust-service PeaceApp-UPC-17433/alerts-service PeaceApp-UPC-17433/community-service PeaceApp-UPC-17433/notification-service PeaceApp-UPC-17433/api-gateway PeaceApp-UPC-17433/PeaceApp-AppWeb}"
RG="${RG:-rg-peaceapp}"
LOCATION="${LOCATION:-northcentralus}"
IDENTITY="peaceapp-github"

SUB_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
SUFFIX="$(printf '%s' "$SUB_ID" | shasum -a 256 | cut -c1-8)"
TFSTATE_SA="stpeaceapptf${SUFFIX}"
RG_ID="/subscriptions/${SUB_ID}/resourceGroups/${RG}"

for ns in Microsoft.Storage Microsoft.ContainerService Microsoft.DBforPostgreSQL Microsoft.Web Microsoft.OperationalInsights Microsoft.Insights Microsoft.Consumption Microsoft.ManagedIdentity Microsoft.Network Microsoft.Compute; do
  [[ "$(az provider show -n "$ns" --query registrationState -o tsv)" = "Registered" ]] || az provider register --namespace "$ns" --wait -o none
done

az storage account create -n "$TFSTATE_SA" -g "$RG" -l "$LOCATION" \
  --sku Standard_LRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false -o none
SA_ID="$(az storage account show -n "$TFSTATE_SA" -g "$RG" --query id -o tsv)"
ME="$(az ad signed-in-user show --query id -o tsv)"
az role assignment create --assignee-object-id "$ME" --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none || true
sleep 20
az storage container create -n tfstate --account-name "$TFSTATE_SA" --auth-mode login -o none

if ! az identity show -g "$RG" -n "$IDENTITY" -o none 2>/dev/null; then
  az identity create -g "$RG" -n "$IDENTITY" -l "$LOCATION" -o none
fi
CLIENT_ID="$(az identity show -g "$RG" -n "$IDENTITY" --query clientId -o tsv)"
PRINCIPAL_ID="$(az identity show -g "$RG" -n "$IDENTITY" --query principalId -o tsv)"

az role assignment create --assignee-object-id "$PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
  --role Contributor --scope "$RG_ID" -o none || true
az role assignment create --assignee-object-id "$PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none || true
az role assignment create --assignee-object-id "$PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
  --role "Azure Kubernetes Service Cluster Admin Role" --scope "$RG_ID" -o none || true

subject_prefix() {
  gh api "repos/$1/actions/oidc/customization/sub" --jq '.sub_claim_prefix' 2>/dev/null || echo "repo:$1"
}

for old in $(az identity federated-credential list -g "$RG" --identity-name "$IDENTITY" --query "[].name" -o tsv); do
  az identity federated-credential delete -g "$RG" --identity-name "$IDENTITY" --name "$old" --yes -o none
done

add_credential() {
  local name
  name="$(echo "$1-$2" | tr '/_:' '---')"
  az identity federated-credential create -g "$RG" --identity-name "$IDENTITY" --name "$name" \
    --issuer "https://token.actions.githubusercontent.com" --subject "$(subject_prefix "$1"):$2" \
    --audiences "api://AzureADTokenExchange" -o none
}

add_credential "$INFRA_REPO" "pull_request"
add_credential "$INFRA_REPO" "ref:refs/heads/main"
for repo in $APP_REPOS; do
  add_credential "$repo" "environment:production"
done

cat <<OUT

AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUB_ID
AZURE_CLIENT_ID=$CLIENT_ID
TFSTATE_RG=$RG
TFSTATE_SA=$TFSTATE_SA
OUT
