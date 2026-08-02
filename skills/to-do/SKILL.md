---
name: to-do
description: Capture a to-do note, timestamp it, and append it to docs/to-dos/todo.md in the current project. Use whenever the user says "/to-do <text>" or asks to log a task, reminder, or note to their project to-do list.
---

# To-Do Logger

Capture the user's note, add a timestamp, and append it to the current project's to-do log.

## Steps

1. **Get the timestamp.** Run `date '+%Y-%m-%d %H:%M'` to get the current local date and time.

2. **Resolve the project root.** The current working directory is the project root (it's a git repo). The target file is `docs/to-dos/todo.md` relative to that root.

3. **Create the file if it doesn't exist.** If `docs/to-dos/todo.md` is missing, create it with a single header line:
   ```
   # To-Dos
   ```

4. **Append the entry.** Add a blank line (if the file is non-empty) followed by:
   ```
   - **YYYY-MM-DD HH:MM** — <user's text verbatim>
   ```
   Use `>>` shell append — do not rewrite the whole file.

5. **Confirm.** Reply with one line: the entry as it was written. Nothing else.

## Rules

- Capture the user's text **verbatim** — no rewording, summarizing, or cleaning up.
- The timestamp is always local machine time from `date`, not the session date from context.
- If `docs/to-dos/` doesn't exist, create it before writing.
- Never open or display the whole file; just confirm the single appended entry.
