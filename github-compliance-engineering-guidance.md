# Git Branch Control Guidance

## Purpose

This document provides example controls for common Git branch types in an ISO 27001-oriented GitHub environment.

The goal is not to mandate the same workflow for every repository. The goal is to apply controls based on risk, release impact, and auditability while keeping prototype work fast enough to remain useful.

## Core Principles

- Controls should follow risk and release influence, not branch name alone.
- Every long-lived branch should have an owner and a clear purpose.
- Any branch that can influence production should be protected.
- Direct pushes to long-lived branches should be avoided.
- Prototype repositories can be lighter, but they still need guardrails and documented risk acceptance.
- `develop`, `qa`, and `uat` branches should exist only where they map to a real workflow or environment.
- `main + develop` should not be the default strategy for every repository.

## Repository Classes

| Repository class | Examples | Recommended branching model |
| --- | --- | --- |
| Prototype / ISO-exempt | AI Lab experiments, proof-of-concepts, research notebooks | Protected `main`, short-lived branches optional |
| Production standard | Internal tools, applications, data pipelines, services | Trunk-based development with protected `main` |
| Production critical | Customer-impacting systems, regulated workflows, release-managed products | Protected `main`, optional `release/*`, optional environment branches |

## Branch Types and Recommended Controls

### `main`

**Purpose**

`main` is the production-ready source of truth. Code on `main` should be releasable, deployable, or directly traceable to released versions.

**Should have**

- Required pull request before merge.
- At least one approval from someone other than the author.
- CODEOWNERS approval for sensitive paths such as security, infrastructure, deployment, authentication, secrets handling, and compliance-relevant code.
- Required CI checks before merge.
- Required security checks where available, such as secret scanning, dependency scanning, SAST, IaC scanning, or container scanning.
- Linked ticket, change request, or documented business justification.
- No direct pushes except approved break-glass scenarios.
- No force pushes.
- No branch deletion.
- Required conversation resolution before merge.
- Merge queue where repository activity is high enough to justify it.
- Release tags or deployment records for production changes.

**Should not have**

- Routine direct commits by engineers or administrators.
- Force push exceptions for normal development.
- Unreviewed dependency, infrastructure, or deployment changes.
- Untraceable changes without a ticket or equivalent audit reference.
- Long-running experimental work committed directly.

### `release/*`

**Purpose**

Release branches support stabilization, patching, or maintenance of a specific version.

Use release branches only when there is a real need to maintain a release separately from active development.

**Should have**

- Required pull request before merge.
- Approval from a maintainer or release owner.
- Required CI checks relevant to the release.
- No force pushes.
- Restricted push access.
- Clear naming, such as `release/1.8` or `release/2026-Q2`.
- Back-merge or forward-merge process to keep `main` aligned where appropriate.
- Release notes or changelog linkage.

**Should not have**

- Open-ended feature development.
- Uncontrolled cherry-picking without traceability.
- Permanent existence after the release is no longer supported.
- Weaker controls than `main` if the branch can deploy to production.

### `hotfix/*`

**Purpose**

Hotfix branches support urgent production fixes.

**Should have**

- Short lifetime.
- Required pull request before merge unless a documented emergency bypass is used.
- Required CI checks, even if the check set is reduced for speed.
- Approval from a code owner, service owner, incident commander, or equivalent responsible person.
- Incident, problem, or change ticket reference.
- Post-implementation review if emergency controls were bypassed.
- Merge back into `main` and any relevant `release/*` branch.

**Should not have**

- Feature work.
- Broad refactoring unrelated to the incident.
- Permanent exceptions to normal branch controls.
- Silent bypasses without after-the-fact documentation.

### `develop`

**Purpose**

`develop` is an integration branch used before code reaches `main`.

Use `develop` only where the team has a genuine integration need. Do not create it by default.

**Should have**

- Required pull request before merge.
- Required CI checks.
- No force pushes.
- No direct pushes for production repositories.
- At least one approval for production repositories, unless the repository is explicitly low risk.
- Clear promotion path from `develop` to `qa`, `uat`, or `main`.
- Regular cleanup to avoid becoming a dumping ground.

**Could have, depending on risk**

