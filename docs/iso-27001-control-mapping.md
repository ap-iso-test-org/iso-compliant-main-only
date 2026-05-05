# ISO/IEC 27001:2022 Control Mapping

## Purpose

This document maps ISO/IEC 27001:2022 Annex A controls to the GitHub configuration applied in this organization. It is the auditor's primary cross-reference: each control row points to the GitHub setting that implements it and to the artifact in this repository that documents it.

This document does not claim full ISO 27001 coverage. ISO 27001 has 93 controls across organizational, people, physical, and technological domains. GitHub configuration only addresses the technological controls related to source code, build, change, and access. People controls (training), organizational controls (policy approval), physical controls, and supplier controls live elsewhere in the ISMS and are out of scope for this document.

## Scope

In scope:

- Source code repositories.
- Branch protection and merge controls.
- Identity and access management for the GitHub organization.
- Build and CI/CD pipeline controls in GitHub Actions.
- Secrets and dependency vulnerability management.
- Audit logging.
- Change management traceability for code changes.

Out of scope (covered by other ISMS documents):

- Cloud platform IAM (AWS, GCP, Azure).
- Endpoint security and laptop hardening.
- Physical security.
- Human-resources controls.
- Supplier security assessments.
- Cryptographic key management for production data.

## Control Mapping

The mapping below uses ISO/IEC 27001:2022 Annex A numbering. Where a single GitHub control supports multiple ISO controls, it is listed against each.

### A.5 Organizational Controls

| ISO control | Title | GitHub implementation | Evidence artifact |
| --- | --- | --- | --- |
| A.5.1 | Policies for information security | This repository serves as the documented GitHub-specific security policy set. The full ISMS policy lives outside this repo. | `docs/github-org-policy-baseline.md`, `github-compliance-engineering-guidance.md`. |
| A.5.10 | Acceptable use of information and assets | Org rules prohibit member-created repos, public repo creation by members, and outside collaborator invitations without approval. | `docs/github-org-policy-baseline.md` "Applied in the Test Organization" table. |
| A.5.15 | Access control | Base repository permission set to `none`. Access granted only via teams. Org-owner role is the only role with elevated rights. | Org settings export, team membership export. |
| A.5.16 | Identity management | Each contributor uses a personal GitHub account. Bots use machine accounts or GitHub Apps. No shared logins. | Member list, app list. |
| A.5.17 | Authentication information | Org enforces 2FA for all members (production org; dummy org records this as a Team-plan-required deviation). | Screenshot of org Authentication security setting. |
| A.5.18 | Access rights review | Quarterly access review process documented in `docs/iso-27001-evidence-inventory.md`. | Quarterly access-review record. |
| A.5.24 | Information security incident management planning and preparation | Out of scope here. Incident response plan lives in the ISMS. | ISMS incident response plan. |
| A.5.30 | ICT readiness for business continuity | Repository protection prevents loss of source via force-push or deletion. Tag protection prevents loss of release history. | Branch protection JSON, ruleset JSON. |
| A.5.32 | Intellectual property rights | License files in production repos. Verified-action allowlist for GitHub Actions prevents importing arbitrary third-party code. | Per-repo `LICENSE`, org Actions policy. |
| A.5.33 | Protection of records | Required signed commits make commit authorship cryptographically attributable. Audit log retention is GitHub default (Team plan: 90 days; export quarterly for longer retention). | Branch protection `required_signatures`, quarterly audit-log export. |
| A.5.37 | Documented operating procedures | `scripts/bootstrap-main-only-repo.sh` and `scripts/bootstrap-org-policies.sh` are the documented procedures for repo and org configuration. | Both scripts plus `docs/iso-github-org-replication-checklist.md`. |

### A.6 People Controls

| ISO control | Title | GitHub implementation | Evidence artifact |
| --- | --- | --- | --- |
| A.6.1 | Screening | Out of scope: HR control. GitHub access is granted post-screening. | HR onboarding record. |
| A.6.5 | Responsibilities after termination or change of employment | Offboarding removes the user from the GitHub org and revokes any personal access tokens granted to org resources. | Offboarding checklist + org audit log entry showing member removal. |
| A.6.6 | Confidentiality or non-disclosure agreements | Out of scope for this document. | NDA on file in HR system. |

### A.8 Technological Controls

