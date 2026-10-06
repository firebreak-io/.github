# Generic documentation standard

A self-contained copy of the documentation standard for repositories in any
organisation. It does not depend on this repository: you copy the files once,
and nothing calls back here.

It is enforced twice: coding agents check the docs before every commit, as
instructed by `AGENTS.md`, and a GitHub Actions workflow checks again on every
push and pull request.

## What is here

| File | Copy it to | Purpose |
|---|---|---|
| [standard.md](standard.md) | `docs/standards/documentation.md` | The routing table and the rules |
| [AGENTS-section.md](AGENTS-section.md) | A section of `AGENTS.md` | The pre-commit checks for agents |
| [check-docs.sh](check-docs.sh) | `scripts/check-docs.sh` | The structure check |
| [workflows/docs.yml](workflows/docs.yml) | `.github/workflows/docs.yml` | Both checks in CI |
| [templates/adr-template.md](templates/adr-template.md) | `docs/adr/0000-template.md` | Starting point for every ADR |
| [templates/adr-index.md](templates/adr-index.md) | `docs/adr/README.md` | The ADR index |
| [templates/runbook-index.md](templates/runbook-index.md) | `docs/runbooks/README.md` | The runbook index |

## Adopting it

From the root of the repository adopting the standard, with this folder at
`$GENERIC`:

```sh
mkdir -p docs/standards docs/adr docs/runbooks scripts .github/workflows
cp "$GENERIC/standard.md"                docs/standards/documentation.md
cp "$GENERIC/check-docs.sh"              scripts/check-docs.sh
cp "$GENERIC/workflows/docs.yml"         .github/workflows/docs.yml
cp "$GENERIC/templates/adr-template.md"  docs/adr/0000-template.md
cp "$GENERIC/templates/adr-index.md"     docs/adr/README.md
cp "$GENERIC/templates/runbook-index.md" docs/runbooks/README.md
```

Then:

1. **Add the agent instructions.** Paste `AGENTS-section.md` into `AGENTS.md`,
   creating the file if there is none. If the repository has its own
   `AGENTS.md` already, add the section, do not replace the file.
2. **Point Claude Code at it.** Claude Code reads `CLAUDE.md`, not `AGENTS.md`.
   If the repository has no `CLAUDE.md`, create one containing the single line
   `@AGENTS.md`. If it has one, add that line to it.
3. **Pick the record directory.** The default is `docs/records`. If specs and
   plans already live elsewhere, change the path in three places: the routing
   table in `docs/standards/documentation.md`, `RECORD_DIR` in
   `.github/workflows/docs.yml`, and both commands in the `AGENTS.md` section.
4. **Run both checks once** with the commands in the `AGENTS.md` section and fix
   what they find before committing the adoption.

Create the two indexes before the first ADR or runbook, not after, which is why
the copy step above does it. Add a row to the right index every time you add an
ADR or a runbook: that row is what the structure check looks for.

## CI requirements

- **A Linux runner with Docker.** Both checks run as `docker run`.
  `ubuntu-latest` and a self-hosted Linux runner qualify. A `container:` job, or
  a macOS or Windows runner, does not, and fails with something like
  `docker: command not found` rather than a documentation finding.
- **`actions/checkout` at the workspace root.** No `path:` input: both checks run
  against the workspace root.
- **No branch or path filter.** The workflow's comments say why. Keep them off
  when you edit the triggers.

To add the checks to a workflow you already run instead, copy the `env` block
and the two check steps from `docs.yml` into an existing Linux job, after its
checkout step.

## What you will hit first

- **Root Markdown that is not on the allowlist.** A `QUICKSTART.md` or a
  `SESSION_SUMMARY.md` at the root is what the standard exists to route: the
  first is a runbook, the second is a point-in-time record.
- **An ADR or runbook with no index row.** The index table is the only
  navigation into those directories, so a file missing from it is invisible.
- **A `Roadmap` or `TODO` heading.** Rule 6 sends what is planned to the
  tracker. Prose about a roadmap is fine; a section named after one is not.

## Keeping copies current

There is no upstream to pull from. A fix made here reaches an adopting
repository only when someone copies the changed file into it again.
