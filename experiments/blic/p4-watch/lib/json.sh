#!/usr/bin/env bash
# A reader for the shape read.sh prints, and only that shape.
#
# Hand-rolled for the same reason read.sh hand-rolls its writer: the thesis of this prototype
# is that a stock shell is enough, and `jq` is not installed on the machine this was measured
# on. It is not a JSON parser. It knows that read.sh emits flat objects of string and boolean
# fields, one nested `phases` array, and no newlines inside values.

# blic_records <json-array> <first-key> — split an array of objects into one record per line.
# Objects are rejoined on their first key, which read.sh writes first and never nests.
# The trailing newline matters: without it `read` returns false on the last record and the
# caller silently drops it. That cost one brief — the only in-progress one in the fixture.
blic_records() {
  printf '%s\n' "$1" | sed "s/},{\"$2\":/}\n{\"$2\":/g" | sed 's/^\[//; s/\]$//'
}

# blic_field <record> <key> — the string or boolean value of one key.
# Values end at the next `,"key":` pair, so a value containing that sequence would cut short.
# read.sh escapes quotes, so the sequence cannot appear inside a brief title.
blic_field() {
  local s="$1"
  case "$s" in *"\"$2\":"*) ;; *) return 0 ;; esac
  s="${s#*\"$2\":}"
  s="${s%%,\"*}"
  s="${s%\}}"
  s="${s%\"}"; s="${s#\"}"
  printf '%s' "$s"
}

# blic_phases <record> — the phase objects of one brief, one per line.
blic_phases() {
  local s="$1"
  case "$s" in *'"phases":['*) ;; *) return 0 ;; esac
  s="${s#*\"phases\":[}"
  s="${s%]*}"
  [ -n "$s" ] || return 0
  printf '%s\n' "$s" | sed 's/},{/}\n{/g'
}
