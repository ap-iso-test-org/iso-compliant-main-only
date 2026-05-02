# ISO GitHub Organization Replication Checklist

This checklist documents the ISO-oriented GitHub organization setup tested in `ap-iso-test-org` and the additional controls to apply in a real GitHub Team organization.

## 1. Organization Prerequisites

- [ ] Confirm you are an organization owner.
- [ ] Confirm `gh` is installed.
- [ ] Authenticate with required scopes:

  ```bash
  gh auth login
  gh auth refresh -h github.com -s admin:org -s repo -s workflow
  gh auth status
  ```

- [ ] Confirm the target organization:

  ```bash
  gh org list
  ```

- [ ] Replace `ORG` in commands below with the real organization name.

## 2. Create Repository Classification Properties

Use organization custom properties as the source of truth for repository classification.

Required properties:

| Property | Type | Values | Purpose |
| --- | --- | --- | --- |
| `iso_classification` | Single select | `iso-compliant`, `iso-exempt` | Official ISO scope classification. |
| `repo_template` | String | Example: `iso-compliant-main-only` | Template used to initialize the repository. |
| `branching_strategy` | Single select | `main-only`, `main-develop`, `prototype` | Approved branching strategy. |

These are created automatically by:

```bash
scripts/bootstrap-main-only-repo.sh ORG/REPO
```

Verification:

```bash
gh api orgs/ORG/properties/schema --jq '.'
gh api repos/ORG/REPO/properties/values --jq '.'
```

## 3. Apply Organization Policy Baseline

Run:

```bash
scripts/bootstrap-org-policies.sh ORG
```

This configures:

- Base repository permission: `none`
- Member repository creation: disabled
- Member public repository creation: disabled
- Member private repository creation: disabled
- Private repository forking: disabled
- Organization projects: disabled
- Repository projects: disabled
- Pages creation: disabled
- GitHub Actions: selected actions only
- GitHub-owned Actions: allowed
- Verified Marketplace Actions: disabled
- Default `GITHUB_TOKEN`: read-only
- Actions cannot approve pull requests

Verification:

```bash
gh api orgs/ORG --jq '{
  default_repository_permission,
  two_factor_requirement_enabled,
  members_allowed_repository_creation_type,
  members_can_create_repositories,
  members_can_create_public_repositories,
  members_can_create_private_repositories,
  members_can_fork_private_repositories,
  members_can_delete_repositories,
  members_can_change_repo_visibility,
  members_can_invite_outside_collaborators,
  members_can_create_teams,
  has_organization_projects,
  has_repository_projects,
  members_can_create_pages,
  default_repository_branch
}'

gh api orgs/ORG/actions/permissions --jq '.'
gh api orgs/ORG/actions/permissions/selected-actions --jq '.'
gh api orgs/ORG/actions/permissions/workflow --jq '.'
```

## 4. Manual Organization Settings to Confirm

Some settings may not apply consistently through the API depending on plan and organization type. Confirm these in GitHub UI:

- [ ] Require 2FA for all members.
- [ ] Restrict repository deletion to owners/admins.
- [ ] Restrict repository visibility changes to owners/admins.
- [ ] Restrict outside collaborator invitations.
- [ ] Restrict team creation.
- [ ] Confirm default branch name is `main`.
- [ ] Confirm base permissions are `No permission`.
- [ ] Confirm repository creation is restricted to owners or approved platform admins.
- [ ] Confirm private/internal repository forking is disabled by default.
- [ ] Confirm repository transfer is restricted.
- [ ] Configure organization default labels from `docs/github-org-repository-defaults.md`.
- [ ] Confirm default merge settings if available in the UI:
  - squash merge enabled
  - merge commit enabled
  - rebase merge disabled
  - auto-delete head branches enabled

Suggested UI path:

```text
Organization -> Settings -> Member privileges
Organization -> Settings -> Policies
Organization -> Settings -> Actions -> General
Organization -> Settings -> Security
Organization -> Settings -> Repository -> Custom properties
Organization -> Settings -> Repository -> Repository defaults
```

## 5. Create or Publish Approved Templates

Template created in the test org:

```text
iso-compliant-main-only
```

Template purpose:

