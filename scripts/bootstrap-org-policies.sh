#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 ORG" >&2
  exit 1
fi

org="$1"

run_optional() {
  local description="$1"
  local output
  shift

  if ! output="$("$@" 2>&1)"; then
    echo "Warning: could not ${description}." >&2
    echo "$output" >&2
  fi
}

echo "Configuring organization access and repository lifecycle policies for $org"
gh api \
  --method PATCH "orgs/$org" \
  -f default_repository_permission=none \
  -F members_can_create_repositories=false \
  -F members_can_create_public_repositories=false \
  -F members_can_create_private_repositories=false \
  -F members_can_fork_private_repositories=false \
  -F has_organization_projects=false \
  -F has_repository_projects=false \
  -F members_can_create_pages=false \
  -F members_can_create_public_pages=false \
  -F members_can_create_private_pages=false \
  >/dev/null

run_optional "disable member repository deletion" \
  gh api --method PATCH "orgs/$org" -F members_can_delete_repositories=false >/dev/null

run_optional "disable member repository visibility changes" \
  gh api --method PATCH "orgs/$org" -F members_can_change_repo_visibility=false >/dev/null

run_optional "disable outside collaborator invitations by members" \
  gh api --method PATCH "orgs/$org" -F members_can_invite_outside_collaborators=false >/dev/null

run_optional "disable member team creation" \
  gh api --method PATCH "orgs/$org" -F members_can_create_teams=false >/dev/null

run_optional "require 2FA for members" \
  gh api --method PATCH "orgs/$org" -F two_factor_requirement_enabled=true >/dev/null

echo "Configuring organization Actions policy"
gh api \
  --method PUT "orgs/$org/actions/permissions" \
  -F enabled_repositories=all \
  -f allowed_actions=selected \
  >/dev/null

actions_policy_file="$(mktemp)"
cat >"$actions_policy_file" <<'JSON'
{
  "github_owned_allowed": true,
  "verified_allowed": false,
  "patterns_allowed": []
}
JSON

gh api \
  --method PUT "orgs/$org/actions/permissions/selected-actions" \
  --input "$actions_policy_file" \
  >/dev/null
rm -f "$actions_policy_file"

gh api \
  --method PUT "orgs/$org/actions/permissions/workflow" \
  -f default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=false \
  >/dev/null

echo "Attempting to create ISO-compliant main-only org ruleset"
run_optional "create organization ruleset for ISO-compliant main-only repositories" \
  gh api --method POST "orgs/$org/rulesets" \
    --input .github/examples/org-ruleset-iso-compliant-main.json \
    >/dev/null

echo "Organization policy bootstrap complete for $org"
