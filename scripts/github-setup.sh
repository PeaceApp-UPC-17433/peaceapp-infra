#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-PeaceApp-UPC-17433}"
SERVICES="identity-service incident-service trust-service alerts-service community-service notification-service api-gateway"
PUBLIC_REPOS="pipelines media-sanitizer-fn"
PRIVATE_REPOS="notification-service"
ALL_REPOS="$SERVICES PeaceApp-AppWeb peaceapp-infra pipelines media-sanitizer-fn"

: "${AZURE_TENANT_ID:?}" "${AZURE_SUBSCRIPTION_ID:?}" "${AZURE_CLIENT_ID:?}" "${TFSTATE_RG:?}" "${TFSTATE_SA:?}"
: "${BUDGET_CONTACT_EMAIL:?}" "${SONAR_TOKEN:?}"

for repo in $PUBLIC_REPOS; do
  gh repo view "$ORG/$repo" >/dev/null 2>&1 || gh repo create "$ORG/$repo" --public
done
for repo in $PRIVATE_REPOS; do
  gh repo view "$ORG/$repo" >/dev/null 2>&1 || gh repo create "$ORG/$repo" --private
done

set_variable() {
  local name="$1" value="$2"
  if ! gh variable set "$name" --org "$ORG" --visibility all --body "$value" 2>/dev/null; then
    for repo in $ALL_REPOS; do gh variable set "$name" --repo "$ORG/$repo" --body "$value"; done
  fi
}

set_secret() {
  local name="$1" value="$2"
  if ! gh secret set "$name" --org "$ORG" --visibility all --body "$value" 2>/dev/null; then
    for repo in $ALL_REPOS; do gh secret set "$name" --repo "$ORG/$repo" --body "$value"; done
  fi
}

set_variable AZURE_TENANT_ID "$AZURE_TENANT_ID"
set_variable AZURE_SUBSCRIPTION_ID "$AZURE_SUBSCRIPTION_ID"
set_variable AZURE_CLIENT_ID "$AZURE_CLIENT_ID"
set_secret SONAR_TOKEN "$SONAR_TOKEN"

for name in TFSTATE_RG TFSTATE_SA BUDGET_CONTACT_EMAIL; do
  gh variable set "$name" --repo "$ORG/peaceapp-infra" --body "${!name}"
done
[[ -z "${RESEND_API_KEY:-}" ]] || gh secret set RESEND_API_KEY --repo "$ORG/peaceapp-infra" --body "$RESEND_API_KEY"
[[ -z "${MAPBOX_ACCESS_TOKEN:-}" ]] || gh secret set MAPBOX_ACCESS_TOKEN --repo "$ORG/peaceapp-infra" --body "$MAPBOX_ACCESS_TOKEN"
gh variable set FUNCTION_APP_NAME --repo "$ORG/media-sanitizer-fn" --body "func-peaceapp-prod-media"

for repo in $ALL_REPOS; do
  gh api -X PATCH "repos/$ORG/$repo" \
    -f 'security_and_analysis[secret_scanning][status]=enabled' \
    -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null 2>&1 \
    || echo "secret scanning no disponible en $repo"
  gh api -X PUT "repos/$ORG/$repo/vulnerability-alerts" >/dev/null 2>&1 || true
  gh api -X PUT "repos/$ORG/$repo/automated-security-fixes" >/dev/null 2>&1 || true
done
echo "listo"