| ISO control | Title | GitHub implementation | Evidence artifact |
| --- | --- | --- | --- |
| A.8.2 | Privileged access rights | Org-owner role is the only privileged role. Member privilege flags restrict repo creation, deletion, visibility changes, outside collaborator invitations, and team creation. | Org settings export. |
| A.8.3 | Information access restriction | Custom property `iso_classification` segregates ISO-compliant from ISO-exempt repositories. Org rulesets target by classification. | `gh api orgs/ORG/properties/values`, ruleset list. |
| A.8.4 | Access to source code | Branch protection requires PR + review + passing checks before code reaches `main`. CODEOWNERS enforces reviewer for sensitive paths. | Branch protection JSON, `CODEOWNERS` file. |
| A.8.5 | Secure authentication | Org enforces 2FA. Required signed commits enforce authentication of commit author. | Org 2FA setting, branch protection `required_signatures`. |
| A.8.7 | Protection against malware | GitHub Advanced Security secret scanning + push protection blocks credential leakage. Verified-actions allowlist prevents arbitrary third-party action execution. | Org security settings, Actions policy. |
| A.8.8 | Management of technical vulnerabilities | Dependabot alerts and security updates enabled at the org level. Triage and remediation tracked via GitHub Security tab. | `gh api orgs/ORG/dependabot/alerts`, remediation timestamps. |
| A.8.9 | Configuration management | Repository configuration is version-controlled in this repo's bootstrap scripts. Custom properties record each repo's classification, template, and branching strategy. | `scripts/`, `docs/`, custom property values. |
| A.8.15 | Logging | GitHub audit log captures admin actions, permission changes, and authentication events. Exported quarterly for long-term retention. | Quarterly audit-log JSON export. |
| A.8.16 | Monitoring activities | Audit log review is part of the quarterly evidence cycle. Security alerts (Dependabot, secret scanning) reviewed continuously. | Review records, alert dashboards. |
| A.8.20 | Networks security | Out of scope for this document (cloud network controls). | Cloud network policy. |
| A.8.24 | Use of cryptography | Required signed commits use SSH or GPG signing. TLS for all GitHub traffic is provider-enforced. | Branch protection JSON, contributor signing-key registration. |
| A.8.25 | Secure development life cycle | Pull-request-based change flow with required review, required CI, and release-impact label requirement. Documented in engineering guidance. | `github-compliance-engineering-guidance.md`, sample PR walkthrough. |
| A.8.26 | Application security requirements | Required CI checks include security scanning where applicable. Repos handling production data have `repo:production` and `compliance:review-required` labels. | Workflow files, label definitions. |
| A.8.27 | Secure system architecture and engineering principles | Documented branching strategies (`main-only`, `main-develop`) with control levels by branch type. | `github-compliance-engineering-guidance.md`. |
| A.8.28 | Secure coding | Default `GITHUB_TOKEN` permission is read-only. Workflow permissions cannot approve PRs. Verified-Marketplace actions disabled. | `gh api orgs/ORG/actions/permissions/workflow`. |
| A.8.29 | Security testing in development and acceptance | CI runs on every PR. Required release-impact label prompts the author to consider blast radius. | Workflow files, branch protection required-status-checks. |
| A.8.30 | Outsourced development | Outside collaborators must be approved by an org owner. Apps and integrations require org-owner approval. | Org policy, third-party-app approval list. |
| A.8.31 | Separation of development, test, and production environments | Branching strategy guidance details environment branches. Environment segregation in cloud is out of scope here. | `github-compliance-engineering-guidance.md`. |
| A.8.32 | Change management | Every change to `main` flows through a PR with linked ticket, release-impact label, review, CI, and merge-button merge. Force pushes and direct pushes blocked. | Sample PR walkthrough, branch protection JSON. |
| A.8.33 | Test information | Branching guidance prohibits production secrets and customer data on feature/experiment branches. | `github-compliance-engineering-guidance.md` "Should not have" sections. |

### A.7 Physical Controls

Not applicable to GitHub configuration. Out of scope for this document.

## Coverage Status

The status column shows whether the control is currently active in `ap-iso-test-org`. "Production-only" means the control is documented but cannot be applied in the dummy org due to plan or single-user constraints; the production org will activate it on replication.

| ISO control | Status in dummy org | Production org expectation |
| --- | --- | --- |
| A.5.15 base permission `none` | Active | Active |
| A.5.17 2FA enforcement | Production-only (Team plan + multiple members) | Active |
| A.5.18 access reviews | Documented; no quarterly cycle yet (single user) | Active quarterly |
| A.5.33 required signed commits | Active on `main` of template + example | Active on all production repos |
| A.5.37 documented operating procedures | Active | Active |
| A.8.2 privileged access restrictions | Active | Active |
| A.8.3 classification via custom properties | Active | Active |
| A.8.4 PR + review + CI on `main` | PR + CI active; review count = 0 (single user) | PR + 1 review + CI |
| A.8.5 signed commits | Active on `main` of template + example | Active on all production repos |
| A.8.7 secret scanning + push protection | Production-only (requires Team plan or public repos) | Active |
| A.8.8 Dependabot alerts and updates | Production-only at org default level | Active |
| A.8.15 audit log retention | Default GitHub retention; no quarterly export yet | Quarterly export |
| A.8.24 commit cryptography | Active | Active |
| A.8.28 read-only `GITHUB_TOKEN` | Active | Active |
| A.8.32 PR-based change flow | Active | Active |
| Org rulesets | Production-only (Team plan) | Active |

See `docs/dummy-vs-production-deltas.md` for the full deviation list and the exact API call to flip each on.

## Maintenance

This document should be reviewed:

- Annually as part of the ISMS review cycle.
- Whenever GitHub introduces or renames an Annex A-relevant feature.
- Whenever ISO/IEC 27001 is revised.

Reviewers should confirm that every "Active" row in the coverage table still reflects the actual GitHub configuration, by re-running the verification commands listed in `docs/iso-github-org-replication-checklist.md`.
