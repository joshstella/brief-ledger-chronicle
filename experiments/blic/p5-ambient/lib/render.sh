#!/usr/bin/env bash
# lib/render.sh — the facts file -> one line, under a width budget.
#
# Rendering happens at refresh time, not at prompt time. The prompt prints a string somebody
# else already built; that is the whole latency argument of this prototype.
#
# Glyphs are opt-out. BLIC_ASCII=1 gives a line that survives a terminal with no UTF-8 and a
# font with no arrows, because a status line that renders as boxes is worse than no line.

blic_glyphs() {
  if [ "${BLIC_ASCII:-0}" = 1 ]; then
    G_RUN='>'; G_WAIT='.'; G_NEW='^'; G_DEFECT='!'; G_OK='ok'; G_STALE='?'; G_SYN='~'
  else
    G_RUN='▸'; G_WAIT='·'; G_NEW='↑'; G_DEFECT='!'; G_OK='✓'; G_STALE='?'; G_SYN='~'
  fi
}

# Reads the already-loaded fact variables (see blic_load_facts) and prints one line.
# $1 is the width budget. The brief's title is the only elastic part, so it absorbs whatever
# the fixed fields leave and nothing else has to be measured.
blic_render_line() {
  local width="${1:-80}" out="" tail="" room label
  blic_glyphs

  if [ -n "${mine_serial:-}" ]; then
    out="#${mine_serial}${mine_phase:-}"
    case "${mine_phase_state:-}" in
      in-progress) out="$G_RUN $out" ;;
      pending)     out="$G_WAIT $out" ;;
      *)           out="$G_WAIT $out" ;;
    esac
    [ "${mine_open:-0}" -gt 1 ] && out="$out+$(( mine_open - 1 ))"
  else
    out="$G_OK nothing open"
  fi

  # Order is deliberate: mine first, then what other people did, then the gate. A person
  # scanning left to right should hit their own next action before anything else.
  if [ "${new_total:-0}" -gt 0 ]; then
    tail="$G_NEW${new_total}"
    [ "${new_synthetic:-0}" -gt 0 ] && tail="$tail$G_SYN"
    out="$out · $tail"
  fi
  [ "${defects:-0}" -gt 0 ] && out="$out · $G_DEFECT${defects}"
  [ "${stale:-0}" = 1 ] && out="$out $G_STALE"

  # The phase label is the one thing that tells you what the serial is about. It goes in
  # only if the rest of the line left room for it, and it is cut rather than wrapped.
  label="${mine_phase_label:-}"
  [ -n "$label" ] || label="${mine_title:-}"
  if [ -n "$label" ] && [ -n "${mine_serial:-}" ]; then
    room=$(( width - ${#out} - 3 ))
    if [ "$room" -ge 8 ]; then
      [ "${#label}" -gt "$room" ] && label="${label:0:$(( room - 1 ))}…"
      out="$out · $label"
    fi
  fi
  printf '%s' "$out"
}

# key=value, one per line, values may hold spaces and nothing else. Loaded with `read`, not
# with `eval`: the facts file holds brief titles, and eval on a title is a shell injection
# with a markdown file as its payload.
blic_load_facts() {
  local file="$1" k v
  [ -f "$file" ] || return 1
  while IFS='=' read -r k v; do
    case "$k" in
      briefs_total|briefs_open|mine_open|no_ledger|mine_serial|mine_state|mine_title) ;;
      mine_phase|mine_phase_state|mine_phase_label|next_phase|next_label) ;;
      defects|new_total|new_synthetic|new_top|head|generated|events_total) ;;
      *) continue ;;
    esac
    printf -v "$k" '%s' "$v"
  done < "$file"
}
