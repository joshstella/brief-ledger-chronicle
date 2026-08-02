---
name: installer-builder
description: Package a set of files into a .tgz with a safe, self-installing shell script that mirrors a destination tree and copies each file to the right place. Use whenever the user wants to "make an installer", "package this for install", "create a tgz/installer", "make these files installable", "bundle this so it drops into ~/.cursor/skills (or ~/.config, or a project dir)", "create a self-installing archive", or distribute a skill/command/dotfile set to other machines. Trigger even if they just say "package these up" or "make this easy to install somewhere".
---

# Installer builder

Produce a distributable `<name>.tgz` containing a generated `install.sh`, a `README.md`,
and a `payload/` directory that **mirrors the install destination**. Installing is then a
generic walk-and-copy: each file under `payload/<rel>` lands at `<dest>/<rel>`. The
generated installer backs up anything it would overwrite, restores executable bits, and
never touches user-data files.

Two bundled assets do the parts that must be identical every time:
`assets/install.sh.template` (the installer's proven logic) and `scripts/verify.sh` (the
extract-and-install check). The per-package assembly is judgment and lives here in prose.

## Inputs to gather

From the conversation or by asking:

1. **What to package**, and the **destination path** each file/dir maps to.
2. **Destination root** + the **override env var** (e.g. `~/.cursor/skills` with `CURSOR_SKILLS_HOME`;
   `~/.config/app` with `APP_HOME`; a project dir).
3. **User-data files to protect** — configs/identity the installer must never create or
   overwrite (it only notes if absent). Often none.
4. **Executable globs** — which installed files get `chmod +x` (default `*.sh`).
5. **Package name** (names the archive, the install banner, and the backup dir).

## Method

1. **Stage `payload/` to mirror the destination.** For each input, place it at
   `payload/<relative-dest-path>`. The payload *is* the destination overlay — its shape is
   exactly what will appear under the destination root. Do **not** put user-data files in
   the payload (they would be installed and could overwrite the user's own); protect them
   via `DATA_FILES` instead.
2. **Generate `install.sh` from the template.** Copy `assets/install.sh.template` to the
   package root as `install.sh` and edit **only the CONFIG block** (between the
   `─── CONFIG` and `─── END CONFIG` markers): set `PKG_NAME`, `DEST_ENV`, `DEST_DEFAULT`,
   `DATA_FILES`, `EXEC_GLOBS`. Leave the logic below the marker untouched — it is proven;
   re-deriving it risks the safety behavior.
3. **Write `README.md`** — what it installs (show the payload tree), how to install, the
   backup/safety guarantees, and any per-package notes about protected data files.
4. `chmod +x install.sh`.
5. **Archive**: `tar -czf <name>.tgz` the package directory (top-level dir named for the
   package, containing `install.sh`, `README.md`, `payload/`).
6. **Verify**: run `scripts/verify.sh <name>.tgz`. It extracts into a temp dir, installs
   with a temp destination, and checks every payload file landed and every `*.sh` is
   executable. **Never present an installer that hasn't passed this.**
7. **Present** the `.tgz`.

## CONFIG block — example (the brief-workflow installer)

```
PKG_NAME="brief-workflow"
DEST_ENV="CURSOR_SKILLS_HOME"
DEST_DEFAULT="$HOME/.cursor/skills"
DATA_FILES=("briefs.json")
EXEC_GLOBS=("*.sh")
```

## Why the installer is shaped this way

- **Mirror payload → generic install.** Adding a file later needs no installer code change
  — drop it in the right `payload/` subdir.
- **Backup-on-overwrite.** Re-running is safe; a user's local edits to an installed file go
  to a timestamped backup dir rather than being lost.
- **Exec-bit restoration.** A download or move drops the executable bit; the installer
  re-sets it for the declared globs.
- **Data-file protection.** Configs and identity files are the user's; the installer never
  creates or clobbers them, only notes their absence.
- **Self-locating + destination override.** Works wherever it's extracted and can install
  anywhere via the env var.

## Rules

- Never present an installer you have not run `scripts/verify.sh` against.
- Edit only the template's CONFIG block; never rewrite the logic below it.
- Keep user-data files out of `payload/`; declare them in `DATA_FILES` instead.
- The payload mirrors the destination exactly — no extra wrapper directories.
