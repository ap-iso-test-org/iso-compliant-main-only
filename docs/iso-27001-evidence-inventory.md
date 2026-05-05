# ISO/IEC 27001 Evidence Inventory

## Purpose

ISO 27001 audits are evidence-driven. Auditors do not ask "do you have controls?" — they ask "show me." This document lists every artifact the audit team should be able to produce on request, where it lives, who owns it, and how it is captured.

The companion script `scripts/collect-audit-evidence.sh` produces a quarterly snapshot of the API-accessible items below into a timestamped directory.

## Evidence Categories

### 1. Continuous Evidence (lives in GitHub itself)

These artifacts do not need separate capture. The auditor is given read access or shown a sample.

| Evidence | ISO control | Where it lives | Sample auditor request |
| --- | --- | --- | --- |
| Pull request with linked ticket, release label, review, CI green, merge | A.8.4, A.8.32 | Each repo's PR list | "Show me a random PR from the last quarter that touched production code." |
| `CODEOWNERS` file | A.5.30, A.8.4 | Each repo's root | "Show me the CODEOWNERS file for service X." |
| Branch protection JSON | A.8.4, A.8.32 | `gh api repos/ORG/REPO/branches/main/protection` | "Show me the protection rule on `main` for service X." |
| Signed-commit verification | A.5.33, A.8.5, A.8.24 | Any commit page in GitHub UI shows "Verified" badge | "Show me 5 random recent commits and their signature status." |
| Dependabot alerts | A.8.8 | Repo Security tab | "Show open critical alerts and the SLA for remediation." |
| Secret scanning alerts | A.5.33, A.8.7 | Repo Security tab | "Show how a leaked secret would be blocked at push time." |

### 2. Periodic Snapshots (captured by `scripts/collect-audit-evidence.sh`)

Run quarterly. Output committed to a controlled-access evidence repository or stored in an audit-evidence bucket. Filename pattern: `YYYY-QN/<control>.json`.

| Evidence | ISO control | API source | Cadence |
| --- | --- | --- | --- |
| Org settings | A.5.15, A.8.2 | `gh api orgs/ORG` | Quarterly |
| Org Actions policy | A.5.10, A.8.28 | `gh api orgs/ORG/actions/permissions` and `.../selected-actions` and `.../workflow` | Quarterly |
| Org rulesets | A.8.32 | `gh api orgs/ORG/rulesets` (Team plan) | Quarterly |
| Custom property schema | A.8.3, A.8.9 | `gh api orgs/ORG/properties/schema` | Quarterly |
| Custom property values per repo | A.8.3, A.8.9 | `gh api orgs/ORG/properties/values` | Quarterly |
| Repo list with visibility and topics | A.8.1 | `gh api orgs/ORG/repos` | Quarterly |
| Branch protection per repo | A.8.4, A.8.32 | `gh api repos/ORG/REPO/branches/main/protection` | Quarterly |
| Repo Actions permissions | A.8.28 | `gh api repos/ORG/REPO/actions/permissions` | Quarterly |
| Repo security and analysis flags | A.8.7, A.8.8 | `gh api repos/ORG/REPO --jq '.security_and_analysis'` | Quarterly |
| Repo labels | A.8.32 | `gh api repos/ORG/REPO/labels` | Quarterly |
| Members list | A.5.15, A.8.2 | `gh api orgs/ORG/members` | Quarterly |
| Teams list and members | A.5.15, A.5.18 | `gh api orgs/ORG/teams` and per-team members | Quarterly |
| Outside collaborators | A.5.15, A.8.30 | `gh api orgs/ORG/outside_collaborators` | Quarterly |
| Installed apps and integrations | A.8.30 | `gh api orgs/ORG/installations` | Quarterly |

### 3. Manually-Captured Records (no API; stored alongside snapshots)

