# Recommended GitHub Labels

These labels support release automation, change traceability, and audit-friendly pull request review.

## Release Impact

Exactly one of these labels should be applied to every pull request targeting `main`.

| Label | Meaning |
| --- | --- |
| `release:major` | Breaking change or incompatible release. |
| `release:minor` | Backward-compatible feature or material enhancement. |
| `release:patch` | Backward-compatible bug fix, small improvement, or maintenance change. |
| `release:exempt` | No release version impact, such as documentation-only changes. |

## Change Type

| Label | Meaning |
| --- | --- |
| `type:feature` | New functionality. |
| `type:fix` | Defect fix. |
| `type:hotfix` | Urgent production fix. |
| `type:docs` | Documentation-only change. |
| `type:infra` | Infrastructure, deployment, or CI/CD change. |
| `type:security` | Security-relevant change. |
| `type:dependency` | Dependency update. |

## Risk

| Label | Meaning |
| --- | --- |
| `risk:low` | Low operational, security, or data impact. |
| `risk:medium` | Material impact requiring standard review. |
| `risk:high` | High-impact change requiring owner or security review. |
| `risk:prod-impact` | Production behavior, availability, data, or deployment impact. |

## Repository Classification

| Label | Meaning |
| --- | --- |
| `repo:prototype` | Prototype, experiment, or ISO-exempt repository. |
| `repo:production` | Production-grade repository. |
| `repo:critical` | Critical or customer-impacting production repository. |

