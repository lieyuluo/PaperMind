# ADR 0001: Repository Structure

## Status

Accepted

## Context

The project needs a predictable structure for source code, tests, documentation, and automation.

## Decision

Use the following top-level directories:

- `src/` for application source code.
- `tests/` for automated tests.
- `docs/` for documentation and architecture decisions.
- `scripts/` for repeatable local automation.

## Consequences

The repository can grow without mixing application code, documentation, generated artifacts, and local workspace files.
