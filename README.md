# ISO Compliant Main-Only Repository Template

This repository is a governance-only GitHub template for production-grade repositories that use `main` as the only long-lived branch.

## Intended Use

Use this template for repositories where:

- `main` is the production-ready source of truth.
- Work is done on short-lived branches.
- All changes enter `main` through pull requests.
- Release impact is tracked using PR labels.
- Branch protection, CI checks, and review evidence are required.

## Default Branching Model

- `main` is protected.
- Short-lived branches use names such as `feature/<ticket-id>-short-name`, `fix/<ticket-id>-short-name`, or `hotfix/<ticket-id>-short-name`.
- Pull requests target `main`.
- Squash merge is acceptable for short-lived branches.
- Release versions should be created from protected `v*` tags or reviewed release PRs.

## Included Governance Files

- `.github/pull_request_template.md`
- `.github/ISSUE_TEMPLATE/production_change.yml`
- `.github/workflows/validate-release-label.yml`
- `.github/examples/main-branch-protection-strict.json`
- `CODEOWNERS`
- `docs/github-labels.md`
- `github-compliance-engineering-guidance.md`

## Required Setup After Creating a Repository

GitHub template repositories copy files, but they do not reliably copy all repository settings, labels, branch protection, or rulesets.

After creating a repository from this template:

1. Update `CODEOWNERS` with real teams or users.
2. Run the bootstrap script:

   ```bash
   scripts/bootstrap-main-only-repo.sh OWNER/REPO
   ```

3. Confirm the release-label workflow runs on pull requests to `main`.
4. Confirm force pushes and branch deletion are disabled for `main`.

The bootstrap script creates labels, applies `iso-compliant` repository metadata, configures merge settings, disables rebase merge, enables delete-branch-on-merge, restricts default Actions permissions, enables available code-security settings, and applies strict `main` branch protection.

Some security settings depend on GitHub plan, organization policy, and token scope. If a setting cannot be applied, the script prints a warning and continues so the remaining controls are still configured.

## Repository Classification

Repositories bootstrapped from this template are classified as ISO-compliant using organization custom properties as the source of truth:

- `iso_classification=iso-compliant`
- `repo_template=iso-compliant-main-only`
- `branching_strategy=main-only`

Repository topics are also applied as a convenience mirror for search and discovery:

- `iso-compliant`
- `iso-27001`
- `production`
- `main-only`
- `github-template`

Use custom properties for governance, reporting, and audit evidence. Use topics only for human-friendly discovery.

## Compliance Position

This template supports ISO 27001-aligned change control, traceability, review, and release governance. It does not make a repository compliant by itself. Teams must still configure access control, secrets, CI checks, deployment approvals, monitoring, and data handling according to repository risk.