- Lighter approval than `main`.
- Reduced security check set compared with `main`, provided full checks run before production release.
- More permissive merge cadence to support integration speed.

**Should not have**

- The same strict controls as `main` if doing so creates unnecessary duplicate friction without reducing risk.
- No controls at all if it is part of the path to production.
- Direct deployment to production.
- Long-lived unreviewed work.

### `qa`

**Purpose**

`qa` represents a shared test environment or quality assurance validation point.

**Should have**

- Required pull request before merge.
- Required automated tests relevant to QA deployment.
- No force pushes.
- Restricted direct push access.
- Clear deployment record to the QA environment.
- Clear promotion process to `uat`, `release/*`, or `main`.

**Could have, depending on risk**

- One approval rather than multiple approvals.
- CODEOWNERS only for sensitive paths.
- Reduced checks if full validation happens later in UAT or before production.

**Should not have**

- Uncontrolled direct pushes that change the QA environment without audit trail.
- Production secrets or customer production data.
- Assumption that QA approval equals production approval.
- Permanent divergence from `main` or `develop`.

### `uat`

**Purpose**

`uat` represents pre-production user acceptance testing or formal business validation.

If `uat` is part of the production release approval path, treat it as high risk.

**Should have**

- Required pull request before merge.
- Required approval from engineering.
- Required approval from product, business owner, QA owner, or release owner where applicable.
- Required CI checks.
- Required security checks if UAT artifacts are promoted to production.
- No force pushes.
- Restricted push access.
- Clear deployment record to the UAT environment.
- Clear sign-off evidence before production release.

**Should not have**

- Weaker controls than `main` if UAT artifacts are directly promoted to production.
- Direct commits from developers.
- Untested changes inserted after user acceptance.
- Production data unless formally approved and protected.

### `feature/*`

**Purpose**

Feature branches are short-lived working branches for planned changes.

**Should have**

- Naming tied to a ticket or work item, such as `feature/ABC-123-add-report-export`.
- Short lifetime.
- Secret scanning and push protection at the repository or organization level.
- PR into the target long-lived branch.
- Rebase or update before merge where required by repository policy.

**Could have**

- Minimal restrictions while work is in progress.
- Draft pull requests for early review.
- Temporary commits that are cleaned up before merge if the team requires clean history.

**Should not have**

- Direct deployment to production.
- Long-lived ownership by one person without review.
- Secrets, credentials, customer data, or large binary artifacts.
- Force pushes after review if doing so invalidates reviewer confidence, unless the team accepts this and requires re-review.

### `fix/*` or `bugfix/*`

**Purpose**

Fix branches are short-lived branches for non-emergency defects.

**Should have**

- Linked issue, ticket, or defect report.
- Required pull request into the target branch.
- Tests that reproduce or cover the fix where practical.
- Same review expectations as feature branches.

**Should not have**

- Emergency production bypass unless treated as `hotfix/*`.
- Unrelated refactoring that obscures the defect fix.
- Merge without validation simply because the change appears small.

### `experiment/*` or `spike/*`

**Purpose**

Experiment branches support research, prototyping, and technical exploration.

**Should have**

- Clear expiry or review date.
- Clear owner.
- No production secrets.
- No production customer data.
- Secret scanning and push protection.
- Explicit decision before merging into a production branch.

**Could have**

- Lightweight review.
- Relaxed commit history expectations.
- Relaxed test requirements if the branch is not merged or deployed.

**Should not have**

- Direct path to production.
- Automatic deployment to production-like environments.
- Long-term accumulation of unreviewed code.
- Promotion into production repositories without meeting production controls.

## Prototype / ISO-Exempt Repository Controls

Prototype repositories should move quickly, but ISO-exempt should not mean uncontrolled.

**Should have**

- Repository classification as `prototype`, `research`, or `iso-exempt`.
- Named owner or owning team.
- Risk acceptance record.
- Review or expiry date.
- Protected `main`.
- No force pushes to `main`.
- Secret scanning and push protection.
- Dependency visibility.
- Clear README stating purpose and non-production status.
- Controls preventing use of production secrets and production customer data.

**Could have**

- Optional pull requests.
- Self-merge after automated checks.
- Lightweight CI focused on linting, basic tests, and secrets.
- Fewer required approvals than production repositories.

