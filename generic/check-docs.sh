#!/bin/sh
# Structure checks for the documentation standard (docs/standards/documentation.md).
#
# Portable by design: POSIX shell, no git, no language runtime, so this file
# copies unchanged into a repository of any language.
#
# It deliberately does not shell out to git. The check runs inside a container
# with only the repository directory mounted, and a git worktree's .git is a
# file pointing somewhere outside that mount rather than a directory, which
# the -e check further down accounts for.
#
# Checks:
#   1. Every .md at the repository root is on the allowlist.
#   2. Every ADR is named NNNN-title.md, carries a status and is linked from
#      the ADR index; every runbook is linked from the runbook index; neither
#      directory keeps Markdown in a subdirectory.
#   3. No living document carries a forward-looking section heading, ATX or
#      Setext.

set -eu

# The root allowlist exactly as the standard states it, minus LICENSE, which
# carries no extension and so never reaches the *.md loop below. LICENSE.md is
# deliberately absent rather than tolerated: the standard names one spelling,
# and a spelling nothing enforces drifts repository by repository. The three
# community health files are present because GitHub creates them at the root
# with fixed meanings and surfaces them in its own UI, so rejecting them would
# make the check wrong rather than strict.
ROOT_ALLOWLIST="README.md AGENTS.md CLAUDE.md CONTRIBUTING.md CHANGELOG.md SECURITY.md CODE_OF_CONDUCT.md SUPPORT.md"
ADR_DIR="docs/adr"
ADR_INDEX="$ADR_DIR/README.md"

# Headings that mean a document is being used as a tracker. Matched against
# heading TEXT only, never prose: a document may discuss a roadmap, but a
# document that HAS a Roadmap section has taken on work the tracker owns.
#
# FORWARD_TERMS is what a failure prints, so the person who trips this check
# does not have to read a regex or go looking for the list in a document.
#
# Two things the pattern has to get right:
#
#   Word boundaries. Without them "Todoist integration" fails as a TODO.
#   The boundary is expressed as "not alphanumeric" rather than \b, which
#   POSIX ERE does not define and busybox grep is not guaranteed to support.
#
#   Plurals. A bare word boundary lets "TODOs" and "Backlogs" through, which
#   are the natural spellings, so a single trailing s is allowed inside the
#   boundary. "Todoist" still passes, because "ist" is not "s".
#
# This pattern is applied to the heading TEXT that HEADINGS_AWK below emits,
# not to a raw line, so it no longer carries an ATX anchor or an indentation
# allowance: both of those moved into the awk, which has already done the
# work of deciding what is and is not a heading.
#
# The matching itself happens inside HEADINGS_AWK, against the heading text
# alone, never against the "FILENAME:LINE:text" line the awk prints. A shell
# pipeline that grepped the printed line matched the boundary
# "[^[:alnum:]]" against the path and line number too, since "/" and "-" both
# satisfy it: a document at docs/todo-app-integration/usage.md, or an ADR
# named docs/adr/0006-no-roadmap-sections.md, failed on its own path, on any
# heading at all. FORWARD_HEADINGS is already entirely lowercase, so the awk
# tests "tolower(text) ~ pat" rather than needing its own -i flag.
FORWARD_TERMS='Roadmap, Backlog, Coming soon, Future work, Planned work, Upcoming, TODO'
FORWARD_HEADINGS='(^|[^[:alnum:]])(roadmap|backlog|coming soon|future work|planned work|upcoming|todo)s?([^[:alnum:]]|$)'

