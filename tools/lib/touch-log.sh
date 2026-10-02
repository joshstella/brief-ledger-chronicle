# When a path was touched, defined once.
#
# Sourced, never invoked: no shebang, no execute bit. See tools/lib/phase-row.sh for why
# `tools/lib/` is the declaration.
#
# Every date the toolkit shows about a brief comes from git history: the first and last
# columns of `list-briefs.sh`, the order the chronicle narrates in, what the chronicle counts
# as new since its last run, and the age `orient.sh` gives a declaration. #0017 moved the
# whole record from `docs/` to `docs/blc/`, and two things in that brief would have reset
# every one of those dates to the day of the move:
#
#   the move     `git log -- <dir>` does not follow a rename, so a moved folder has no history
#                before the move. Each tracked file under a folder is followed back through
#                its earlier names, and the log runs over all of them.
#
# Not `git log --follow`, which was the first version of this. `--follow` follows copies as
# well as renames: a new ledger that is close to an older brief's ledger inherited that
# brief's history, and its first date moved to before it existed. Briefs and ledgers are
# written from the same templates, so near-copies are the normal case here, not a corner.
# `blc_touch_renames` reads only rename records, and only those are followed.
#
#   the rewrite  phase `b` rewrites the paths inside every brief and ledger. That is a real
#                content change, so following renames cannot hide it. It would become every
#                brief's last touch.
#
# Neither commit is work on the briefs it touched. The ignore list names commits like these,
# in the format of git's own `.git-blame-ignore-revs`: one commit per line, `#` starts a
# comment. A rename-following reader alone would fix the move and keep the rewrite, and then
# the timeline would be lost one phase later.
#
# Each entry is resolved with `git rev-parse`, so an abbreviated hash works. An entry that
# does not resolve is reported on stderr, not dropped quietly: a typo there would put a
# rewrite back into every date with nothing to say why.

# usage: blc_touch_skip IGNORE_FILE
# Prints the full hash of each commit IGNORE_FILE names, one per line. A missing IGNORE_FILE
# names none. Separate from `blc_touch_log` so a tool resolves the list once, and reports a
# bad entry once, rather than once per brief.
blc_touch_skip() {
  local entry sha
  [ -f "$1" ] || return 0
  while IFS= read -r entry || [ -n "$entry" ]; do
    entry="${entry%%#*}"
    entry="$(printf '%s' "$entry" | tr -d '[:space:]')"
    [ -n "$entry" ] || continue
    if sha="$(git rev-parse --verify -q "$entry^{commit}" 2>/dev/null)"; then
      printf '%s\n' "$sha"
    else
      printf '%s: %s is not a commit here, so it ignores nothing\n' "$1" "$entry" >&2
    fi
  done < "$1"
}

# usage: blc_touch_renames
# Prints `<old path><TAB><new path>` for every rename in the history of HEAD, relative to the
# top of the repository. One walk of the history, so a tool reads it once, not once per brief.
# A merge commit records no renames of its own here, and that is fine for a squash-merge
# history. The quoting is off so a non-ASCII name matches the name `ls-files` prints.
blc_touch_renames() {
  # A repository with no commits has no HEAD, and `git log` exits 128. Its callers run under
  # `pipefail` plus `set -e`, so the failure has to stop here: a fresh install has no history,
  # and that is not an error.
  { git -c core.quotePath=false log -M --diff-filter=R --name-status --format= 2>/dev/null || true; } \
    | awk -F'\t' '$1 ~ /^R/ { print $2 "\t" $3 }'
}

# usage: blc_touch_names RENAMES PATH
# Prints PATH, then every name it had before, newest first. A name used again after a rename
# would bring the new file's commits in with the old one's. Nothing here does that, and the
# move in #0017 leaves the old names empty.
blc_touch_names() {
  printf '%s\n' "$1" | awk -F'\t' -v start="$2" '
    NF == 2 { older[$2] = older[$2] SUBSEP $1 }
    END {
      queue[1] = start; n = 1; seen[start] = 1
      for (i = 1; i <= n; i++) {
        print queue[i]
        k = split(older[queue[i]], names, SUBSEP)
        for (j = 2; j <= k; j++) if (!(names[j] in seen)) { seen[names[j]] = 1; queue[++n] = names[j] }
      }
    }
  '
}

# usage: blc_touch_log SKIP RENAMES PATH...
# Prints `<unix-author-time> <iso-author-time>` for each commit that touched any PATH, newest
# first, once per commit, minus the commits in SKIP (the output of `blc_touch_skip`). A
# directory PATH covers every file tracked under it, each followed back through the renames
# in RENAMES (the output of `blc_touch_renames`).
blc_touch_log() {
  local skip="$1" renames="$2" p f name
  shift 2
  {
    for p in "$@"; do
      # The folder's own log still runs: it is the only one that sees a file deleted from
      # the folder, which `ls-files` no longer lists.
      [ -d "$p" ] && { git log --format='%H %at %aI' -- "$p" 2>/dev/null || true; }
      # `--full-name` because the rename records are relative to the top of the repository,
      # and `:(top)` below reads them that way from any working directory. `literal` because
      # each is a file name, not a pattern: a draft once named `what-[x].md` would otherwise
      # take the history of a different draft named `what-x.md`.
      while IFS= read -r f; do
        blc_touch_names "$renames" "$f" | sed 's/^/:(top,literal)/' | {
          set --
          while IFS= read -r name; do set -- "$@" "$name"; done
          git log --format='%H %at %aI' -- "$@" 2>/dev/null || true
        }
      done < <(git ls-files --full-name -- "$p" 2>/dev/null)
    done
  # One line, not one hash per line: the one true awk refuses a newline in a -v value, and
  # that is the awk macOS ships. A hash holds no space, so a space is a safe separator.
  } | awk -v skip="$(printf '%s' "$skip" | tr '\n' ' ')" '
    BEGIN { n = split(skip, s, " "); for (i = 1; i <= n; i++) if (s[i] != "") ignored[s[i]] = 1 }
    !($1 in ignored) && !seen[$1]++ { print $2, $3 }
  ' | sort -k1,1nr
}
