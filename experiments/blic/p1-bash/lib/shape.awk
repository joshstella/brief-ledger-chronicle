# Flat `path<US>value` lines (from json.awk) to one US-separated record per array element.
#
# Called with -v kind=briefs|events|defects|declarations. The field order per kind is the
# contract between this file and the `load_*` functions in ../blic, and nothing else reads
# it, so it is stated here once rather than passed in.
#
# Nested arrays — a brief's phases, a declaration's claims — are packed into the last field
# with GS (0x1d) between children and RS (0x1e) between a child's fields. Those two bytes
# cannot occur in a ledger, and a `|` or `;` separator can: phase labels are free prose cut
# out of a markdown table.

BEGIN {
  SEP = sprintf("%c", 31)
  GS  = sprintf("%c", 29)
  RSX = sprintf("%c", 30)
  FS = SEP
  if (kind == "briefs") {
    nf = split("serial,state,mine,assignee,title,has_ledger,status_line,closed,slug,dir,created,owner,author", F, ",")
    child = "phases"; nc = split("id,label,state,pointer", C, ",")
  } else if (kind == "events") {
    nf = split("when,who,mine,kind,serial,phase,sha,subject", F, ",")
  } else if (kind == "defects") {
    nf = split("subject,clause,kind,message", F, ",")
  } else if (kind == "declarations") {
    nf = split("who,mine,touched", F, ",")
    child = "claims"; nc = 0
  } else {
    print "shape.awk: unknown kind: " kind > "/dev/stderr"; exit 2
  }
}

{
  path = $1; val = $2
  if (path ~ /^[0-9]+\.[a-z_]+$/) {
    split(path, a, ".")
    V[a[1] + 0, a[2]] = val
    if (a[1] + 0 > MAX) MAX = a[1] + 0
    ANY = 1
  } else if (child != "" && path ~ ("^[0-9]+\\." child "\\.[0-9]+\\.[a-z]+$")) {
    split(path, a, ".")
    P[a[1] + 0, a[3] + 0, a[4]] = val
  } else if (child != "" && path ~ ("^[0-9]+\\." child "\\.[0-9]+$")) {
    # A child array of bare strings, which is what a declaration's claims are.
    split(path, a, ".")
    P[a[1] + 0, a[3] + 0, "_"] = val
  } else if (child != "" && path ~ ("^[0-9]+\\." child "\\.#$")) {
    split(path, a, ".")
    N[a[1] + 0] = val + 0
  }
}

END {
  if (!ANY) exit 0
  for (i = 0; i <= MAX; i++) {
    line = ""
    for (j = 1; j <= nf; j++) line = line (j > 1 ? SEP : "") V[i, F[j]]
    if (child != "") {
      packed = ""
      for (p = 0; p < N[i]; p++) {
        one = ""
        if (nc == 0) one = P[i, p, "_"]
        else for (j = 1; j <= nc; j++) one = one (j > 1 ? RSX : "") P[i, p, C[j]]
        packed = packed (p > 0 ? GS : "") one
      }
      line = line SEP packed
    }
    print line
  }
}