# Extracts heading lines from a Markdown file that match the forward-looking
# word list: ATX ("#+ text") and Setext (a text line underlined with "===" or
# "---"), skipping YAML front matter and fenced code blocks, and printing
# "FILENAME:LINE:text" for each hit. Only a matching heading is printed, not
# every heading: the caller passes the word pattern in as "pat" and the awk
# tests it itself, against the heading text alone, so nothing downstream ever
# greps a "FILENAME:LINE:text" line as a whole (see FORWARD_HEADINGS above).
#
# GitHub renders a Setext heading identically to an ATX one, so a document
# that used "Roadmap\n=======" instead of "## Roadmap" passed check 3 clean:
# a plain grep for "#+" line prefixes never saw it, because there
# is no "#" in a Setext heading at all. Recognising both requires seeing a
# heading as two lines together (the text, then its underline), which a
# single grep pattern cannot express, hence an awk pass instead.
#
# This awk is a shell variable, not a shell function, because a shell
# function cannot cross `find -exec`, and the fence handling below is the
# same tracked-marker approach as strip_fences above: a single boolean
# flipped by either ``` or ~~~ lets a ~~~ block nested inside a ```markdown
# example close the outer fence early, which is the same
# false accept as in strip_fences, arriving through headings instead of index rows.
#
# `find -exec ... {} +` hands awk every matched file in one process, so state
# left over from one file would blind the checker to the next. FNR == 1, not
# NR == 1, resets the fence and front-matter state (and any pending heading
# text) at the start of each file, and is also where front matter is
# detected: NR == 1 would only ever see the first file of a batch open with
# "---".
#
# The first rule strips a trailing carriage return from every line before
# anything else looks at $0. Without it, a CRLF file's front-matter
# delimiter never matched "---" (it was "---\r"), and a CRLF Setext underline
# never matched /^(=+|-+)[ \t]*$/ (it was "=======\r"), so a Setext heading in
# a CRLF file passed check 3 cleanly while the same heading in an LF file
# failed: the same gap, reopened by line endings alone.
HEADINGS_AWK='
    function fence_run(s, ch,   n) {
        n = 0
        while (substr(s, n + 1, 1) == ch) n++
        return n
    }
    { sub(/\r$/, "", $0) }
    FNR == 1 {
        infence = 0; infront = 0; prev = ""; fchar = ""; flen = 0
        if ($0 == "---") { infront = 1; next }
    }
    infront && $0 == "---" { infront = 0; next }
    infront { next }
    { match($0, /^ */); indent = RLENGTH; rest = substr($0, indent + 1) }
    indent < 4 {
        btick = fence_run(rest, "`")
        tilde = fence_run(rest, "~")
        if (!infence) {
            if (btick >= 3) { infence = 1; fchar = "`"; flen = btick; prev = ""; next }
            if (tilde >= 3) { infence = 1; fchar = "~"; flen = tilde; prev = ""; next }
        } else {
            run = (fchar == "`") ? btick : tilde
            if (run >= flen && substr(rest, run + 1) ~ /^[ \t]*$/) {
                infence = 0; prev = ""; next
            }
        }
    }
    infence { prev = ""; next }
    # Four spaces of indent after a blank line is an indented code block, not
    # heading text: a "---" under it is a thematic break.
    indent >= 4 && prev == "" { next }
    indent < 4 && rest ~ /^(=+|-+)[ \t]*$/ && prev != "" {
        if (tolower(prev) ~ pat) { print FILENAME ":" prevline ":" prev }
        prev = ""; next
    }
    indent < 4 && rest ~ /^#+[ \t]/ {
        if (tolower(rest) ~ pat) { print FILENAME ":" FNR ":" rest }
        prev = ""; next
    }
    { prev = rest; prevline = FNR }
'

# Records, not living documents, and exempt from check 3. A plan is supposed to
# describe work that has not happened yet; that is what makes it a plan.
#
# Overridable so any caller can set it once rather than this being hardcoded.
# Not every repository keeps point-in-time records in the same place.
#
# A trailing slash (or several) is stripped before the "./" prefix is added.
# Every comparison below that builds a path from RECORD_DIR (the find
# exclusion here, the "$RECORD_DIR is exempt" message) compares a directory
# name, and "docs/records/" is not the same string as "docs/records": left
# untouched, a caller-supplied value ending in "/" silently stops matching
# anything, and the exemption it names stops applying.
_record_dir_raw="${CHECK_DOCS_RECORD_DIR:-docs/records}"
while [ "${_record_dir_raw%/}" != "$_record_dir_raw" ]; do
    _record_dir_raw=${_record_dir_raw%/}
done
RECORD_DIR="./$_record_dir_raw"

failed=0

note() {
    echo "check-docs: $*" >&2
}

# Every check below is relative to the current directory, so running this
# anywhere but a repository root checks nothing, or checks the wrong
# things. README.md is not the marker: the standard requires an index
# file by that name in docs/adr and docs/runbooks, so a README says very
# little about where you are. A .git entry says exactly where you are,
# and -e accepts both a directory and the file a worktree uses.
#
# Exit 2 rather than 1 to separate "you ran this wrong" from "your
# documentation is wrong".
if [ ! -e .git ]; then
    note "no .git here, so this is not a repository root."
    note "  Run this from the root of the repository you want to check."
    exit 2
fi

