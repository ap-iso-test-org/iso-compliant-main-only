# GitHub Organization Policy Baseline

This document defines the recommended organization-level policies for an ISO-oriented GitHub organization.

## Applied in the Test Organization

The following settings were applied to `ap-iso-test-org`:

| Area | Setting | Value |
| --- | --- | --- |
| Access | Base repository permission | `none` |
| Repository lifecycle | Member repository creation | Disabled |
| Repository lifecycle | Member public repository creation | Disabled |
| Repository lifecycle | Member private repository creation | Disabled |
| Repository lifecycle | Private repository forking | Disabled |
| Repository lifecycle | Organization projects | Disabled |
| Repository lifecycle | Repository projects | Disabled |
| Pages | Member Pages creation | Disabled |
| Actions | Enabled repositories | All |
| Actions | Allowed actions | Selected actions only |
| Actions | GitHub-owned actions | Allowed |
| Actions | Verified Marketplace actions | Disabled |
| Actions | Default `GITHUB_TOKEN` permission | Read-only |
| Actions | Actions can approve pull requests | Disabled |

## Manual or Plan-Limited Settings

The following settings should be enforced in a real ISO organization, but were not fully enforceable in the Free test organization through the API:

| Area | Recommended setting | Note |
| --- | --- | --- |
| Authentication | Require 2FA for all members | API call did not change the setting in the Free test org; set this in the GitHub UI. |
| Repository lifecycle | Members cannot delete repositories | API response kept this enabled; verify in the UI or enforce through higher plan policies. |
| Repository lifecycle | Members cannot change repository visibility | API response kept this enabled; verify in the UI or enforce through higher plan policies. |
| Collaboration | Members cannot invite outside collaborators without approval | API response kept this enabled; verify in the UI or enforce through higher plan policies. |
| Team management | Members cannot create teams | API response kept this enabled; verify in the UI or enforce through higher plan policies. |
| Rulesets | Org rulesets targeting custom properties | Requires GitHub Team or higher in this test org. |

## Recommended Production Baseline

For a production ISO-compliant organization:

- Require 2FA for all members.
- Set base permissions to `none`.
- Grant repository access through teams.
- Restrict repository creation to administrators or a platform team.
- Restrict public repositories and visibility changes.
- Restrict repository deletion and transfer.
- Disable private repository forking by default.
- Restrict outside collaborator invitations.
- Use custom properties as the source of truth for repository classification.
- Use organization rulesets targeting `iso_classification=iso-compliant`.
- Set `GITHUB_TOKEN` default permissions to read-only.
- Restrict GitHub Actions to GitHub-owned, org-owned, or explicitly approved actions.
- Disable repository-level self-hosted runners unless centrally managed.

## Intended Ruleset

When available, create the org ruleset from:

```bash
gh api --method POST orgs/ORG/rulesets --input .github/examples/org-ruleset-iso-compliant-main.json
```

This ruleset targets repositories where:

- `iso_classification=iso-compliant`
- `branching_strategy=main-only`
- branch is `main`

It requires:

- Pull requests.
- One approval.
- Stale review dismissal.
- Last-push approval.
- Required conversation resolution.
- Required release-label status check.
- No force pushes.
- No branch deletion.