**Should not have**

- Customer-facing production deployment.
- Production credentials.
- Production customer data.
- Silent transition into production use.
- Unclear ownership.
- Permanent ISO-exempt status without periodic review.

## Promotion From Prototype to Production

Before prototype code becomes production code, require a promotion review.

**Minimum promotion checks**

- Repository owner assigned.
- Repository classification changed from prototype to production where applicable.
- Threat or risk assessment completed.
- Data classification completed.
- Secrets removed and secret history reviewed where necessary.
- CI baseline established.
- Required tests defined.
- Dependency and license review completed.
- CODEOWNERS added for sensitive areas.
- Branch protection or rulesets applied.
- Deployment path documented.
- Support and incident ownership defined.
- Ticketing and change traceability enabled.

## Environment Segregation for Multi-Environment Deployments

ISO 27001 does not require a specific cloud account, subscription, or project structure. It requires development, test, and production environments to be separated and secured.

For cloud-hosted applications, separate projects or accounts are usually the cleaner control boundary. Service-level segregation inside a shared cloud project can be acceptable, but only if the segregation is deliberate, documented, and supported by strong controls.

### Preferred Pattern

Use separate cloud projects, accounts, or subscriptions for production and non-production environments where practical.

**Should have**

- Separate production and non-production IAM boundaries.
- Separate production and non-production secrets.
- Separate production and non-production service accounts.
- Separate production and non-production networks or strongly segmented network paths.
- Separate deployment permissions.
- Separate logging, monitoring, and alerting views where appropriate.
- Clear cost, asset, and ownership tagging.
- Documented promotion path from non-production to production.

**Why this is preferred**

- Easier to evidence environment separation.
- Easier to restrict production access.
- Lower chance of accidental production impact from dev or test activity.
- Cleaner blast-radius control.
- Cleaner audit explanation.

### Acceptable With Justification: Shared Cloud Project, Service-Level Segregation

A shared cloud project can be acceptable for lower-risk systems or legacy constraints if production and non-production are still logically separated and secured.

**Should have**

- Separate service accounts for each environment.
- IAM roles scoped to the minimum required services and resources.
- Separate secrets per environment.
- Clear naming and labels, such as `app-prod`, `app-dev`, `env=prod`, and `env=dev`.
- Separate databases, storage buckets, queues, topics, and runtime services.
- Network controls preventing unnecessary dev-to-prod access.
- CI/CD controls preventing dev deployment identities from deploying to production.
- Production deployment approvals.
- Audit logs showing who changed production resources.
- Monitoring that distinguishes production from non-production.
- Documented risk acceptance explaining why project-level segregation is not currently used.
- Periodic review of whether project-level segregation is now feasible.

**Should not have**

- Shared service accounts between dev and prod.
- Shared secrets between dev and prod.
- Shared databases or storage buckets containing production data.
- Developers with broad project-level permissions that allow unapproved production changes.
- CI/CD runners that can deploy to both dev and prod without separate approval gates.
- Production and development resources distinguishable only by informal naming.
- Testing in production by default.
- Production data copied to dev without masking, approval, and equivalent protection.

### High-Risk Cases Where Shared Projects Are Hard to Defend

Project-level segregation should be strongly preferred when any of the following apply:

- The app processes customer data, regulated data, financial data, health data, or confidential business data.
- Dev users have broad permissions in the shared project.
- Production availability matters to customers.
- Dev and prod use the same databases, buckets, service accounts, secrets, or networks.
- The same CI/CD identity can deploy to both dev and prod.
- There is no reliable audit trail distinguishing dev changes from production changes.
- A mistake in dev could affect production resources.
- The app is in scope for external customer commitments or contractual security obligations.

### Auditor-Friendly Evidence

For each multi-environment application, keep evidence that shows:

- Architecture diagram identifying dev, test, UAT, and production boundaries.
- IAM matrix showing who can access each environment.
- Service account matrix showing which identities deploy to each environment.
- Secret inventory showing separation between environments.
- Network diagram or firewall policy showing environment segmentation.
- CI/CD pipeline showing approval gates for production.
- Change records for production deployments.
- Access review records for production permissions.
- Risk acceptance if production and non-production share a cloud project.

