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
#                before the move. Each tracked file under a folder is followed on its own
#                with `--follow`, which only works on a single path.
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

# usage: blc_touch_log SKIP PATH...
# Prints `<unix-author-time> <iso-author-time>` for each commit that touched any PATH, newest
# first, once per commit, minus the commits in SKIP (the output of `blc_touch_skip`). A
# directory PATH covers every file tracked under it, each followed through renames.
blc_touch_log() {
  local skip="$1" p f
  shift
  {
    for p in "$@"; do
      if [ -d "$p" ]; then
        # The folder's own log still runs: it is the only one that sees a file deleted
        # from the folder, which `ls-files` no longer lists.
        git log --format='%H %at %aI' -- "$p" 2>/dev/null || true
        while IFS= read -r f; do
          git log --follow --format='%H %at %aI' -- "$f" 2>/dev/null || true
        done < <(git ls-files -- "$p" 2>/dev/null)
      else
        git log --follow --format='%H %at %aI' -- "$p" 2>/dev/null || true
      fi
    done
  } | awk -v skip="$skip" '
    BEGIN { n = split(skip, s, "\n"); for (i = 1; i <= n; i++) if (s[i] != "") ignored[s[i]] = 1 }
    !($1 in ignored) && !seen[$1]++ { print $2, $3 }
  ' | sort -k1,1nr
}