| Evidence | ISO control | Source | Cadence |
| --- | --- | --- | --- |
| Org Authentication security screenshot showing 2FA required | A.5.17, A.8.5 | Org settings UI | Quarterly |
| Member Privileges screenshot | A.5.10, A.5.15 | Org settings UI | Quarterly |
| Repository Defaults screenshot (merge buttons, labels, branch name) | A.8.32 | Org settings UI | Quarterly |
| Quarterly access review record | A.5.18 | Spreadsheet or ticket with reviewer sign-off | Quarterly |
| Annual ISMS policy review sign-off | A.5.1 | ISMS document version control | Annual |
| Risk register entries for accepted GitHub-related risks | A.5.4, A.6.6 | Risk register | Reviewed quarterly |
| Audit log export | A.8.15, A.8.16 | Org settings → Logs → Audit log → Export (or `gh api orgs/ORG/audit-log`) | Quarterly, retained 12 months minimum |
| Dependabot remediation log | A.8.8 | Per-alert resolution timestamp captured at quarterly snapshot time | Quarterly |
| Onboarding tickets for new GitHub members | A.6.1, A.5.16 | HR or IT ticketing system | Per event |
| Offboarding tickets for removed members | A.6.5 | HR or IT ticketing system | Per event |
| Incident records for any GitHub-related security event | A.5.24, A.5.27 | Incident management system | Per event |

### 4. Per-Release Evidence

For each production release, the following must be reconstructible from GitHub data alone:

| Evidence | ISO control | Source |
| --- | --- | --- |
| Release tag (`v*`) protected and signed | A.5.33, A.8.32 | `gh api repos/ORG/REPO/git/refs/tags/v*` |
| Release notes | A.8.32 | `gh release view vX.Y.Z` |
| List of merged PRs in the release | A.8.32 | `gh pr list --state merged --search "merged:>YYYY-MM-DD"` |
| Reviewer for each PR in the release | A.5.30, A.8.4 | PR review history |
| CI status for each PR | A.8.29 | PR check runs |
| Deployment record (if applicable) | A.8.32 | `gh api repos/ORG/REPO/deployments` |

## Retention

| Category | Retention | Reason |
| --- | --- | --- |
| Quarterly snapshots | 3 years minimum | Covers two ISO surveillance cycles plus recertification. |
| Annual sign-offs | 6 years | Beyond two recertifications. |
| Audit log exports | 12 months minimum, 3 years preferred | GitHub Team default retention is shorter than typical audit cycle. |
| Incident records | 6 years | Standard incident retention. |
| Per-release records | Lifetime of the released artifact + 12 months | Release auditability. |

## How to Run a Quarterly Snapshot

```bash
scripts/collect-audit-evidence.sh ORG ./evidence/2026-Q2
```

The script will:

1. Create the output directory.
2. Capture each API source listed in section 2 to a separate JSON file.
3. Iterate over every repo in the org and capture per-repo branch protection, security flags, labels, custom property values, and Actions permissions.
4. Write a `MANIFEST.txt` listing every file and the timestamp of capture.
5. Refuse to overwrite an existing snapshot directory (audit-trail integrity).

After running the script, the evidence collector should:

- Capture the manual UI screenshots listed in section 3.
- Append the quarterly access review record.
- Commit or upload the snapshot to the controlled-access evidence store.
- Tag the snapshot in the evidence repository as `evidence/YYYY-Qn`.

## Auditor Walk-Through Outline

When the auditor arrives, the recommended walk-through order is:

1. Show the latest snapshot directory and the `MANIFEST.txt`.
2. Show `docs/iso-27001-control-mapping.md` so the auditor can navigate by control reference.
3. Walk through one sample PR end-to-end (linked ticket → label → review → CI → merge → release).
4. Show one sample release tag with notes, PR list, signed tag, and deployment record.
5. Show the access review record and the most recent quarterly audit-log export.
6. Show the risk register and any accepted-risk entries relevant to GitHub.
