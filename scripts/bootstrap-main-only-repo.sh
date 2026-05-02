#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 OWNER/REPO" >&2
  exit 1
fi

repo="$1"

echo "Configuring repository settings for $repo"
gh api \
  --method PATCH "repos/$repo" \
  -f has_issues=true \
  -f has_wiki=false \
  -f delete_branch_on_merge=true \
  -f allow_squash_merge=true \
  -f allow_merge_commit=true \
  -f allow_rebase_merge=false \
  >/dev/null

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  if gh label view "$name" --repo "$repo" >/dev/null 2>&1; then
    gh label edit "$name" --repo "$repo" --color "$color" --description "$description" >/dev/null
  else
    gh label create "$name" --repo "$repo" --color "$color" --description "$description" >/dev/null
  fi
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
create_label "type:docs" "0075CA" "Documentation-only change"
create_label "type:infra" "5319E7" "Infrastructure, deployment, or CI/CD change"

echo "Applying strict main branch protection"
gh api \
  --method PUT "repos/$repo/branches/main/protection" \
  --input .github/examples/main-branch-protection-strict.json \
  >/dev/null

echo "Repository bootstrap complete for $repo"
