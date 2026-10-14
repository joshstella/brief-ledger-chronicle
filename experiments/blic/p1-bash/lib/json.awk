# JSON to flat `path<US>value` lines. The bake-off bars jq, so this is the substitute.
#
# Output is one line per scalar, with the path a dotted trail of keys and array indexes:
#
#   3.serial<US>0004
#   3.phases.0.state<US>in-progress
#   3.phases.#<US>2
#
# The `#` entry gives each array its length, so a consumer knows how many children to
# expect without scanning for the highest index it happened to see.
#
# The separator is US (0x1f), not a tab. Bash `read` collapses runs of IFS whitespace, and
# a tab is IFS whitespace, so a tab-separated row with two empty fields in the middle
# arrives in the wrong variables. Every empty field in this record matters — an absent
# Owner is what makes a brief fall through to its Author.
#
# Tabs and newlines inside string values are turned into spaces for the same reason, and
# because this feeds a single-line renderer that cannot show them anyway.

function err(m) { print "json.awk: " m " at " pos > "/dev/stderr"; exit 2 }

function ws(   c) {
  while (pos <= n) {
    c = substr(doc, pos, 1)
    if (c == " " || c == "\t" || c == "\n" || c == "\r") pos++
    else return
  }
}

function jstring(   out, c) {
  pos++                                    # opening quote
  out = ""
  while (pos <= n) {
    c = substr(doc, pos, 1)
    if (c == "\\") {
      pos++
      c = substr(doc, pos, 1)
      if (c == "n" || c == "t" || c == "r") out = out " "
      # read.sh escapes only \\ \" \n \r \t, so \u never appears. If a future producer
      # emits one it lands here as a literal `u` rather than being silently dropped.
      else out = out c
      pos++
    } else if (c == "\"") {
      pos++
      return out
    } else {
      out = out c
      pos++
    }
  }
  err("unterminated string")
}

function value(path,   c, k, i, s) {
  ws()
  c = substr(doc, pos, 1)

  if (c == "{") {
    pos++; ws()
    if (substr(doc, pos, 1) == "}") { pos++; return }
    while (1) {
      ws()
      if (substr(doc, pos, 1) != "\"") err("object key expected")
      k = jstring()
      ws()
      if (substr(doc, pos, 1) != ":") err("colon expected")
      pos++
      value(path == "" ? k : path "." k)
      ws()
      c = substr(doc, pos, 1); pos++
      if (c == ",") continue
      if (c == "}") return
      err("bad object")
    }
  }

  if (c == "[") {
    pos++; ws(); i = 0
    if (substr(doc, pos, 1) == "]") {
      pos++
      print (path == "" ? "#" : path ".#") SEP "0"
      return
    }
    while (1) {
      value(path == "" ? i : path "." i)
      i++
      ws()
      c = substr(doc, pos, 1); pos++
      if (c == ",") continue
      if (c == "]") { print (path == "" ? "#" : path ".#") SEP i; return }
      err("bad array")
    }
  }

  if (c == "\"") { print path SEP jstring(); return }

  # number, true, false, null
  s = ""
  while (pos <= n) {
    c = substr(doc, pos, 1)
    if (c == "," || c == "]" || c == "}" || c == " " || c == "\n" || c == "\t" || c == "\r") break
    s = s c
    pos++
  }
  if (s == "") err("value expected")
  print path SEP s
}

BEGIN { SEP = sprintf("%c", 31) }
{ doc = doc $0 "\n" }
END {
  n = length(doc)
  pos = 1
  ws()
  if (pos > n) exit 0
  value("")
}