### Practical Position

Shared GCP projects are not automatically an ISO audit failure. However, they are a higher-explanation position than separate projects.

If the app is important, customer-impacting, or handles sensitive data, treat shared dev/prod projects as technical debt and create a migration plan toward project-level segregation.

If the app is low risk and service-level segregation is strong, document the design, controls, and risk acceptance. The audit outcome will depend on whether the implementation genuinely prevents accidental or unauthorised production impact.

## Shared Source Data for Dev and Prod Data Pipelines

Shared source data is a separate risk from shared infrastructure. A design where both dev and prod transformations read from the same raw bucket or raw dataset can be defensible, but only under tight conditions.

The key question is whether development activity can affect production data confidentiality, integrity, or availability.

### Preferred Pattern

Use separate raw landing zones for production and non-production where practical.

**Should have**

- Production raw data stored in a production-controlled bucket and dataset.
- Non-production raw data copied, sampled, masked, synthetic, or otherwise separated.
- Dev transformations reading from non-production raw data by default.
- Explicit approval for any dev access to production-equivalent raw data.
- Data minimisation, masking, or tokenisation for sensitive fields.

**Why this is preferred**

- Cleaner separation of environments.
- Lower chance of accidental sensitive data exposure.
- Easier access review.
- Easier evidence for ISO 27001 environment separation and test information controls.

### Acceptable With Justification: Shared Read-Only Raw Layer

It can be acceptable for dev and prod dbt environments to read from the same raw layer if the raw layer is treated as a controlled production data source and dev access is constrained.

**Should have**

- Read-only dev access to raw data.
- No dev write, delete, truncate, schema modification, or lifecycle management permissions on raw buckets or raw datasets.
- Separate dev and prod dbt service accounts.
- Separate dev and prod target datasets.
- Separate dev and prod jobs, schedules, credentials, and deployment identities.
- Strong controls preventing dev jobs from writing into prod datasets.
- Column-level security, row-level security, authorized views, masking, or curated raw views where sensitive data is present.
- Audit logging for raw data access.
- Access reviews for all identities that can read raw production-equivalent data.
- Documented justification for why shared raw access is required.
- Documented data classification for the raw layer.

**Should not have**

- Developers using broad BigQuery admin, data owner, or storage admin permissions just to support dev work.
- Dev service accounts with write access to raw or production datasets.
- Shared dbt service accounts between dev and prod.
- Shared dbt schemas or target datasets.
- Unmasked customer, employee, financial, health, or confidential data available to all developers by default.
- Production raw data used for exploratory development without approval.
- No evidence of who queried raw data and why.

### When This Is Hard to Defend

Shared raw data access is difficult to defend if any of the following are true:

- Raw data contains personal data, customer confidential data, regulated data, credentials, tokens, or commercially sensitive data.
- Developers have broad access to the raw dataset instead of access through restricted views or policies.
- Dev jobs can materially increase cost, lock resources, exhaust quotas, or affect production pipeline performance.
- Dev can mutate raw data, raw metadata, or production datasets.
- There is no access review or query audit process.
- The design exists for convenience rather than a documented data-platform requirement.

### Recommended Data Platform Position

Treat the raw layer as production if it contains production source data.

Dev can read from that layer only through approved, least-privilege mechanisms. Prefer restricted views, masked views, sampled datasets, synthetic datasets, or non-production replicas for day-to-day development.

The point where dev and prod branch into separate dbt target datasets is useful, but it is not sufficient by itself if both environments have broad access to sensitive raw production data.

## Example Control Levels

| Control | Prototype `main` | `develop` | `qa` | `uat` | Production `main` |
| --- | --- | --- | --- | --- | --- |
| Protected branch | Yes | Yes | Yes | Yes | Yes |
| Direct pushes blocked | Preferred | Yes | Yes | Yes | Yes |
| Force pushes blocked | Yes | Yes | Yes | Yes | Yes |
| Pull request required | Optional or lightweight | Yes | Yes | Yes | Yes |
| Approval required | Optional or self-approval policy | Usually 1 | Usually 1 | 1+ and owner sign-off | 1+ |
| CODEOWNERS required | Sensitive paths only | Sensitive paths only | Sensitive paths only | Yes for sensitive paths | Yes for sensitive paths |
| CI required | Basic | Yes | Yes | Yes | Yes |
| Security checks required | Basic | Recommended | Recommended | Yes if release path | Yes |
| Ticket required | Recommended | Recommended | Recommended | Yes | Yes |
| Deployment gate | No production deploy | No production deploy | QA only | UAT only | Production |

