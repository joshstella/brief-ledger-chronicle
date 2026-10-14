# parse-briefs.awk — read.sh briefs (one JSON line) -> key=value facts on stdout.
#
# awk and not jq. jq is not installed on this machine, and a surface that runs on every shell
# prompt cannot carry a dependency the shell itself does not already have. The instrument
# emits flat objects with one nested array, which is inside what a field scan can read; this
# would be the wrong tool against arbitrary JSON.

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
# The state field carries its pointer: `done(PR#11)`, `in-progress`. The word before the
# bracket is the state the five-state vocabulary names.
function bare(s,   t) { t = s; sub(/\(.*$/, "", t); return t }

{
  n = split($0, rec, /\{"serial":/)
  for (i = 2; i <= n; i++) {
    r = "\"serial\":" rec[i]
    serial = fld(r, "serial")
    state  = bare(fld(r, "state"))
    mine   = isTrue(r, "mine")
    total++
    if (!isTrue(r, "has_ledger")) no_ledger++
    if (state == "done" || state == "superseded" || state == "abandoned") continue
    open_n++
    if (!mine) continue
    mine_open++
    if (mine_serial != "") continue            # first open brief of mine wins the line
    mine_serial = serial
    mine_state  = state
    mine_title  = fld(r, "title")
    # The phase that is actually in flight, then the one that is next. A brief whose phases
    # are all done but whose own line is not done is the gap #0039 cites, and it shows here
    # as a brief with no phase to name.
    pn = split(r, ph, /\{"id":/)
    for (j = 2; j <= pn; j++) {
      p = "\"id\":" ph[j]
      ps = bare(fld(p, "state"))
      if (ps == "in-progress" && mine_phase == "") {
        mine_phase = fld(p, "id"); mine_phase_state = ps; mine_phase_label = fld(p, "label")
      } else if (ps == "pending" && next_phase == "") {
        next_phase = fld(p, "id"); next_label = fld(p, "label")
      }
    }
    if (mine_phase == "" && next_phase != "") {
      mine_phase = next_phase; mine_phase_state = "pending"; mine_phase_label = next_label
    }
  }
}
END {
  print "briefs_total=" total+0
  print "briefs_open=" open_n+0
  print "mine_open=" mine_open+0
  print "no_ledger=" no_ledger+0
  print "mine_serial=" mine_serial
  print "mine_state=" mine_state
  print "mine_title=" mine_title
  print "mine_phase=" mine_phase
  print "mine_phase_state=" mine_phase_state
  print "mine_phase_label=" mine_phase_label
  print "next_phase=" next_phase
  print "next_label=" next_label
}
