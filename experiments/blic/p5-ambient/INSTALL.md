# Installing the three surfaces

Nothing here is installed. This prototype wrote no file in your home directory, touched no
`~/.cursor` file, and added nothing to your shell startup. Each surface below is opt-in, and
each one is one line to put in and one line to take out.

Let `P5` be the absolute path of this directory:

```sh
P5="$(git rev-parse --show-toplevel)/experiments/blic/p5-ambient"
```

## What all three share

A cache in `$XDG_RUNTIME_DIR/blic-$UID/` (or `/tmp/blic-$UID/` when the system gives no
runtime directory), one entry per checkout. It holds a rendering of the record, never a
record. Delete the directory and the next refresh rebuilds it.

Nothing runs between invocations. There is no daemon, nothing to start at login, and nothing
to kill. Refreshing stops the moment the last shell, CLI session and agent session is gone.

## 1. The shell prompt segment

Install — one line in `~/.bashrc`, and one edit to `PS1`:

```sh
. "$P5/blic-prompt.bash" && PS1='$(blic_prompt) \w \$ '
```

Uninstall: delete that line.

For zsh, fish, tmux, or anything that cannot source a bash function, use the script instead
and pay about 6ms per prompt rather than 0.03ms:

```sh
PROMPT='$('"$P5"'/bin/blic line) %~ %# '     # zsh
```

Knobs, all optional: `BLIC_TTL` (seconds before a prompt spawns a refresh, default 20),
`BLIC_WIDTH` (line budget, default 72), `BLIC_ASCII=1` (no glyphs), `BLIC_PEER=1` (merge the
synthetic peer events, which is the only way to see the `↑` counter in this repository).

## 2. The Cursor CLI status line

Merge the `statusLine` key from `cli-config.example.json` into `~/.cursor/cli-config.json`,
keeping whatever that file already holds, and put your own absolute path in `command`:

```sh
# review this before running it; it edits a file in your home directory
python3 - "$P5" <<'EOF'
import json, os, sys
p = os.path.expanduser("~/.cursor/cli-config.json")
cfg = json.load(open(p)) if os.path.exists(p) else {}
cfg["statusLine"] = {"type": "command", "command": sys.argv[1] + "/blic-statusline.sh",
                     "padding": 2, "updateIntervalMs": 1000, "timeoutMs": 2000}
json.dump(cfg, open(p, "w"), indent=2)
EOF
```

Uninstall: delete the `statusLine` key.

Test it without installing anything:

```sh
echo '{"cwd":"'"$(git rev-parse --show-toplevel)"'","render_width_chars":100,
       "model":{"display_name":"Opus"},"context_window":{"used_percentage":34.5}}' \
  | "$P5/blic-statusline.sh"
```

## 3. The hooks

Merge the three entries from `hooks.json.example` into `.cursor/hooks.json` at the project
root, preserving any hooks already there. Paths in a project hooks file are relative to the
project root, and the example already uses the right ones.

Uninstall: remove those three entries.

Read `REPORT.md` question 6 before you install this one. `sessionStart` and `stop` only warm
the cache. `beforeShellExecution` is the only event that can show you a sentence, it fires
only when you are about to run a matching command, and **whether the CLI renders
`user_message` on an `allow` verdict is unverified here** — nothing was installed, so nothing
was observed firing.

Test the scripts without installing them:

```sh
printf '{"cwd":"%s","command":"git push"}' "$(git rev-parse --show-toplevel)" \
  | "$P5/hooks/blic-notify.sh"
```

## Reproducing the report

```sh
"$P5/bench.sh"      # every number in REPORT.md
"$P5/capture.sh"    # every file in captures/
"$P5/bin/blic" doctor
```
