#!/usr/bin/env bash
set -uo pipefail

ORG="${ORG:-PeaceApp-UPC-17433}"
SERVICES="identity-service incident-service trust-service alerts-service community-service notification-service api-gateway PeaceApp-AppWeb"
OTHERS="peaceapp-infra pipelines media-sanitizer-fn"

protect() {
  local repo="$1" branch="$2" checks="$3"
  gh api -X PUT "repos/$ORG/$repo/branches/$branch/protection" --input - >/dev/null <<JSON
{
  "required_status_checks": { "strict": false, "contexts": $checks },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 1, "dismiss_stale_reviews": true },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
  if [[ $? -eq 0 ]]; then echo "ok   $repo@$branch"; else echo "FALLA $repo@$branch (¿plan sin protección en repos privados?)"; fi
}

for repo in $SERVICES; do
  for branch in main develop; do
    protect "$repo" "$branch" '["pipeline / verify","pipeline / security","pipeline / image"]'
  done
done
for repo in $OTHERS; do
  for branch in main develop; do
    protect "$repo" "$branch" '[]'
  done
done
