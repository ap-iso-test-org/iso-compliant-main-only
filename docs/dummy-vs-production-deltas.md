# Dummy Org vs Production Org Deltas

## Purpose

This document lists every place where the configuration in `ap-iso-test-org` (the public dummy reference org, on GitHub Free) intentionally differs from the configuration the production company organization (on GitHub Team) must apply when replicating these controls.

Anything in this document **must be flipped on** in the production org. Nothing here should be treated as a tolerable long-term gap.

## Why the Dummy Org Has Deltas

Three reasons account for every deviation:

1. **GitHub Free plan limits**: features such as organization rulesets and some organization-level security defaults are gated to GitHub Team or higher.
2. **Single-user team**: with one human in the org, controls that require segregation of duties (1+ approver, dual control on releases) cannot be exercised end-to-end.
3. **Public repos for demonstration**: the dummy org uses public repos so the configuration is browsable as a reference; the production org will use private/internal repos.

## Delta Inventory

### Authentication and Membership

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| 2FA enforcement org-wide | Off | On | Free plan + single user + API call did not persist | Org settings → Authentication security → Require two-factor authentication. ISO 27001 A.5.17 / A.8.5. |
| Members can delete repositories | Stays enabled in API | Disabled | API flag did not persist on Free plan | Org settings → Member privileges → uncheck "Allow members to delete or transfer repositories". |
| Members can change repo visibility | Stays enabled in API | Disabled | API flag did not persist on Free plan | Org settings → Member privileges → uncheck "Allow members to change repository visibilities". |
| Members can invite outside collaborators | Stays enabled in API | Disabled | API flag did not persist on Free plan | Org settings → Member privileges → "Repository invitations" → owners only. |
| Members can create teams | Stays enabled in API | Disabled | API flag did not persist on Free plan | Org settings → Member privileges → uncheck "Allow members to create teams". |

### Approvals and Reviews

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| Required approving reviewers on `main` | 0 (template repo); 1 (example repo) | **Always 1 minimum** on every protected branch | Single-user dummy org cannot self-approve; example repo demonstrates the production setting | `gh api -X PUT repos/ORG/REPO/branches/main/protection` with `required_pull_request_reviews.required_approving_review_count: 1`. ISO 27001 A.5.30, A.8.4, A.8.32. |
| CODEOWNERS review required | Off | On for sensitive paths (see `CODEOWNERS`) | Single-user dummy org has no real teams to assign | Branch protection → "Require review from Code Owners". Requires the org to first create the teams referenced in `CODEOWNERS`. |
| Last-push approval required | Off (template); on (example) | On | Template demonstrates baseline; example shows production setting | `required_pull_request_reviews.require_last_push_approval: true`. |

### Org-Level Rulesets and Classification Enforcement

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| Org rulesets targeting custom properties | None (API returns 403) | Active for `iso_classification=iso-compliant` | Free plan blocks org rulesets | `gh api --method POST orgs/ORG/rulesets --input .github/examples/org-ruleset-iso-compliant-main.json`. ISO 27001 A.8.32. |
| Tag protection for `v*` release tags | None | Active | Same plan limit | Create org tag ruleset blocking deletion and force-update of `v*`. ISO 27001 A.5.33, A.8.32. |
| Ruleset for prototype/exempt repos | None | Light protection on `iso_classification=iso-exempt` | Plan limit | Separate ruleset, lighter controls (see `github-compliance-engineering-guidance.md`). |

### Code Security

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| Org default: Dependabot alerts on new repos | Off | On | Plan default | Org settings → Code security and analysis → enable for new repositories. ISO 27001 A.8.8. |
| Org default: Dependabot security updates on new repos | Off | On | Plan default | Same UI page. |
| Org default: secret scanning on new repos | Off | On | Plan/visibility (free private repos lack secret scanning) | Same UI page. ISO 27001 A.5.33, A.8.7. |
| Org default: secret scanning push protection | Off | On | Plan/visibility | Same UI page. |
| Advanced Security for private repos | Not available | Available on Team only for public; Enterprise for private | Plan limit | Enable per repo if on Enterprise; otherwise document compensating controls. |

### Required Signed Commits

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| `required_signatures` on `main` of all production repos | Enabled on `iso-compliant-main-only` and `example-from-main-only-template` (post replication) | Enabled on every repo with `iso_classification=iso-compliant` | None — same setting, just broader application | Add to org ruleset and `scripts/bootstrap-main-only-repo.sh`. ISO 27001 A.5.33, A.8.5, A.8.24. Each contributor must register a signing key — see "Signing-key onboarding" in `github-compliance-engineering-guidance.md`. |

### Audit Log Retention and Review

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| Quarterly audit log export | Not yet performed | Quarterly with 3-year retention | No production-grade evidence cycle yet | Run `scripts/collect-audit-evidence.sh` and capture audit log via Org settings → Logs → Audit log → Export, or `gh api orgs/ORG/audit-log` (Team plan API). ISO 27001 A.8.15. |
| Quarterly access review | Not yet performed | Quarterly | Single-user org | Use `scripts/collect-audit-evidence.sh` member and team output as the review input; record reviewer sign-off. ISO 27001 A.5.18. |

### Outside Collaborators and Apps

| Setting | Dummy org (current) | Production org (required) | Reason for delta | How to flip on |
| --- | --- | --- | --- | --- |
| Outside collaborator approval workflow | Not configured | Required | No external collaborators in dummy org | Org settings → Member privileges → require admin approval for outside collaborator invites. ISO 27001 A.8.30. |
| Third-party app approval policy | Default (open) | Restricted to org-owner approval | None — should also be set in dummy org | Org settings → Third-party access → "Setup application access restrictions". |

## Replication Procedure

When applying this configuration in the production org:

1. Run `scripts/bootstrap-org-policies.sh ORG`.
2. Walk through the deltas above in the GitHub UI to fix everything the API could not.
3. Apply the org rulesets from `.github/examples/`.
4. Bootstrap each repo with `scripts/bootstrap-main-only-repo.sh`.
5. Run `scripts/collect-audit-evidence.sh` to produce the first quarterly snapshot.
6. Schedule recurring tasks for the quarterly snapshot, audit-log export, access review, and dependency-alert review.

## Maintenance

This document should be refreshed whenever:

- A delta is closed (remove the row).
- A new dummy-org limitation is discovered.
- GitHub changes plan boundaries or default settings.
- The org upgrades plan tier.

The objective is for this document to converge to "no deltas" once the production org has fully adopted the controls.
