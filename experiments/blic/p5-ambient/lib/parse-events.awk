# parse-events.awk — events -> one record per line: sha, mine, synthetic, kind, serial, who,
# subject, separated by \x1f.
#
# Not tab. Tab is IFS whitespace, so bash `read` collapses runs of it and an event with an
# empty `serial` silently shifts `who` into `subject`. Found that the first time a
# declaration event rendered with no subject. \x1f is not whitespace, so empty fields survive
# the hop into the shell. read.sh picks \x1f for the same reason.
#
# Accepts both shapes the bake-off hands out: read.sh events prints one JSON array on one
# line, peer-events.sh prints one object per line. Splitting on the `sha` key covers both,
# so the two sources merge without a second parser.
#
# `synthetic` is carried through, never defaulted. A surface that shows a peer-events.sh line
# without the mark is lying about the record, and the only way to keep that honest is to make
# the mark survive every hop.

function fld(s, name,   t) {
  if (match(s, "\"" name "\":\"[^\"]*\"")) {
    t = substr(s, RSTART, RLENGTH)
    sub("^\"" name "\":\"", "", t)
    sub("\"$", "", t)
    return t
  }
  return ""
}
function isTrue(s, name) { return (index(s, "\"" name "\":true") > 0) }

{
  n = split($0, rec, /\{"sha":/)
  for (i = 2; i <= n; i++) {
    r = "\"sha\":" rec[i]
    sha = fld(r, "sha")
    if (sha == "") continue
    printf "%s\037%d\037%d\037%s\037%s\037%s\037%s\n", \
      sha, isTrue(r, "mine"), isTrue(r, "synthetic"), \
      fld(r, "kind"), fld(r, "serial"), fld(r, "who"), fld(r, "subject")
  }
}