## Merge Strategy

Merge strategy should depend on what is being merged.

Squash merge is useful for keeping feature work readable, but it should not be used as the default promotion mechanism between long-lived branches such as `develop`, `qa`, `uat`, and `main`.

### Recommended Merge Methods

| Source | Target | Recommended method | Rationale |
| --- | --- | --- | --- |
| `feature/*` | `develop` | Squash merge | Produces one clean integration commit per change. |
| `feature/*` | `main` | Squash merge | Works well for trunk-based repositories where `main` is the only long-lived branch. |
| `fix/*` | `develop` or `main` | Squash merge | Keeps small fixes readable and traceable. |
| `hotfix/*` | `main` | Merge commit or squash merge | Either is acceptable if the hotfix is short-lived and traceable. |
| `develop` | `qa` | Merge commit | Preserves ancestry between long-lived branches. |
| `qa` | `uat` | Merge commit | Preserves environment promotion history. |
| `uat` | `main` | Merge commit | Keeps the release path auditable and avoids branch divergence caused by squash commits. |
| `release/*` | `main` | Merge commit | Preserves release stabilization history. |
| `main` | `develop`, `qa`, or `uat` | Merge commit | Keeps long-lived branches synchronized after production changes. |

### Squash Merge

**Best for**

- Short-lived feature branches.
- Small fixes.
- Prototype repositories.
- Trunk-based repositories with only `main` as a long-lived branch.
- Repositories where the PR is the primary audit record and individual feature branch commits are not important.

**Should have**

- Clear PR title because the squash commit message usually becomes the permanent history.
- Linked ticket or change reference.
- Passing CI before merge.
- Review evidence retained in the PR.

**Should not be used for**

- Routine promotion from `develop` to `qa`, `qa` to `uat`, or `uat` to `main`.
- Back-merging `main` into `develop`.
- Release branch synchronization.
- Any workflow where long-lived branches need to remain ancestrally aligned.

### Merge Commit

**Best for**

- Promotion between long-lived branches.
- Environment branch workflows.
- Release branches.
- Back-merging production changes into integration branches.
- Cases where preserving branch ancestry matters.

**Should have**

- Pull request review before merge.
- Passing checks on the target branch.
- Clear merge commit message or PR title.
- Deployment or release evidence where applicable.

**Should not be used for**

- Every small feature branch if it creates noisy history and the team does not need individual commits.
- Unreviewed direct merges.

### Rebase Merge

**Best for**

- Teams that require a strictly linear history.
- Repositories where contributors understand rebase workflows well.
- Low-risk feature branches.

**Should have**

- Clear policy on when rebasing is allowed.
- Re-review after substantial history rewrites.
- No rebasing of shared long-lived branches.

**Should not be used for**

- Long-lived shared branches.
- Branches already used by multiple engineers unless coordinated.
- Compliance-sensitive promotion paths where rewriting context may confuse auditability.

### Why Squash Merge Causes `develop` and `main` Divergence

When a PR from `develop` to `main` is squash merged, Git creates a new commit on `main` with the combined content of `develop`, but that new commit does not share the same commit ancestry as the original commits on `develop`.

As a result, Git does not see `main` and `develop` as synchronized even if the file contents look the same. Future PRs may show repeated changes, confusing diffs, or unnecessary conflicts.

For long-lived branches, prefer merge commits so Git can preserve the relationship between branches.

### Recommended Default Merge Policy

Use this default unless a repository has a documented reason to differ:

- Enable squash merge for short-lived branches into their target branch.
- Enable merge commits for long-lived branch promotion and synchronization.
- Disable rebase merge unless the team explicitly wants linear history and understands the tradeoffs.
- Do not squash merge `develop` into `main` if `develop` remains long-lived.
- After a hotfix to `main`, merge `main` back into `develop`, `qa`, `uat`, or `release/*` branches that need the fix.
- If using GitHub, document which merge button should be used for each branch path because GitHub merge options are repository-wide unless controlled by process or automation.

