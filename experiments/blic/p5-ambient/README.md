# p5-ambient

Prototype 5 of the #0039 bake-off: the record in the places a person already looks, rather
than in a console they would have to open.

- **`REPORT.md`** — the eight bake-off questions, with measured numbers. Read this first.
- **`INSTALL.md`** — how to opt into each of the three surfaces, and how to remove it.
- **`captures/`** — each surface rendering the real record, plus the raw `bench.sh` output.

Nothing here is installed, nothing writes a record, and nothing runs between invocations.

```
blic-prompt.bash       surface 1: the shell prompt segment (source it)
blic-statusline.sh     surface 2: the Cursor CLI status line
hooks/                 surface 3: the agent-event hooks
blic-refresh.sh        the slow read, run detached, never in front of a person
bin/blic               line | why | ack | refresh | doctor
lib/                   the renderer and the two awk parsers
bench.sh capture.sh    the harness that produced REPORT.md and captures/
```

Quick look, without installing anything:

```sh
./bin/blic refresh --full && ./bin/blic why
BLIC_PEER=1 ./bin/blic refresh --events && BLIC_PEER=1 ./bin/blic why
```
