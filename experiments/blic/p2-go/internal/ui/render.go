package ui

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"
)

// seg is a run of text with one style. Rows are built from segments so truncation can be
// measured on the plain text: styling a string first and cutting it afterwards cuts ANSI.
type seg struct {
	s  string
	st lipgloss.Style
}

func plain(segs []seg) string {
	var b strings.Builder
	for _, g := range segs {
		b.WriteString(g.s)
	}
	return b.String()
}

// renderRow styles the segments and pads or truncates to width on the plain text.
func renderRow(segs []seg, width int) string {
	if width <= 0 {
		return ""
	}
	var out strings.Builder
	used := 0
	for _, g := range segs {
		if used >= width {
			break
		}
		s := g.s
		if used+len([]rune(s)) > width {
			r := []rune(s)
			s = string(r[:width-used])
		}
		used += len([]rune(s))
		out.WriteString(g.st.Render(s))
	}
	if used < width {
		out.WriteString(strings.Repeat(" ", width-used))
	}
	return out.String()
}

func trunc(s string, n int) string {
	r := []rune(s)
	if n <= 1 || len(r) <= n {
		return s
	}
	return string(r[:n-1]) + "…"
}

func pad(s string, n int) string {
	r := []rune(s)
	if len(r) >= n {
		return string(r[:n])
	}
	return s + strings.Repeat(" ", n-len(r))
}

// ago renders an RFC3339 timestamp as an age. The record carries three timestamp shapes
// across three years of conventions, so an unparseable one is shown as itself rather than
// as a wrong age.
func ago(ts string, now time.Time) string {
	t, ok := parseTime(ts)
	if !ok {
		if ts == "" {
			return "—"
		}
		return ts
	}
	d := now.Sub(t)
	switch {
	case d < 0:
		return "just now"
	case d < time.Minute:
		return fmt.Sprintf("%ds ago", int(d.Seconds()))
	case d < time.Hour:
		return fmt.Sprintf("%dm ago", int(d.Minutes()))
	case d < 48*time.Hour:
		return fmt.Sprintf("%dh ago", int(d.Hours()))
	default:
		return fmt.Sprintf("%dd ago", int(d.Hours()/24))
	}
}

func parseTime(ts string) (time.Time, bool) {
	for _, layout := range []string{time.RFC3339, "2006-01-02T15:04:05Z0700", "2006-01-02"} {
		if t, err := time.Parse(layout, ts); err == nil {
			return t, true
		}
	}
	return time.Time{}, false
}

func clock(ts string) string {
	if t, ok := parseTime(ts); ok {
		return t.Local().Format("15:04")
	}
	return "  —  "
}

// pane frames a body in a bordered box of exactly w×h cells, title included.
func pane(title string, focused bool, body []string, w, h int) string {
	inner := w - 2
	innerH := h - 2
	if inner < 4 || innerH < 2 {
		return ""
	}
	lines := make([]string, 0, innerH)
	lines = append(lines, renderRow([]seg{{title, styTitle}}, inner))
	for i := 0; i < innerH-1; i++ {
		if i < len(body) {
			lines = append(lines, body[i])
		} else {
			lines = append(lines, strings.Repeat(" ", inner))
		}
	}
	return paneBorder(focused).Render(strings.Join(lines, "\n"))
}

// scrollWindow returns the slice of lines visible for a cursor and a height, keeping the
// cursor in view.
func scrollWindow(n, cursor, height int) (start, end int) {
	if height <= 0 || n == 0 {
		return 0, 0
	}
	start = 0
	if cursor >= height {
		start = cursor - height + 1
	}
	if start+height > n {
		start = n - height
	}
	if start < 0 {
		start = 0
	}
	end = start + height
	if end > n {
		end = n
	}
	return start, end
}
