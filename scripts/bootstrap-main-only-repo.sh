#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 OWNER/REPO" >&2
  exit 1
fi

repo="$1"
owner="${repo%%/*}"
repo_name="${repo##*/}"

run_optional() {
  local description="$1"
  local output
  shift

  if ! output="$("$@" 2>&1)"; then
    echo "Warning: could not ${description}. This may require a different GitHub plan, token scope, or organization setting." >&2
    if [[ "$output" == *"admin:org"* ]]; then
      echo "Hint: GitHub custom properties require the admin:org scope. Run: gh auth refresh -h github.com -s admin:org" >&2
    fi
  fi
}

set_repo_topics() {
  local topics_json

  topics_json="$(
    gh api "repos/$repo/topics" --jq '.names' |
      jq -c '(. - ["iso-27001"]) + ["iso-compliant", "production", "main-only", "github-template"] | unique'
  )"

  local topics_file
  topics_file="$(mktemp)"
  jq -n --argjson names "$topics_json" '{names: $names}' >"$topics_file"

  gh api \
    --method PUT "repos/$repo/topics" \
    --input "$topics_file" \
    >/dev/null

  rm -f "$topics_file"
}

set_org_custom_properties() {
  local schema_file values_file

  schema_file="$(mktemp)"
  cat >"$schema_file" <<'JSON'
{
  "properties": [
    {
      "property_name": "iso_classification",
      "value_type": "single_select",
      "required": false,
      "description": "ISO compliance classification for the repository.",
      "allowed_values": [
        "iso-compliant",
        "iso-exempt"
      ],
      "values_editable_by": "org_actors"
    },
    {
      "property_name": "repo_template",
      "value_type": "string",
      "required": false,
      "description": "Governance template used to initialize the repository.",
      "values_editable_by": "org_actors"
    },
    {
      "property_name": "branching_strategy",
      "value_type": "single_select",
      "required": false,
      "description": "Approved branching strategy for the repository.",
      "allowed_values": [
        "main-only",
        "main-develop",
        "prototype"
      ],
      "values_editable_by": "org_actors"
    }
  ]
}
JSON

  gh api \
    --method PATCH "orgs/$owner/properties/schema" \
    --input "$schema_file" \
    >/dev/null || {
      rm -f "$schema_file"
      return 1
    }
  rm -f "$schema_file"

  values_file="$(mktemp)"
  jq -n \
    --arg repo_name "$repo_name" \
    '{
      repository_names: [$repo_name],
      properties: [
        {property_name: "iso_classification", value: "iso-compliant"},
        {property_name: "repo_template", value: "iso-compliant-main-only"},
        {property_name: "branching_strategy", value: "main-only"}
      ]
    }' >"$values_file"

  gh api \
    --method PATCH "orgs/$owner/properties/values" \
    --input "$values_file" \
    >/dev/null || {
      rm -f "$values_file"
      return 1
    }
  rm -f "$values_file"
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

echo "Applying repository classification metadata"
run_optional "apply repository topics" set_repo_topics
run_optional "apply organization custom properties" set_org_custom_properties

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

echo "Enabling required signed commits on main"
run_optional "require signed commits on main" \
  gh api --method POST "repos/$repo/branches/main/protection/required_signatures" \
    >/dev/null

echo "Repository bootstrap complete for $repo"
echo
echo "Reminder: required signed commits are now enforced on main."
echo "Every contributor must register a signing key with GitHub and configure"
echo "git locally. See 'Signing-key onboarding' in github-compliance-engineering-guidance.md."