## Versioning and Release Automation

Protected `main` should remain immutable. Versioning and release automation should not require force pushes to `main`.

Use automation to calculate versions, create release notes, create tags, publish artifacts, and open follow-up pull requests where needed. Do not give CI broad bypass rights to rewrite protected branch history.

### Recommended Versioning Model

Use semantic versioning for production software unless the repository has a documented reason to use another scheme.

**Version format**

- `MAJOR` for breaking changes.
- `MINOR` for backward-compatible feature changes.
- `PATCH` for backward-compatible fixes.

**Recommended PR labels**

- `release:major`
- `release:minor`
- `release:patch`
- `release:exempt`

Only one release-impact label should be allowed per PR.

### Preferred Pattern: Version From Merged PR Metadata

In this model, developers do not manually edit version files in every PR.

**Flow**

- Developer opens a PR into `main`.
- Developer applies exactly one release-impact label.
- CI validates that one valid label exists unless the repository is explicitly exempt.
- PR is reviewed and merged into `main`.
- Release automation runs after merge to `main`.
- Automation calculates the next version from the previous release tag and the PR label.
- Automation creates a signed or protected tag such as `v1.8.3`.
- Automation generates release notes from PR title, labels, commits, and linked tickets.
- Automation publishes artifacts or deployment metadata.

**Should have**

- Required PR label validation before merge.
- Release notes generated from reviewed PR metadata.
- Tags created by a dedicated release automation identity.
- Tag protection or rulesets for `v*` tags.
- Audit trail linking release tag, PR, commit SHA, deployment, and ticket.
- Manual approval gate before production deployment where required.

**Should not have**

- CI force-pushing to `main`.
- CI rewriting commits on `main`.
- Developers manually editing changelogs in every PR unless the project genuinely needs curated release notes.
- Multiple conflicting release labels on one PR.
- Unreviewed release commits directly pushed to `main`.

### Alternative Pattern: Release Pull Request

Use this when repositories require version files, changelogs, manifests, package metadata, or lockstep release branches to be updated in source control.

**Flow**

- Feature and fix PRs merge normally.
- Release automation opens a release PR, for example `release: prepare v1.8.3`.
- The release PR updates version files, changelog, manifests, and release notes.
- The release PR is reviewed and merged into `main`.
- Automation tags the merge commit and publishes the release.

**Best for**

- Libraries and packages where version files are part of the distributed source.
- Mobile apps or desktop apps where version metadata must be committed.
- Repositories that need human-curated changelogs.
- Regulated releases requiring explicit release approval.

**Tradeoff**

- Slightly more process.
- Cleaner audit evidence.
- No protected branch bypass required.

### Manual Version Bumps in Every PR

Manual version bumps in normal feature PRs are usually not the best default.

**Acceptable when**

- The repository is small.
- Releases are infrequent.
- Version files must change with the functional change.
- Conflicts are manageable.

**Problems**

- Frequent merge conflicts.
- Developers guess release impact inconsistently.
- Multiple PRs can race to set the same next version.
- Changelog quality depends on every author doing it correctly.

### CI Permissions

Release automation should use narrowly scoped permissions.

**Should be allowed**

- Read repository contents.
- Read pull request metadata and labels.
- Create release notes.
- Create releases.
- Create protected version tags if explicitly allowed.
- Open release pull requests.
- Publish artifacts to approved registries.

**Should not be allowed**

- Force push to `main`.
- Delete or rewrite release tags.
- Bypass PR review for source changes.
- Push arbitrary commits to protected long-lived branches.
- Use a shared human administrator account.

### Recommended Default Release Policy

Use this default unless a repository has a documented reason to differ:

- Keep `main` protected and immutable.
- Do not allow force pushes to `main`, including for CI.
- Require one release-impact label on each PR to `main`.
- Let automation calculate the next version after merge.
- Use protected `v*` tags as the release version source of truth.
- Use release PRs only where version files or curated changelogs must be committed.
- Require deployment approvals separately from version calculation.

