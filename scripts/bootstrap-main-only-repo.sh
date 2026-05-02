#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 OWNER/REPO" >&2
  exit 1
fi

repo="$1"

run_optional() {
  local description="$1"
  shift

  if ! "$@"; then
    echo "Warning: could not ${description}. This may require a different GitHub plan, token scope, or organization setting." >&2
  fi
}

echo "Configuring repository settings for $repo"
gh api \
  --method PATCH "repos/$repo" \
  -f has_issues=true \
  -f has_wiki=false \
  -f has_projects=false \
  -f delete_branch_on_merge=true \
  -f allow_squash_merge=true \
  -f allow_merge_commit=true \
  -f allow_rebase_merge=false \
  >/dev/null

echo "Configuring GitHub Actions permissions"
run_optional "enable Actions with selected allowed actions" \
  gh api --method PUT "repos/$repo/actions/permissions" \
    -F enabled=true \
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
run_optional "restrict allowed Actions to GitHub-owned actions" \
  gh api --method PUT "repos/$repo/actions/permissions/selected-actions" \
    --input "$actions_policy_file" \
    >/dev/null
rm -f "$actions_policy_file"

run_optional "set default GITHUB_TOKEN permissions to read-only" \
  gh api --method PUT "repos/$repo/actions/permissions/workflow" \
    -f default_workflow_permissions=read \
    -F can_approve_pull_request_reviews=false \
    >/dev/null

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  gh label create "$name" \
    --repo "$repo" \
    --color "$color" \
    --description "$description" \
    --force \
    >/dev/null
}

echo "Creating standard labels"
create_label "release:major" "B60205" "Breaking or incompatible release impact"
create_label "release:minor" "1D76DB" "Backward-compatible feature release impact"
create_label "release:patch" "0E8A16" "Backward-compatible fix or maintenance release impact"
create_label "release:exempt" "C5DEF5" "No release version impact"
create_label "risk:low" "D4C5F9" "Low operational, data, or security risk"
create_label "risk:medium" "FBCA04" "Material change requiring standard review"
create_label "risk:high" "D93F0B" "High-impact change requiring owner or security review"
create_label "risk:prod-impact" "B60205" "Production behavior, availability, data, or deployment impact"
create_label "type:feature" "1D76DB" "New functionality"
create_label "type:fix" "0E8A16" "Defect fix"
create_label "type:hotfix" "B60205" "Urgent production fix"
create_label "type:docs" "0075CA" "Documentation-only change"
create_label "type:infra" "5319E7" "Infrastructure, deployment, or CI/CD change"
create_label "type:security" "D93F0B" "Security-relevant change"
create_label "type:dependency" "0366D6" "Dependency update"
create_label "repo:production" "0E8A16" "Production-grade repository"
create_label "compliance:review-required" "B60205" "Requires compliance or security review"

echo "Configuring code security settings where available"
run_optional "enable vulnerability alerts" \
  gh api --method PUT "repos/$repo/vulnerability-alerts" \
    >/dev/null

run_optional "enable Dependabot security updates" \
  gh api --method PUT "repos/$repo/automated-security-fixes" \
    >/dev/null

security_file="$(mktemp)"
cat >"$security_file" <<'JSON'
{
  "security_and_analysis": {
    "secret_scanning": {
      "status": "enabled"
    },
    "secret_scanning_push_protection": {
      "status": "enabled"
    }
  }
}
JSON
run_optional "enable secret scanning and push protection" \
  gh api --method PATCH "repos/$repo" \
    --input "$security_file" \
    >/dev/null
rm -f "$security_file"

echo "Applying strict main branch protection"
gh api \
  --method PUT "repos/$repo/branches/main/protection" \
  --input .github/examples/main-branch-protection-strict.json \
  >/dev/null

echo "Repository bootstrap complete for $repo"
