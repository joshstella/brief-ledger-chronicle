#!/usr/bin/env bash
# experiments/blic/peer-events.sh — synthetic events from a peer, for the #0039 bake-off.
#
# Why this exists: this repository has one author. Every real event is `"mine": true`, so the
# half of #0039 that matters most — "what changed that I did not do" — cannot be demonstrated
# against the real record at all. A prototype that only ever saw its own commits would show a
# notification surface nobody could judge.
#
# Every event this prints carries `"synthetic": true`. Nothing removes that field. A console
# that shows these without marking them is lying about the record, and the field is there so
# the mistake is visible rather than arguable.
#
#   peer-events.sh            print the fixed set once
#   peer-events.sh --stream   print one every few seconds, forever, for a live view
set -euo pipefail

INTERVAL="${BLIC_PEER_INTERVAL:-7}"

# Fixed, not random. Five prototypes comparing notification behaviour need the same events in
# the same order, and a random generator makes two runs incomparable for no gain.
events() {
  cat <<'EOF'
{"sha":"c0ffee01","who":"dana@example.test","mine":false,"synthetic":true,"kind":"phase","serial":"0024","phase":"b","subject":"[#0024b] split the renderer from the scan"}
{"sha":"c0ffee02","who":"dana@example.test","mine":false,"synthetic":true,"kind":"declaration","serial":"","phase":"","subject":"docs: declare #0041, picked up not yet filed"}
{"sha":"c0ffee03","who":"sam@example.test","mine":false,"synthetic":true,"kind":"filed","serial":"0041","phase":"","subject":"docs: file #0041, the serial two people took"}
{"sha":"c0ffee04","who":"sam@example.test","mine":false,"synthetic":true,"kind":"close","serial":"0024","phase":"","subject":"docs: close #0024 (the renderer split)"}
{"sha":"c0ffee05","who":"dana@example.test","mine":false,"synthetic":true,"kind":"code","serial":"","phase":"","subject":"fix: the scan no longer reads its own example"}
EOF
}

if [ "${1:-}" = "--stream" ]; then
  while :; do
    while IFS= read -r line; do
      printf '%s\n' "$line"
      sleep "$INTERVAL"
    done < <(events)
  done
else
  events
fi
