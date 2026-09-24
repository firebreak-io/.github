# Adopting the documentation standard

The [standard](standards/documentation.md) says where documents go. This says
how to make a repository check that it obeys it.

Nothing here names a particular repository. Everything is copy-paste.

## If your repository already runs a workflow

Add two steps to a job you already have:

```yaml
      - uses: actions/checkout@v4
      - uses: firebreak-io/.github/actions/check-docs@v1
```

The action does not check out your repository. It runs against the job's
workspace root, the directory a plain `actions/checkout@v4` populates, so that
step has to come first. It does not support a checkout placed with
`actions/checkout`'s `path:` input, and a job-level
`defaults.run.working-directory` does not reach a composite action's own
steps either: if your checkout is not at the workspace root, this action will
not find it, and the assert step below says so rather than blaming a step you
already have.

Both checks run as `docker run`, so the job needs a Linux runner with a
working Docker daemon: `ubuntu-latest` and a self-hosted Linux runner both
qualify. A `container:` job, or a `macos-latest` or `windows-latest` runner,
does not give you that, and the job fails with something like `docker:
command not found` rather than a documentation finding.

If it is missing, the action fails with a message saying so rather than
passing silently.

## If your repository runs no workflows yet

Create `.github/workflows/docs.yml`:

```yaml
name: Docs

# No branch filter on pull_request: `branches` filters the BASE branch, so a
# filter of [main] silently skips every stacked pull request. No path filter:
# renaming a non-Markdown file rots links without touching any .md.
on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: firebreak-io/.github/actions/check-docs@v1
```

## If your records live somewhere other than docs/superpowers

```yaml
      - uses: firebreak-io/.github/actions/check-docs@v1
        with:
          record-dir: docs/design
```

## Running the checks locally

Two commands, from the root of your repository. Neither adds a file to it.
Both take the record directory the same way the action does: set
`RECORD_DIR` to whatever you gave the action's `record-dir` input, or to its
default, `docs/superpowers`, if you did not set one.

```bash
RECORD_DIR=docs/superpowers
docker run --rm -v "$PWD:/input" -w /input \
  lycheeverse/lychee:0.24.2 --offline --no-progress --include-fragments \
  --exclude-path "$RECORD_DIR" .
```

```bash
RECORD_DIR=docs/superpowers
curl -fsSL https://raw.githubusercontent.com/firebreak-io/.github/v1/actions/check-docs/check-docs.sh \
  > /tmp/check-docs.sh && \
docker run --rm -v "$PWD:/input" -v /tmp/check-docs.sh:/check-docs.sh:ro -w /input \
  -e CHECK_DOCS_RECORD_DIR="$RECORD_DIR" \
  alpine:3.22 sh /check-docs.sh
```

The checker refuses to run anywhere without a `.git` entry, so running it from
a subdirectory tells you so instead of reporting a clean result it never
earned.

## What you will hit first

- **Root Markdown that is not on the allowlist.** The allowlist is
  `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `SECURITY.md`,
  `CODE_OF_CONDUCT.md` and `SUPPORT.md`. A `QUICKSTART.md` or a
  `SESSION_SUMMARY.md` at the root is what the standard exists to route: the
  first is a runbook, the second is a point-in-time record.
- **An ADR or runbook with no index row.** The index table is the only
  navigation into those directories, so a file missing from it is invisible.
- **A `Roadmap` or `TODO` heading.** Rule 7 sends what is planned to the
  tracker. Prose about a roadmap is fine; a section named after one is not.

## Starting your ADR and runbook indexes

The structure check requires an index for any `docs/adr/` or
`docs/runbooks/` directory that holds a document, so create the index before
your first document, not after. Your first ADR will otherwise fail with two
findings at once: no `**Status:**` line, because you had no template to
start from, and a missing index, because nothing created one.

Start `docs/adr/README.md` with:

```markdown
# Architecture decision records

## Index

| ADR | Title | Status |
|---|---|---|
```

Start `docs/runbooks/README.md` with:

```markdown
# Runbooks

## Index

| Runbook | Covers |
|---|---|
```

Save this as `docs/adr/0000-template.md`, and start every new ADR by copying
it to `NNNN-kebab-title.md`, the next four-digit number in order:

```markdown
# ADR-NNNN: Title

**Status:** Proposed

## Context

The forces at play. What is true, what is constrained, and what made this a
decision rather than an obvious choice. No solution here.

## Decision

What was chosen, stated plainly in the present tense.

## Consequences

What follows, good and bad. Include what this forecloses, and what someone
might reasonably try to "fix" later without knowing why it is this way.
```

Add a row to the index table linking to each new ADR as you create it: that
row is what the structure check looks for.

## AGENTS.md

`AGENTS.md` cannot be inherited the way `CONTRIBUTING.md` is, so each
repository writes its own. Start it as a pointer to `CONTRIBUTING.md` plus a
"Things that will catch you out" section reading "Nothing recorded yet", and
add to that section the first time something costs you an afternoon. An empty
section is honest. A section copied from another repository is not.
