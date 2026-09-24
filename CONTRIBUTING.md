# Contributing to Firebreak projects

This is the organization default, used by any repository that does not have
its own `CONTRIBUTING.md`. A repository with specific rules should add one.

## Where a document goes

Firebreak repositories follow the
[documentation standard](https://github.com/firebreak-io/.github/blob/main/docs/standards/documentation.md).
One question routes any document to one home:

| The reader's question | Home |
|---|---|
| Why is it built this way? | `docs/adr/`, immutable once accepted |
| What does it do? | `docs/` |
| How do I work on it, and what will bite me? | `docs/runbooks/` |
| What are we doing next, and where is it up to? | The issue tracker |
| What did this review find? | The pull request or issue |

Do not add a new Markdown file to the repository root. The allowlist is
`README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `SECURITY.md`,
`CODE_OF_CONDUCT.md` and `SUPPORT.md`.

The rules people get wrong:

- **ADRs are immutable once accepted.** Supersede with a new ADR rather than
  rewriting one. Anything appended to over time is a runbook, not an ADR.
- **Runbooks are meant to be edited.** When something costs you an afternoon,
  append it.
- **Review findings stay in the pull request.** Anything still true after
  merge has already become an ADR, a runbook entry or a test.
- **Forward-looking work goes to the tracker,** not into a document that is
  accurate the day it is written and quietly wrong a month later.

## Checking your work

Repositories that have adopted the checks run them in CI. To run them
yourself, see [adoption](https://github.com/firebreak-io/.github/blob/main/docs/adoption.md).

## House style

No em dashes.