# 1. No new Markdown at the repository root.
#
# This reads the filesystem, not the git index, so an untracked scratch note at
# the root fails too. That is deliberate: a file that trips this check today is
# a file that gets committed by accident tomorrow.
# Hidden names too: "*.md" never expands to ".scratch.md" or ".md".
for candidate in *.md .*.md .md; do
    [ -e "$candidate" ] || continue
    case " $ROOT_ALLOWLIST " in
        *" $candidate "*)
            ;;
        *)
            note "$candidate is not allowed at the repository root."
            note "  Route it with the table in docs/standards/documentation.md. If it is a scratch"
            note "  note, keep it outside the repository entirely."
            failed=1
            ;;
    esac
done

# 2. Every ADR and every runbook is listed in its index; every ADR also
#    states its status.
#
# The per-document loop below runs whether or not that directory's index
# exists. Guarding the whole loop on the index, which is what this check did
# first for ADRs alone, meant that deleting or renaming the index silently
# switched off every check for the documents in that directory while this
# script still reported success: the single edit that breaks navigation into
# a directory was also the single edit that nothing could catch.
# That failure mode is closed here for both docs/adr and docs/runbooks, not
# only the directory it was first found in.
#
# A missing index is a failure only when there is a document to index. A
# repository with no docs/adr/ or docs/runbooks/ at all passes, because the
# standard does not require either, and one that has neither should not be
# made to carry an empty index to satisfy a checker.
#
# 0000-template.md is not an ADR, and README.md is not a runbook. Both are
# skipped and not counted, so a repository holding only the template still
# passes.

# Print the lines of a file that are outside fenced code blocks.
#
# grep has no idea what a fence is, so an index row written inside a
# ```markdown example satisfied the index check while the document had no
# real row. Fences are recognised at up to three spaces of
# indentation, the same limit CommonMark applies to headings; at four the
# line is an indented code block and its content is not a fence marker.
#
# The marker character and the run length of the opening fence are tracked,
# not just an in/out toggle, and a fence only closes on a run of the same
# character at least as long, with nothing but whitespace after it. That is
# CommonMark's own closing rule. Without it, a single boolean flipped by
# either ``` or ~~~ let a ~~~ block nested inside a ```markdown example close
# the outer fence early, so a fake row inside the nested block was read as
# ordinary text again: the same false accept, arriving
# through a second marker. Interval regexes such as /^`{3,}/ are avoided
# because busybox awk's support for them is not something this check should
# depend on.
strip_fences() {
    awk '
        function fence_run(s, ch,   n) {
            n = 0
            while (substr(s, n + 1, 1) == ch) n++
            return n
        }
        { sub(/\r$/, "", $0) }
        { match($0, /^ */); indent = RLENGTH; rest = substr($0, indent + 1) }
        indent < 4 {
            btick = fence_run(rest, "`")
            tilde = fence_run(rest, "~")
            if (!infence) {
                if (btick >= 3) { infence = 1; fchar = "`"; flen = btick; next }
                if (tilde >= 3) { infence = 1; fchar = "~"; flen = tilde; next }
            } else {
                run = (fchar == "`") ? btick : tilde
                if (run >= flen && substr(rest, run + 1) ~ /^[ \t]*$/) {
                    infence = 0
                    next
                }
            }
        }
        infence { next }
        { print }
    ' "$1"
}

# Every Markdown file in docs/adr is the index, the template or an ADR named
# NNNN-title.md, and neither directory keeps Markdown in a subdirectory. A
# subdirectory of images or other assets is fine, so only Markdown is looked for. The loop below
# only looks at files that match its pattern directly inside the directory,
# so a misnamed or nested file would otherwise escape every check in it.
# The "?" in the pattern requires a title: "0001-.md" has none. A hidden file
# is rejected outright, because "*.md" never expands to one and the loop below
# would never see it.
for doc in "$ADR_DIR"/.*.md "$ADR_DIR"/.md docs/runbooks/.*.md docs/runbooks/.md; do
    [ -e "$doc" ] || continue
    note "$doc is a hidden file, so nothing indexes or checks it."
    note "  Rename it without the leading dot and add it to its index."
    failed=1
done
for doc in "$ADR_DIR"/*.md; do
    [ -e "$doc" ] || continue
    case ${doc##*/} in
        README.md|[0-9][0-9][0-9][0-9]-?*.md)
            ;;
        *)
            note "$doc is not named NNNN-title.md."
            note "  Rename it to the next four-digit number in $ADR_INDEX."
            failed=1
            ;;
    esac
