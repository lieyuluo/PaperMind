# Enterprise Project

This repository is the starting point for an enterprise-grade application.

## Repository Layout

```text
src/                 Application source code
tests/               Automated tests
docs/                Project documentation and ADRs
scripts/             Local automation scripts
.github/             Pull request templates and CI workflows
```

## Development

1. Clone the repository.
2. Copy `.env.example` to `.env`.
3. Install the project dependencies once a runtime stack is selected.
4. Create a feature branch from `main`.
5. Open a pull request for review before merging.

## Branching

- `main`: production-ready code.
- `feature/*`: new features.
- `fix/*`: bug fixes.
- `hotfix/*`: urgent production fixes.

## Quality Gates

Before code is merged:

- Code review is required.
- CI must pass.
- Tests should cover meaningful behavior.
- Secrets must not be committed.
