# Firebreak Documentation Standard

How documentation is organised in a Firebreak repository. One question routes a
document to exactly one home, and each home states whether its documents may be
edited.

This document is repository agnostic on purpose. Nothing in it names a
particular repository or language, so it copies without edits.

## The routing table

Answer one question about the document you are holding:

| The reader's question | Home | Editable? |
|---|---|---|
| What is this, and how do I start? | `README.md` | Yes |
| Why is it built this way? | [`docs/adr/`](../adr/README.md) | No. Supersede with a new ADR |
| What does it do? | `docs/` | Yes |
| How do I work on it, and what will bite me? | [`docs/runbooks/`](../runbooks/README.md) | Yes, that is the point |
| How was this designed and built? | `docs/superpowers/{specs,plans}/` | No. A point-in-time record |
| What rules does every Firebreak repo follow? | `docs/standards/` | Yes, but change it upstream first |
| What did this review find? | The pull request or issue | Not a repository document |
| What are we doing next, and where is it up to? | The issue tracker and its board | Living. Never a repository document |

## The rules

1. **No new Markdown at the repository root.** The allowlist is `README.md`,
   `AGENTS.md`, `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md`, `SECURITY.md`,
   `CODE_OF_CONDUCT.md` and `SUPPORT.md`. `LICENSE` carries no extension, so
   `LICENSE.md` is not on the list and the structure check rejects it.
   Everything else routes through the table above.

2. **ADRs are immutable once accepted.** Supersede with a new ADR rather than
   rewriting one. The corollary is the useful part: anything that gets appended
   to over time is a runbook, not an ADR. Fixing a typo, a heading or a broken
   link is not a rewrite.

3. **Runbooks are meant to be edited.** When you lose an afternoon to an
   environment trap or a non-obvious failure mode, append it to the relevant
   runbook so the next person does not. Runbooks are named by topic, not
   numbered: there is no ordering and no history to preserve.

4. **Review findings are not repository documents.** They belong in the pull
   request or issue that raised them. Anything still true once that pull
   request merges has already become an ADR, a runbook entry or a test, so the
   write-up itself is spent.

5. **Process artifacts are a record, not documentation.** A spec describes what
   was intended at one moment. It is not updated as the code moves, and it must
   not be read as a description of current behaviour. When a spec's reasoning
   still matters months later, that reasoning belongs in an ADR.

6. **Standards change upstream.** `docs/standards/` holds copies of rules that
   apply across Firebreak repositories. Fix a typo locally, but change a rule
   in the canonical copy and re-copy it, or the repositories diverge silently.

7. **Forward-looking work is not a repository document.** Every home above
   holds something that already exists, or a decision already taken. What is
   planned, in progress or deferred changes daily, and it belongs in the issue
   tracker, where it moves without a commit. A roadmap committed to a
   repository is accurate on the day it is written and quietly wrong a month
   later, and no review catches that, because nothing in the diff is wrong.

   Two consequences, and they are the whole point of the rule:

   - **A living document describes the present.** Where a document needs to say
     what comes next, link to the tracker instead of listing it. The structure
     check rejects a section heading that names work not yet done. The list it
     holds is `Roadmap`, `Backlog`, `Coming soon`, `Future work`,
     `Planned work`, `Upcoming` and `TODO`, singular or plural. It matches
     heading lines only, so prose may discuss any of them freely, and a failure
     prints the full list, so nobody has to come back here to read it.
   - **Deferring is an action, and it leaves an artifact.** A review finding
     left unfixed, or a spec item left unbuilt, gets an issue before the pull
     request merges. Rule 4 sends findings to the pull request, and a merged
     pull request stops being read, so an issue is the only thing that carries
     a still-open finding past the merge.

## ADR format

Context, then Decision, then Consequences. Files are named `NNNN-kebab-title.md`
with four digits, allocated in order. Every ADR carries a `**Status:**` line and
appears in the ADR index.

## Enforcement

Two checks, run by the `firebreak-io/.github/actions/check-docs` action.
See [adoption](../adoption.md).

| Check | Catches |
|---|---|
| Link check | Relative links that do not resolve, and `#fragment` anchors that name no heading |
| Structure check | Root Markdown not on the allowlist, an ADR or runbook missing from its index, an ADR with no Status line, and a forward-looking heading in a living document |

What is deliberately not checked: CI does not diff against the base branch to
detect edits to an accepted ADR. Typo and link fixes are legitimate under rule
2, so such a check would fail on valid changes routinely, and a check people
learn to override is worse than no check. ADR immutability is a reviewer
responsibility.

## Adopting this standard

See [adoption](../adoption.md).
