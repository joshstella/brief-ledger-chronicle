#!/usr/bin/env python3
"""pty-session.py — drive an interactive bash on a pty and print what the terminal saw.

capture.sh uses this to capture the prompt segment. PS1 is only evaluated by an interactive
shell on a terminal, so a capture taken without a pty is a reproduction of a prompt rather
than a prompt, and the one surface this prototype is really arguing for would be the one
thing in the report nobody could check.

Usage: pty-session.py <rcfile> <cwd> <command>...
Stdlib only. python3 is not a dependency of any surface here, only of this capture tool.
"""
import os
import pty
import select
import sys


def main() -> int:
    rcfile, cwd, *commands = sys.argv[1:]
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(cwd)
        os.environ["PS1"] = ""  # the rcfile sets the real one
        os.execvp("bash", ["bash", "--rcfile", rcfile, "-i"])
        raise SystemExit(127)

    # Feed one command per prompt. A single write of everything races the shell's own echo
    # and the transcript comes back interleaved.
    script = "".join(c + "\n" for c in commands) + "exit\n"
    out = bytearray()
    pending = script.encode()
    while True:
        r, w, _ = select.select([fd], [fd] if pending else [], [], 5.0)
        if w and pending:
            n = os.write(fd, pending[:64])
            pending = pending[n:]
        if r:
            try:
                chunk = os.read(fd, 4096)
            except OSError:
                break
            if not chunk:
                break
            out += chunk
        elif not r and not w:
            break
    os.waitpid(pid, 0)
    text = out.decode("utf-8", "replace").replace("\r\n", "\n")
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