- Governance-only template.
- `main` is the only long-lived branch.
- Short-lived feature/fix/hotfix branches.
- PRs into `main`.
- Release-impact labels required.
- Custom properties classify repo as ISO-compliant.

Template includes:

- `README.md`
- `CODEOWNERS`
- `.github/pull_request_template.md`
- `.github/ISSUE_TEMPLATE/production_change.yml`
- `.github/workflows/validate-release-label.yml`
- `.github/examples/main-branch-protection-strict.json`
- `.github/examples/org-ruleset-iso-compliant-main.json`
- `docs/github-labels.md`
- `docs/github-org-repository-defaults.md`
- `docs/github-org-policy-baseline.md`
- `github-compliance-engineering-guidance.md`
- `scripts/bootstrap-main-only-repo.sh`
- `scripts/bootstrap-org-policies.sh`

For your real org:

- [ ] Create `ORG/iso-compliant-main-only` as a template repository.
- [ ] Mark it as a GitHub template.
- [ ] Keep it governance-only unless a language-specific template is required.
- [ ] Create separate templates later for:
  - `iso-compliant-main-develop`
  - `iso-exempt-prototype`

## 6. Create a Repository From the Template

Example:

```bash
gh repo create ORG/example-service \
  --private \
  --template ORG/iso-compliant-main-only \
  --description "Example ISO-compliant main-only service"
```

Important: GitHub template repositories copy files, but they do not reliably copy labels, branch protection, rulesets, merge settings, Actions settings, or custom property values.

Always run the bootstrap script after creating a repo:

```bash
git clone https://github.com/ORG/example-service.git
cd example-service
scripts/bootstrap-main-only-repo.sh ORG/example-service
```

Or run the script from the template checkout:

```bash
scripts/bootstrap-main-only-repo.sh ORG/example-service
```

## 7. Repository Bootstrap: Main-Only ISO-Compliant Repo

The bootstrap script configures:

- Repository settings:
  - Issues enabled.
  - Wiki disabled.
  - Projects disabled.
  - Squash merge enabled.
  - Merge commits enabled.
  - Rebase merge disabled.
  - Delete branch on merge enabled.

- Repository classification:
  - `iso_classification=iso-compliant`
  - `repo_template=iso-compliant-main-only`
  - `branching_strategy=main-only`

- Topic mirror:
  - `iso-compliant`
  - `production`
  - `main-only`
  - `github-template`

- GitHub Actions:
  - Selected actions only.
  - GitHub-owned actions allowed.
  - Verified Marketplace actions disabled.
  - Default `GITHUB_TOKEN` read-only.
  - Actions cannot approve PRs.

- Labels:
  - `release:major`
  - `release:minor`
  - `release:patch`
  - `release:exempt`
  - `risk:low`
  - `risk:medium`
  - `risk:high`
  - `risk:prod-impact`
  - `type:feature`
  - `type:fix`
  - `type:hotfix`
  - `type:docs`
  - `type:infra`
  - `type:security`
  - `type:dependency`
  - `repo:production`
  - `compliance:review-required`

- Code security where available:
  - Vulnerability alerts.
  - Dependabot security updates.
  - Secret scanning.
  - Secret scanning push protection.

- Branch protection:
  - PR required.
  - 1 approval required.
  - Stale reviews dismissed.
  - Last-push approval required.
  - Required release-label status check.
  - Conversation resolution required.
  - Force pushes disabled.
  - Branch deletion disabled.
  - Admin enforcement enabled.

Verification:

```bash
gh api repos/ORG/REPO/properties/values --jq '.'
gh api repos/ORG/REPO/topics --jq '.names'
gh label list --repo ORG/REPO --limit 100
gh api repos/ORG/REPO/branches/main/protection --jq '.'
gh api repos/ORG/REPO/actions/permissions --jq '.'
gh api repos/ORG/REPO/actions/permissions/workflow --jq '.'
gh api repos/ORG/REPO --jq '{security_and_analysis}'
```

## 8. GitHub Team Plan: Add Organization Rulesets

The Free test org could not enable org rulesets. GitHub returned:

```text
Upgrade to GitHub Team to enable this feature.
```

In the real company org with GitHub Team, apply the org ruleset:

