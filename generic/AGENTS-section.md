## Documentation

This repository follows the documentation standard in
`docs/standards/documentation.md`. Read its routing table before creating any
Markdown file: one question decides where a document goes, and the repository
root is not the default.

### Before every commit

Run both checks from the repository root and fix every finding before you
commit. Never commit around a failure, and never weaken a check to make it pass.

1. **Structure check:**

   ```sh
   CHECK_DOCS_RECORD_DIR=docs/records sh scripts/check-docs.sh
   ```

2. **Link check:** run lychee, natively if it is installed, otherwise in Docker.

   ```sh
   lychee --offline --no-progress --include-fragments --exclude-path docs/records .
   ```

   ```sh
   docker run --rm -v "$PWD:/input:ro" -w /input lycheeverse/lychee:0.24.2 \
     --offline --no-progress --include-fragments --exclude-path docs/records .
   ```

   If neither lychee nor Docker is available, check by hand that every relative
   link and `#anchor` in the Markdown files you changed resolves, and say in
   your summary that the link check did not run.

Then confirm the things no script can see:

- An accepted ADR changed only for a typo, heading or broken link. Anything
  more is a new ADR that supersedes it.
- A new ADR started from `docs/adr/0000-template.md` and has a row in
  `docs/adr/README.md`. A new runbook has a row in `docs/runbooks/README.md`.
- Nothing planned, deferred or in progress went into a document. It went to the
  issue tracker, and a document that needs to mention it links there.
- Every review finding or spec item you are deferring has an issue.
- No review write-up, session summary or scratch note was committed.
