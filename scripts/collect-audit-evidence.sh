#!/usr/bin/env bash
set -euo pipefail

# collect-audit-evidence.sh
#
# Captures a quarterly snapshot of ISO 27001-relevant GitHub configuration for
# `ORG` into `OUTDIR`. Refuses to overwrite an existing `OUTDIR` to preserve
# audit-trail integrity.
#
# Usage:
#   scripts/collect-audit-evidence.sh ORG OUTDIR
#
# Example:
#   scripts/collect-audit-evidence.sh ap-iso-test-org ./evidence/2026-Q2
#
# After running, capture the manual artifacts listed in
# docs/iso-27001-evidence-inventory.md (UI screenshots, access-review record,
# audit-log export) into the same OUTDIR before committing or uploading.

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 ORG OUTDIR" >&2
  exit 1
fi

org="$1"
outdir="$2"

if [ -e "$outdir" ]; then
  echo "Refusing to overwrite existing path: $outdir" >&2
  echo "Choose a fresh directory name (e.g. ./evidence/$(date -u +%Y-Q%q))." >&2
  exit 1
fi

mkdir -p "$outdir/repos"

manifest="$outdir/MANIFEST.txt"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

{
  echo "ISO 27001 evidence snapshot"
  echo "Org:        $org"
  echo "Captured:   $timestamp"
  echo "Tool:       scripts/collect-audit-evidence.sh"
  echo
  echo "Files in this snapshot:"
} >"$manifest"

record() {
  local relpath="$1"
  local control="$2"
  echo "  $relpath  [$control]" >>"$manifest"
}

capture() {
  local relpath="$1"
  local control="$2"
  local fullpath="$outdir/$relpath"

  shift 2
  if "$@" >"$fullpath" 2>"$fullpath.err"; then
    rm -f "$fullpath.err"
    record "$relpath" "$control"
  else
    echo "Warning: capture failed for $relpath. See ${relpath}.err for details." >&2
    record "$relpath (FAILED — see .err file)" "$control"
  fi
}

echo "Capturing organization-level evidence for $org"
capture "org-settings.json"             "A.5.15,A.8.2"      gh api "orgs/$org"
capture "org-actions-permissions.json"  "A.5.10,A.8.28"     gh api "orgs/$org/actions/permissions"
capture "org-actions-selected.json"     "A.5.10,A.8.28"     gh api "orgs/$org/actions/permissions/selected-actions"
capture "org-actions-workflow.json"     "A.8.28"            gh api "orgs/$org/actions/permissions/workflow"
capture "org-rulesets.json"             "A.8.32"            gh api "orgs/$org/rulesets"
capture "org-property-schema.json"      "A.8.3,A.8.9"       gh api "orgs/$org/properties/schema"
capture "org-property-values.json"      "A.8.3,A.8.9"       gh api "orgs/$org/properties/values"
capture "org-members.json"              "A.5.15,A.8.2"      gh api "orgs/$org/members"
capture "org-teams.json"                "A.5.15,A.5.18"     gh api "orgs/$org/teams"
capture "org-outside-collaborators.json" "A.5.15,A.8.30"    gh api "orgs/$org/outside_collaborators"
capture "org-installations.json"        "A.8.30"            gh api "orgs/$org/installations"
capture "org-repos.json"                "A.8.1"             gh api --paginate "orgs/$org/repos"

echo "Capturing per-team membership"
mkdir -p "$outdir/teams"
team_slugs="$(gh api "orgs/$org/teams" --jq '.[].slug' 2>/dev/null || true)"
for slug in $team_slugs; do
  capture "teams/$slug-members.json"  "A.5.15,A.5.18"      gh api "orgs/$org/teams/$slug/members"
done

echo "Capturing per-repo evidence"
repo_names="$(gh api --paginate "orgs/$org/repos" --jq '.[].name')"
for name in $repo_names; do
  mkdir -p "$outdir/repos/$name"
  capture "repos/$name/repo-settings.json"        "A.8.4,A.8.9"   gh api "repos/$org/$name"
  capture "repos/$name/branch-protection.json"    "A.8.4,A.8.32"  gh api "repos/$org/$name/branches/main/protection"
  capture "repos/$name/actions-permissions.json"  "A.8.28"        gh api "repos/$org/$name/actions/permissions"
  capture "repos/$name/actions-workflow.json"     "A.8.28"        gh api "repos/$org/$name/actions/permissions/workflow"
  capture "repos/$name/labels.json"               "A.8.32"        gh api "repos/$org/$name/labels"
  capture "repos/$name/topics.json"               "A.8.1"         gh api "repos/$org/$name/topics"
  capture "repos/$name/property-values.json"      "A.8.3"         gh api "repos/$org/$name/properties/values"
  capture "repos/$name/codeowners.txt"            "A.5.30,A.8.4"  gh api "repos/$org/$name/contents/CODEOWNERS" --jq '.content' || true
done

{
  echo
  echo "Manual artifacts to add to this snapshot directory before commit:"
  echo "  - org-2fa-screenshot.png       (Org settings → Authentication security)"
  echo "  - org-member-privileges-screenshot.png"
  echo "  - org-repo-defaults-screenshot.png"
  echo "  - access-review-YYYY-Qn.{xlsx,pdf}"
  echo "  - audit-log-export-YYYY-Qn.json (Org settings → Logs → Audit log)"
  echo "  - dependabot-remediation-YYYY-Qn.csv"
} >>"$manifest"

echo "Snapshot complete: $outdir"
echo "Manifest: $manifest"
echo
echo "Reminder: capture the manual artifacts listed at the bottom of MANIFEST.txt"
echo "before you commit or upload this snapshot."