```bash
gh api --method POST orgs/ORG/rulesets \
  --input .github/examples/org-ruleset-iso-compliant-main.json
```

The ruleset targets:

- `iso_classification=iso-compliant`
- `branching_strategy=main-only`
- branch `main`

It enforces:

- Pull requests.
- 1 approval.
- Stale review dismissal.
- Last-push approval.
- Required conversation resolution.
- Required release-label status check.
- No force pushes.
- No branch deletion.
- Allowed merge methods: merge and squash.

Verification:

```bash
gh api orgs/ORG/rulesets --jq '.'
gh ruleset list --org ORG
gh ruleset check main --repo ORG/REPO
```

## 9. GitHub Team Plan: Recommended Additional Rulesets

Create additional org rulesets for:

- [ ] `iso-compliant-main-develop`: protect `main` and `develop`.
- [ ] `iso-compliant-release`: protect `release/*`.
- [ ] `iso-compliant-tags`: protect `v*` release tags.
- [ ] `iso-exempt-prototype`: lightweight protection for prototype repos.

Recommended tag ruleset for `v*`:

- Block deletion.
- Block force update.
- Restrict tag creation to release automation or maintainers.
- Require tag naming pattern `v*`.

Recommended prototype ruleset:

- Protect `main`.
- Block force pushes.
- Block branch deletion.
- Require secret scanning and push protection.
- PR review optional or lightweight.

## 10. Release Governance

For main-only ISO-compliant repositories:

- [ ] Require exactly one release-impact label on PRs to `main`.
- [ ] Use labels:
  - `release:major`
  - `release:minor`
  - `release:patch`
  - `release:exempt`
- [ ] Generate releases from merged PR metadata.
- [ ] Use protected `v*` tags as release version source of truth.
- [ ] Do not allow CI to force-push to `main`.
- [ ] If committed version files are required, use a reviewed release PR.

Future automation to add:

- [ ] Semver calculation from PR labels.
- [ ] Release notes generation.
- [ ] Protected tag creation.
- [ ] Artifact publishing.
- [ ] Deployment approval gates.

## 11. CODEOWNERS

Before enforcing CODEOWNERS review:

- [ ] Replace placeholder owners in `CODEOWNERS`.
- [ ] Create real teams:
  - `security-team`
  - `platform-team`
  - `data-platform-team`
- [ ] Grant teams appropriate repository access.
- [ ] Enable CODEOWNERS review in branch protection or rulesets.

Sensitive paths should require owners:

- `.github/`
- `infra/`
- `terraform/`
- `deployment/`
- `secrets/`
- `dbt/`
- `pipelines/`
- authentication and authorization code
- production deployment code

## 12. Evidence to Keep for Audit

Keep screenshots or exports for:

- Organization member privilege settings.
- Actions policy settings.
- Custom property schema.
- Custom property values for repositories.
- Rulesets.
- Branch protection.
- Repository labels.
- CODEOWNERS.
- PR template.
- Required check results.
- Example PR showing:
  - linked ticket
  - release label
  - review
  - passing checks
  - merge through PR
- Example release tag and release notes.

## 13. Current Test Org Limitations

Observed in `ap-iso-test-org`:

- 2FA API call did not enable `two_factor_requirement_enabled`.
- Some member privilege flags stayed enabled in the API:
  - `members_can_delete_repositories`
  - `members_can_change_repo_visibility`
  - `members_can_invite_outside_collaborators`
  - `members_can_create_teams`
- Org rulesets require GitHub Team or higher.
- Branch protection on private repositories was unavailable on the Free test org until repositories were made public.

These should be resolved or configurable in the real GitHub Team company organization.

## 14. Recommended Rollout Order

1. Configure org custom properties.
2. Apply org policy baseline.
3. Create approved templates.
4. Create org rulesets targeting custom properties.
5. Create one pilot repo from `iso-compliant-main-only`.
6. Bootstrap the pilot repo.
7. Run a test PR through the full control path.
8. Create the `iso-exempt-prototype` template.
9. Create the `iso-compliant-main-develop` template.
10. Roll out to new repos.
11. Inventory existing repos and classify them.
12. Migrate existing repos into the right ruleset/template baseline.
