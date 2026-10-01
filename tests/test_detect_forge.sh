# tools/detect-forge.sh — which forge hosts the remote.
#
# Every run uses a PATH holding only links to git and tr and the stub CLIs a test asks for.
# PATH can shadow a program but cannot hide one, and /usr/bin/gh exists on GitHub's Ubuntu
# runners, so a test that wants "gh is not installed" has to build the PATH it runs on.
#
# Helper names are prefixed DF_ / df_ because run.sh sources every test file into one shell.

DF_TOOL() { printf '%s' "$REPO_ROOT/tools/detect-forge.sh"; }

# usage: df_repo [remote-url]   (no argument: no remote at all)
df_repo() {
  DF_REPO="$TMP/df-repo"
  rm -rf "$DF_REPO"
  git init -q "$DF_REPO"
  [ -z "${1:-}" ] || git -C "$DF_REPO" remote add origin "$1"
  DF_YARD="$TMP/df-yard"
  rm -rf "$DF_YARD"
  mkdir -p "$DF_YARD"
  ln -s "$(command -v git)" "$DF_YARD/git"
  ln -s "$(command -v tr)" "$DF_YARD/tr"
  : > "$DF_YARD/calls"
}

# A CLI that accepts `auth status --hostname <host>` only for the host given, and records
# every host it was asked about.
# usage: df_cli <gh|glab> <accepted-host>
df_cli() {
  printf '#!/bin/sh\nprintf "%%s %%s\\n" %s "$4" >> "%s/calls"\n[ "$1 $2 $3" = "auth status --hostname" ] && [ "$4" = "%s" ]\n' \
    "$1" "$DF_YARD" "$2" > "$DF_YARD/$1"
  chmod +x "$DF_YARD/$1"
}

df_run() {
  ( cd "$DF_REPO" && PATH="$DF_YARD" "$BASH" "$(DF_TOOL)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

test_detect_forge_names_github_when_gh_accepts_the_host() {
  df_repo https://github.com/o/r.git
  df_cli gh github.com
  df_cli glab nothing.example
  df_run
  assert_status 0
  [ "$(cat "$OUT")" = github ] || fail "printed '$(cat "$OUT")', not github"
}

# The case the URL alone cannot decide: a GitLab on a host with no recognisable name.
test_detect_forge_names_a_self_hosted_gitlab() {
  df_repo git@code.internal.example:team/r.git
  df_cli gh github.com
  df_cli glab code.internal.example
  df_run
  assert_status 0
  [ "$(cat "$OUT")" = gitlab ] || fail "printed '$(cat "$OUT")', not gitlab"
}

test_detect_forge_says_nothing_when_no_cli_accepts_the_host() {
  df_repo https://github.com/o/r.git
  df_cli gh other.example
  df_cli glab other.example
  df_run
  assert_status 1
  [ ! -s "$OUT" ] || fail "printed a forge on stdout: $(cat "$OUT")"
  assert_contains "neither CLI accepts github.com (gh: did not accept, glab: did not accept)" "$ERR"
}

# Picking one would be the guess this tool replaces.
test_detect_forge_refuses_a_host_both_clis_accept() {
  df_repo https://forge.example/o/r.git
  df_cli gh forge.example
  df_cli glab forge.example
  df_run
  assert_status 1
  [ ! -s "$OUT" ] || fail "picked a forge: $(cat "$OUT")"
  assert_contains "both gh and glab accept forge.example" "$ERR"
}

test_detect_forge_reports_a_cli_that_is_not_installed() {
  df_repo https://github.com/o/r.git
  df_cli glab other.example
  df_run
  assert_status 1
  assert_contains "gh: not installed, glab: did not accept" "$ERR"
}

# The host each URL shape must yield. The stub records the host it was asked about.
test_detect_forge_reads_the_host_from_every_url_shape() {
  local url want
  while IFS='|' read -r url want; do
    df_repo "$url"
    df_cli gh "$want"
    df_run
    [ "$(cat "$OUT")" = github ] \
      || fail "$url: expected host $want, gh was asked about: $(cat "$DF_YARD/calls")"
  done <<'URLS'
https://github.com/o/r.git|github.com
https://user:token@GitHub.com:443/o/r.git|github.com
ssh://git@ghe.example:2222/o/r.git|ghe.example
git@github.com:o/r.git|github.com
github.com:o/r.git|github.com
URLS
}

# A colon in a path must not make it read as `host:path`.
test_detect_forge_a_local_remote_has_no_host() {
  local url
  for url in /srv/git/r.git /srv/git/team:r.git ./team:r.git file:///srv/git/r.git; do
    df_repo "$url"
    df_cli gh /srv/git/team
    df_run
    assert_status 1
    assert_contains "has no host" "$ERR"
    [ ! -s "$DF_YARD/calls" ] || fail "$url: a CLI was asked about a local path: $(cat "$DF_YARD/calls")"
  done
}

test_detect_forge_errors_without_the_remote() {
  df_repo
  df_run
  assert_status 2
  assert_contains "no remote named origin" "$ERR"
}

test_detect_forge_reads_a_named_remote() {
  df_repo https://github.com/o/r.git
  git -C "$DF_REPO" remote add upstream git@gitlab.example:o/r.git
  df_cli gh github.com
  df_cli glab gitlab.example
  df_run upstream
  assert_status 0
  [ "$(cat "$OUT")" = gitlab ] || fail "printed '$(cat "$OUT")' for remote upstream"
}

test_detect_forge_uses_the_only_remote_when_there_is_no_origin() {
  df_repo
  git -C "$DF_REPO" remote add upstream https://github.com/o/r.git
  df_cli gh github.com
  df_run
  assert_status 0
  [ "$(cat "$OUT")" = github ] || fail "printed '$(cat "$OUT")' for the only remote"
}

test_detect_forge_does_not_pick_among_remotes_without_an_origin() {
  df_repo
  git -C "$DF_REPO" remote add one https://github.com/o/r.git
  git -C "$DF_REPO" remote add two https://github.com/o/s.git
  df_cli gh github.com
  df_run
  assert_status 2
  assert_contains "no remote named origin" "$ERR"
}

test_detect_forge_does_not_replace_a_named_remote() {
  df_repo
  git -C "$DF_REPO" remote add upstream https://github.com/o/r.git
  df_cli gh github.com
  df_run origin
  assert_status 2
  assert_contains "no remote named origin" "$ERR"
}

test_detect_forge_errors_outside_a_repository() {
  df_repo
  mkdir -p "$TMP/df-nowhere"
  ( cd "$TMP/df-nowhere" && PATH="$DF_YARD" GIT_CEILING_DIRECTORIES="$TMP" "$BASH" "$(DF_TOOL)" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 2
  assert_contains "not inside a git repository" "$ERR"
}
