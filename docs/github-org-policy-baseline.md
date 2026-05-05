# GitHub Organization Policy Baseline

This document defines the recommended organization-level policies for an ISO 27001-oriented GitHub organization.

It is intended to be readable both as engineering guidance (what we configure and why) and as audit evidence (what controls are in place and how they are verified).

## Applied in the Test Organization

The following settings were applied to `ap-iso-test-org` and verified via API:

| Area | Setting | Value | ISO 27001 reference |
| --- | --- | --- | --- |
| Access | Base repository permission | `none` | A.5.15, A.8.2 |
| Repository lifecycle | Member repository creation | Disabled | A.5.10, A.8.2 |
| Repository lifecycle | Member public repository creation | Disabled | A.5.10 |
| Repository lifecycle | Member private repository creation | Disabled | A.5.10 |
| Repository lifecycle | Private repository forking | Disabled | A.8.4 |
| Repository lifecycle | Organization projects | Disabled | A.5.10 |
| Repository lifecycle | Repository projects | Disabled | A.5.10 |
| Pages | Member Pages creation | Disabled | A.5.10 |
| Actions | Enabled repositories | All | A.8.28 |
| Actions | Allowed actions | Selected actions only | A.5.32, A.8.28 |
| Actions | GitHub-owned actions | Allowed | A.8.28 |
| Actions | Verified Marketplace actions | Disabled | A.8.28, A.8.30 |
| Actions | Default `GITHUB_TOKEN` permission | Read-only | A.8.28 |
| Actions | Actions can approve pull requests | Disabled | A.5.30, A.8.28 |

## Manual or Plan-Limited Settings

Some settings cannot be enforced through the GitHub Free API in the dummy org. These are documented separately in `docs/dummy-vs-production-deltas.md` so the production org can apply them on replication.

| Area | Recommended setting | Note |
| --- | --- | --- |
| Authentication | Require 2FA for all members | Not enforced in dummy org via API; production org must enable in UI. ISO 27001 A.5.17, A.8.5. |
| Repository lifecycle | Members cannot delete repositories | API flag did not persist on Free plan. ISO 27001 A.8.4. |
| Repository lifecycle | Members cannot change repository visibility | API flag did not persist on Free plan. ISO 27001 A.8.4. |
| Collaboration | Members cannot invite outside collaborators without approval | API flag did not persist on Free plan. ISO 27001 A.8.30. |
| Team management | Members cannot create teams | API flag did not persist on Free plan. ISO 27001 A.5.15. |
| Rulesets | Org rulesets targeting custom properties | Requires GitHub Team plan. ISO 27001 A.8.32. |
| Code security | Dependabot alerts and secret scanning enabled by default for new repos | Requires Team plan or higher; private repo secret scanning needs Advanced Security on Enterprise. ISO 27001 A.8.7, A.8.8. |

## Recommended Production Baseline

For a production ISO 27001-aligned organization:

### Identity and access

- Require 2FA for all members. Prefer hardware-backed second factor or passkeys.
- Set base repository permission to `none`.
- Grant repository access through teams, never to individuals.
- Restrict outside collaborator invitations to org owners.
- Restrict team creation to org owners.
- Run a quarterly access review using the output of `scripts/collect-audit-evidence.sh` as the input.

### Repository lifecycle

- Restrict repository creation to org owners or a platform-engineering team.
- Restrict public repository creation.
- Restrict repository visibility changes to owners.
- Restrict repository deletion and transfer to owners.
- Disable private repository forking by default.
- Use organization custom properties as the source of truth for repository classification (`iso_classification`, `repo_template`, `branching_strategy`).

### Change control on `main`

Every protected `main` branch in a repository classified `iso_classification=iso-compliant` must enforce:

- Pull request required.
- **At least 1 approving review** (production org). Single-user dummy orgs may set this to 0 as documented in `docs/dummy-vs-production-deltas.md`, but no production-classified repository should ever ship with a 0-approval main branch.
- Last-push approval required (re-review after new commits).
- Stale review dismissal.
- CODEOWNERS review required for sensitive paths.
- Required release-impact label status check.
- Required conversation resolution.
- **Required signed commits** (`required_signatures: true`). Every contributor must register a signing key with GitHub and configure local git accordingly. See `github-compliance-engineering-guidance.md` "Signing-key onboarding".
- No force pushes.
- No branch deletion.
- Admin enforcement enabled (no bypass for org owners on production-classified repos).

### Approval-bypass policy (ISO-allowed exceptions)

Production org policy is **always 1 reviewer minimum**. The "always" stance is deliberate: relaxing the gate up front for narrow scenarios increases the risk that an exception becomes the default. Instead, exceptions are handled by **post-hoc review**:

- **Emergency hotfixes** under documented break-glass procedure: a separately-recorded incident ticket and a follow-up review within 24 hours, captured in the incident record.
- **Approved bot PRs** (e.g. Dependabot version bumps): allowed to merge after CI green via auto-merge, but the org owner reviews bot-merged PRs in aggregate weekly.
- **Single-author working sessions** outside the production org: not permitted on production-classified repos.

These exceptions live in `github-compliance-engineering-guidance.md` and the incident-management policy. They do not change the branch protection setting itself.

### Actions and supply-chain

- Set `GITHUB_TOKEN` default permissions to read-only.
- Restrict Actions to GitHub-owned, org-owned, and explicitly approved third-party actions.
- Disable repository-level self-hosted runners unless centrally managed and isolated.
- Disable "Actions can approve pull requests".

### Security and visibility

- Enable Dependabot alerts and security updates organization-wide.
- Enable secret scanning and push protection.
- Enable repository-level vulnerability alerts.
- Triage security alerts on a documented SLA tied to severity.

### Audit and evidence

- Capture the quarterly evidence snapshot using `scripts/collect-audit-evidence.sh`.
- Export and retain the GitHub audit log quarterly.
- Conduct an annual ISMS review of this baseline document.

## Intended Org Ruleset

When the organization is on GitHub Team or higher, create the org ruleset from:

```bash
gh api --method POST orgs/ORG/rulesets --input .github/examples/org-ruleset-iso-compliant-main.json
```

This ruleset targets repositories where:

- `iso_classification=iso-compliant`
- `branching_strategy=main-only`
- branch is `main`

It enforces:

- Pull requests.
- At least 1 approval.
- Stale review dismissal.
- Last-push approval.
- Required conversation resolution.
- Required release-impact label status check.
- Required signed commits.
- No force pushes.
- No branch deletion.

The ruleset complements per-repo branch protection. Where both are present, ruleset rules take precedence and apply across every targeted repo without per-repo configuration drift.

## Verification

The verification commands listed in `docs/iso-github-org-replication-checklist.md` should be re-run as part of every quarterly evidence cycle.