## Signing-Key Onboarding

Production repositories enforce required signed commits on `main` (`required_signatures: true`). This is a one-time setup per contributor.

### Why Required Signed Commits

A Git commit object stores an author name and email — both are user-controlled and trivially spoofable. Without signing, any contributor can produce commits that appear to come from any other person. Required signed commits make commit authorship cryptographically attributable: GitHub will only accept commits whose signature verifies against a key registered to a GitHub account whose email matches the commit author.

This implements ISO 27001 A.5.33 (protection of records), A.8.5 (secure authentication), A.8.24 (use of cryptography), and A.8.32 (change management — non-repudiation of authorship).

### Recommended Setup: SSH Signing

SSH-key signing is the simplest path because most engineers already have an SSH key registered with GitHub. Available in Git 2.34 and later.

1. Use an existing SSH key, or generate a new one:

   ```bash
   ssh-keygen -t ed25519 -C "you@company.com"
   ```

2. Register the public key with GitHub. In GitHub Settings → SSH and GPG keys → New SSH key, choose **Key type: Signing Key**. The same physical key can also be registered as an authentication key, but a signing-key registration must exist for verification to work.

3. Configure local git to sign commits and tags using the SSH key:

   ```bash
   git config --global gpg.format ssh
   git config --global user.signingkey ~/.ssh/id_ed25519.pub
   git config --global commit.gpgsign true
   git config --global tag.gpgsign true
   ```

4. Tell git which keys are trusted for signature verification (used by `git log --show-signature` locally; not required for GitHub-side verification, but useful for local tooling):

   ```bash
   mkdir -p ~/.config/git
   echo "you@company.com $(cat ~/.ssh/id_ed25519.pub)" >> ~/.config/git/allowed_signers
   git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
   ```

5. Verify a test commit:

   ```bash
   cd /tmp && mkdir signing-test && cd signing-test
   git init -q && git commit --allow-empty -m "signing check"
   git log --show-signature
   ```

### Alternative: GPG Signing

GPG remains supported and is preferable in environments that already standardize on GPG (e.g. for package signing). The setup is more involved: generate a GPG key, export the public key, register it with GitHub, configure `user.signingkey` and `commit.gpgsign`. SSH signing is preferred for new setups.

### Web UI and PR-Merge Commits

Commits created through the GitHub web UI (web edits, PR merge button, issue auto-close commits) are signed automatically by GitHub's own internal key. They appear as "Verified" without any contributor setup. This means:

- Merging PRs through the merge button does not require the merger to have a personal signing key.
- Automation that authors commits via GitHub Apps signs with the App's identity.
- Bot accounts must register signing keys if they push commits via Git (rather than the API).

### Onboarding Checklist for New Engineers

- [ ] Generate or identify an existing SSH key.
- [ ] Register it as a Signing Key in GitHub.
- [ ] Configure local git per the steps above.
- [ ] Push a test commit and confirm "Verified" badge appears.
- [ ] Confirm push to a protected branch is accepted.

### Failure Mode

A push of an unsigned commit to a branch with `required_signatures: true` is rejected by GitHub with a clear error message. The contributor either signs the commit (`git commit --amend -S`) or replays the work on top of a signed parent. There is no fallback to "merge anyway" for unsigned commits.

## Recommended Default

Use this default unless a repository has a documented reason to differ:

- `main` as the only long-lived branch.
- Short-lived `feature/*`, `fix/*`, and `hotfix/*` branches.
- Pull requests into `main`.
- Required CI and review for production repositories.
- Required signed commits on production `main` branches.
- Lightweight controls for prototype repositories.
- `develop`, `qa`, `uat`, and `release/*` only when tied to real environments, release processes, or support needs.

## Anti-Patterns

- Creating `develop` in every repository without a clear purpose.
- Protecting `main` while leaving `uat` or `release/*` unprotected even though they can affect production.
- Treating ISO-exempt repositories as unmanaged repositories.
- Allowing direct pushes to long-lived branches for convenience.
- Using branch names as a substitute for deployment approvals.
- Keeping stale release, experiment, or feature branches indefinitely.
- Requiring so many approvals that teams work around the process.
- Applying identical controls to all repositories regardless of risk.