done
for dir in "$ADR_DIR" docs/runbooks; do
    [ -d "$dir" ] || continue
    nested=$(find "$dir" -mindepth 2 -type f -name '*.md')
    if [ -n "$nested" ]; then
        printf '%s\n' "$nested" | while IFS= read -r doc; do
            note "$doc is in a subdirectory of $dir."
        done
        note "  $dir keeps no Markdown in subdirectories, so its index is the whole of it."
        note "  Move these files up into $dir and add them to its index."
        failed=1
    fi
done

# Fields: directory, index file, filename pattern, name to skip.
for pair in \
    "$ADR_DIR|$ADR_INDEX|[0-9][0-9][0-9][0-9]-?*.md|0000-template.md" \
    "docs/runbooks|docs/runbooks/README.md|*.md|README.md"
do
    dir=${pair%%|*}; rest=${pair#*|}
    index=${rest%%|*}; rest=${rest#*|}
    pattern=${rest%%|*}; skip=${rest#*|}

    found=0
    for doc in "$dir"/$pattern; do
        [ -e "$doc" ] || continue
        name=${doc##*/}
        # An `if`, not `[ ... ] && continue`: under `set -e` a false AND-list
        # is a failing command and aborts the script rather than skipping one
        # file. The original check 2 used an `if` for exactly this reason.
        if [ "$name" = "$skip" ]; then
            continue
        fi
        found=$((found + 1))

        # An ADR with no status is indistinguishable from one that was never
        # accepted, and the Status column of the index then has nothing behind
        # it: the index says Accepted while the record itself says nothing.
        # This runs regardless of whether the index exists, because it has
        # nothing to do with the index, and applies to ADRs only: a runbook
        # carries no Status line and is not held to this rule.
        # A Status line with nothing after it says as little as no line, and
        # one inside a fenced example is not the ADR's own.
        if [ "$dir" = "$ADR_DIR" ] && ! strip_fences "$doc" | grep -qE '^\*\*Status:\*\*[[:space:]]*[^[:space:]]'; then
            note "$doc has no **Status:** line, or the line is empty."
            note "  Every ADR carries one. Start from 0000-template.md."
            failed=1
        fi

        # The index-membership check needs an index. When it is absent, the
        # report after this loop says so once, rather than once per document.
        if [ -f "$index" ]; then
            # Require the match to be a row of the index table, not merely
            # the filename appearing somewhere in the file. A bare string in
            # prose or inside a code fence satisfied the old substring grep,
            # so a document could be mentioned while having no row, which is
            # the same as being absent: the table is the only navigation
            # into this directory.
            # The filename goes into an ERE, so its dots are wildcards
            # unless escaped: an index row reading (0001-fooXmd) satisfied
            # the check for 0001-foo.md.
            #
            # The closing bracket has to come first in the class, right
            # after the opening one: a bracket expression is not
            # backslash-escaped internally (POSIX leaves backslash literal
            # inside one), so a "]" anywhere else in the class would close
            # it early and split the class in two.
            #
            # The class covers every ERE metacharacter that can appear in a
            # filename, not only the ones a dash-delimited ADR or runbook
            # name happens to use: "( ) + ? { } |" are ERE-significant too,
            # and were missing here. A filename such as restore+db.md or
            # opts{a|b}.md went into the row pattern with those characters
            # still live, so a wrong index row could satisfy it (or, for an
            # unbalanced "(" or "{", made grep -E itself error out, which
            # surfaced as a misdiagnosed "no row in the index table" instead
            # of the escaping bug it actually was).
            esc=$(printf '%s' "$name" | sed 's/[].[*^$\()+?{}|]/\\&/g')

            # Accept the spellings that resolve: a bare name, a ./ prefix, a
            # #fragment, and a "title". Rejecting those told the author to
            # write the link "exactly as ($name)" when what they had was
            # already correct.
            #
            # A complete "[label](" makes it a Markdown link: a filename in
            # plain parentheses, a bare "](" or an image "![label](" all
            # passed while giving no link to follow.
            row="^\\|.*[^!]\\[[^]]+\\]\\((\\./)?$esc(#[^)]*)?( \"[^\"]*\")?\\)"
            if ! strip_fences "$index" | grep -qE "$row"; then
                note "$doc has no row in the index table in $index."
                note "  Add a table row linking it as [Title]($name). A ./ prefix, a"
                note "  #fragment and a \"title\" are all accepted; a mention in"
                note "  prose or inside a code fence is not a row."
                failed=1
            fi
        fi
    done

    if [ "$found" -ne 0 ] && [ ! -f "$index" ]; then
        note "$index is missing, but $dir holds $found document(s)."
        note "  The index table is the only navigation into this directory, so a"
        note "  missing index hides every document in it. Restore it with a row"
        note "  per document."
        failed=1
    fi
done

# 3. Living documents describe the present.
#
# Rule 6 of the standard: what is planned, in progress or deferred lives in the
# issue tracker, where it moves without a commit. A roadmap in a document is
# right the day it is written and wrong a month later, and no reviewer catches
# that, because nothing in the diff is wrong.
#
# Scoped to the homes the standard governs: the repository root, plus docs/,
# minus ADRs and the record directory. An ADR is a decision record, not a
# living document (its index and template are, and stay in scope), and its Consequences may name work it leaves for later.
# Scanning the whole tree failed the build on content nobody here wrote, because
# find respects neither .gitignore nor hidden directories: node_modules/ in a
# TypeScript repo and vendor/ in a Go one both carry Roadmap and TODO headings. The link check already skips
# those. The two checks now agree on scope: whatever invokes them passes
# lychee the same record-directory exclusion, so a point-in-time record is
# out of scope for both. A record whose links are held to current-tree
# accuracy is not a point-in-time record, which is rule 5.
#
# HEADINGS_AWK prints "FILENAME:LINE:text" for every heading that matches
# FORWARD_HEADINGS, with fences and front matter already stripped, so a
# single collected file's worth of output is already the finished list; there
# is nothing left for a shell grep to filter, and nothing for it to
# accidentally match against a path instead of heading text.
#
# The exit status of each `find -exec awk ...` is captured explicitly, rather
# than folding both invocations into one `{ ... } 2>/dev/null || true` group.
# That grouping is how a broken HEADINGS_AWK (an unbalanced brace, say) went
# unnoticed: awk's failure was thrown away along with its stderr, the
# extractor silently produced no hits, and the script went on to report
# success against a tree that still had a Roadmap section in it. A check
# that cannot run must fail the build, not pass it by omission. `find`'s own
# stderr is not separately suppressed here either, since separating it from
# the child awk's stderr, which share the same descriptor, is not reliable.
#
# The output collects into a temporary file rather than a shell variable
# accumulated across two command substitutions, and `mktemp` with no
# arguments creates that file under /tmp, outside the repository the
# container mounts at its working directory: a check must not write into the
# tree it is checking, even a scratch file cleaned up before exit.
extractor_failed=0
hits=$(mktemp)
find . -maxdepth 1 -type f -name '*.md' \
    -exec awk -v pat="$FORWARD_HEADINGS" "$HEADINGS_AWK" {} + >>"$hits" || extractor_failed=1
if [ -d ./docs ]; then
    find ./docs -type f -name '*.md' ! -path "$RECORD_DIR/*" \
        ! \( -path "./$ADR_DIR/[0-9][0-9][0-9][0-9]-?*.md" ! -name 0000-template.md \) \
        -exec awk -v pat="$FORWARD_HEADINGS" "$HEADINGS_AWK" {} + >>"$hits" || extractor_failed=1
fi
if [ "$extractor_failed" -ne 0 ]; then
    note "the heading extractor failed, so the forward-looking heading check did not run."
    note "  This is reported as a failure rather than passed over: a check that"
    note "  could not run must not be indistinguishable from one that ran clean."
    failed=1
fi
forward_hits=$(cat "$hits")
rm -f "$hits"
if [ -n "$forward_hits" ]; then
    note "forward-looking headings in living documents:"
    printf '%s\n' "$forward_hits" | while IFS= read -r hit; do
        note "  $hit"
    done
    note "  A living document describes the present. Move this to the issue"
    note "  tracker and link to it. See rule 6 of the documentation standard."
    note "  Rejected heading words: $FORWARD_TERMS."
    note "  $RECORD_DIR and the ADRs themselves are exempt: they are point-in-time records."
    note "  The list is a heuristic: a heading naming something that already"
    note "  exists, such as \"Roadmap API\", fails too. Rename the heading."
    failed=1
fi

if [ "$failed" -ne 0 ]; then
    note "FAILED"
    exit 1
fi

echo "check-docs: root allowlist, ADR and runbook indexes, and living-document headings are consistent."
