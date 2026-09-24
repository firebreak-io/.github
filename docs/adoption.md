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

The action does not check out your repository. It runs against the working
directory your job already prepared, so `actions/checkout` has to come first.
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

```bash
docker run --rm -v "$PWD:/input" -w /input \
  lycheeverse/lychee:0.24.2 --offline --no-progress --include-fragments \
  --exclude-path docs/superpowers .
```

```bash
curl -fsSL https://raw.githubusercontent.com/firebreak-io/.github/v1/actions/check-docs/check-docs.sh \
  > /tmp/check-docs.sh && \
docker run --rm -v "$PWD:/input" -v /tmp/check-docs.sh:/check-docs.sh -w /input \
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

## AGENTS.md

`AGENTS.md` cannot be inherited the way `CONTRIBUTING.md` is, so each
repository writes its own. Start it as a pointer to `CONTRIBUTING.md` plus a
"Things that will catch you out" section reading "Nothing recorded yet", and
add to that section the first time something costs you an afternoon. An empty
section is honest. A section copied from another repository is not.
