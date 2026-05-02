# GitHub Organization Repository Defaults

This document defines recommended organization-level repository defaults for an ISO-oriented GitHub organization.

## Recommended Repository Defaults

Configure these in:

```text
Organization -> Settings -> Repository -> Repository defaults
```

Recommended values:

| Setting | Recommended value | Reason |
| --- | --- | --- |
| Default branch name | `main` | Standardizes branch protection and rulesets. |
| Default labels | Standard label set below | Ensures new repositories get consistent issue and PR labels. |
| Projects | Disabled unless used | Reduces unused collaboration surface. |
| Wikis | Disabled unless used | Reduces uncontrolled documentation surface. |
| Merge commit | Enabled | Required for long-lived branch promotion workflows. |
| Squash merge | Enabled | Useful for short-lived feature branches. |
| Rebase merge | Disabled | Avoids history rewrite complexity in controlled repositories. |
| Auto-delete head branches | Enabled | Reduces stale branch accumulation. |

Some repository defaults are not fully configurable through the public REST API. Use the GitHub UI for organization default labels and verify settings manually.

## Standard Default Labels

Default labels apply to new repositories only. They do not update existing repositories.

Create these labels at organization level:

| Label | Color | Description |
| --- | --- | --- |
| `release:major` | `B60205` | Breaking or incompatible release impact. |
| `release:minor` | `1D76DB` | Backward-compatible feature release impact. |
| `release:patch` | `0E8A16` | Backward-compatible fix or maintenance release impact. |
| `release:exempt` | `C5DEF5` | No release version impact. |
| `risk:low` | `D4C5F9` | Low operational, data, or security risk. |
| `risk:medium` | `FBCA04` | Material change requiring standard review. |
| `risk:high` | `D93F0B` | High-impact change requiring owner or security review. |
| `risk:prod-impact` | `B60205` | Production behavior, availability, data, or deployment impact. |
| `type:feature` | `1D76DB` | New functionality. |
| `type:fix` | `0E8A16` | Defect fix. |
| `type:hotfix` | `B60205` | Urgent production fix. |
| `type:docs` | `0075CA` | Documentation-only change. |
| `type:infra` | `5319E7` | Infrastructure, deployment, or CI/CD change. |
| `type:security` | `D93F0B` | Security-relevant change. |
| `type:dependency` | `0366D6` | Dependency update. |
| `repo:production` | `0E8A16` | Production-grade repository. |
| `repo:prototype` | `C5DEF5` | Prototype or ISO-exempt repository. |
| `compliance:review-required` | `B60205` | Requires compliance or security review. |
| `repo-request` | `5319E7` | Repository creation or classification request. |

## What Labels Are For

Labels classify issues and pull requests. They are not repository classification metadata.

Use labels for:

- Release impact on PRs.
- Risk level of a change.
- Type of change.
- Routing review work.
- Repository request intake issues.
- Automation inputs, such as version bump calculation.

Use custom properties for:

- Official repository ISO classification.
- Branching strategy.
- Template used.
- Audit and governance reporting.

If labels and custom properties conflict, custom properties win.

## Existing Repositories

Organization default labels do not update existing repositories.

For existing repositories, run the relevant bootstrap script:

```bash
scripts/bootstrap-main-only-repo.sh ORG/REPO
```

