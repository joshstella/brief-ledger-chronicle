#!/usr/bin/env bash
# notify.sh — where a notification can land on this machine, and what survives WSL2.
#
#   notify.sh --probe            report every transport and whether it is available here
#   notify.sh --send <text>      send on the first transport that works
#   notify.sh --send --transport bell|osc9|osc777|notify-send|tty|windows|none <text>
#
# Every transport here is a write to a file descriptor or an exec of a program already
# installed. None of them is a service.
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
is_wsl() { [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; }

# A terminal that will accept an escape sequence. stderr first: stdout may be a pipe, and the
# whole point of a notification is that it reaches the person, not the pipeline.
tty_fd() {
  if [ -t 2 ]; then printf '2'
  elif [ -t 1 ]; then printf '1'
  else printf ''
  fi
}

# Availability is tested, not inferred from PATH. `powershell.exe` is on PATH inside WSL2 and
# $WSL_INTEROP is set even in a context where the interop socket cannot be reached, so the
# presence of the binary proves nothing. Same for notify-send: libnotify installed with no
# notification daemon on the session bus fails at the first send.
interop_works() {
  is_wsl && have powershell.exe &&
    timeout 10 powershell.exe -NoProfile -Command exit >/dev/null 2>&1
}
notifyd_works() {
  have notify-send && have gdbus &&
    timeout 5 gdbus call --session --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1
}

probe() {
  local fd; fd="$(tty_fd)"
  printf '%-14s %-9s %s\n' transport available note
  printf '%-14s %-9s %s\n' bell "$([ -n "$fd" ] && echo yes || echo no)" \
    'BEL on the controlling terminal; silent if the terminal has the bell off'
  printf '%-14s %-9s %s\n' osc9 "$([ -n "$fd" ] && echo yes || echo no)" \
    'ESC ]9;text BEL — Windows Terminal and iTerm2 honour it; xterm ignores it'
  printf '%-14s %-9s %s\n' osc777 "$([ -n "$fd" ] && echo yes || echo no)" \
    'ESC ]777;notify;title;body BEL — urxvt and some VTE builds'
  printf '%-14s %-9s %s\n' notify-send "$(notifyd_works && echo yes || echo no)" \
    'needs libnotify and a notification daemon answering on the session bus'
  printf '%-14s %-9s %s\n' tty "$([ -n "${BLIC_TTY:-}" ] && echo yes || echo 'set BLIC_TTY')" \
    'write to another terminal, so the watcher can be headless'
  printf '%-14s %-9s %s\n' windows "$(interop_works && echo yes || echo no)" \
    'WSL interop: a Windows toast through powershell.exe, about a second a call'
  printf '\nterminal: TERM=%s tty=%s wsl=%s dbus=%s\n' \
    "${TERM:-unset}" "$(tty 2>/dev/null | grep -v 'not a tty' || echo none)" \
    "$(is_wsl && echo yes || echo no)" \
    "${DBUS_SESSION_BUS_ADDRESS:-unset}"
}

pick() {
  if [ -n "${BLIC_TTY:-}" ] && [ -w "${BLIC_TTY:-}" ]; then printf 'tty'
  elif notifyd_works; then printf 'notify-send'
  elif [ -n "$(tty_fd)" ]; then printf 'osc9'
  else printf 'none'
  fi
}

send() {
  local t="$1" text="$2" fd
  [ "$t" = auto ] && t="$(pick)"
  fd="$(tty_fd)"
  case "$t" in
    none) return 0 ;;
    bell)   [ -n "$fd" ] && printf '\a' >&"$fd" ;;
    osc9)   [ -n "$fd" ] && printf '\033]9;%s\a' "$text" >&"$fd" ;;
    osc777) [ -n "$fd" ] && printf '\033]777;notify;blic;%s\a' "$text" >&"$fd" ;;
    notify-send) notify-send -a blic "blic" "$text" 2>/dev/null || return 1 ;;
    tty)    [ -n "${BLIC_TTY:-}" ] && printf '%s\n' "$text" > "$BLIC_TTY" ;;
    windows)
      # Interop costs about a second per call, which is why it is never the default.
      powershell.exe -NoProfile -Command \
        "[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); \
         \$n=New-Object System.Windows.Forms.NotifyIcon; \
         \$n.Icon=[System.Drawing.SystemIcons]::Information; \$n.Visible=\$true; \
         \$n.ShowBalloonTip(4000,'blic','$text',[System.Windows.Forms.ToolTipIcon]::Info); \
         Start-Sleep -Seconds 4" >/dev/null 2>&1 || return 1 ;;
    *) echo "notify: unknown transport: $t" >&2; return 2 ;;
  esac
  return 0
}

case "${1:---probe}" in
  --probe) probe ;;
  --pick) pick; echo ;;
  --send)
    shift
    t=auto
    [ "${1:-}" = "--transport" ] && { t="$2"; shift 2; }
    send "$t" "$*" ;;
  *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
