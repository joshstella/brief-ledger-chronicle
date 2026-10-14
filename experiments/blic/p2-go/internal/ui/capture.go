package ui

import (
	"context"
	"fmt"
	"io"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/termenv"

	"blic/p2go/internal/record"
)

// Capture drives the model without a terminal and writes plain text frames.
//
// It exists for two reasons. The bake-off asks for a plain-text capture of a session, and a
// full-screen TUI cannot be piped to a file. And a console with no way to render a frame
// without a tty has no way to be tested either, so this is also what the tests drive.
func Capture(w io.Writer, o Options, script string, width, height int) error {
	lipgloss.SetColorProfile(termenv.Ascii) // no escape codes: the capture must read as text

	o.PeerNote = "peer injected (capture)"
	m := New(o)
	m.width, m.height = width, height
	m.now = time.Now()

	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()
	snap, dur, err := o.Reader.Snapshot(ctx)
	if err != nil {
		return err
	}
	model, _ := m.Update(snapshotMsg{snap: snap, dur: dur})
	m = model.(Model)

	frame := func(caption string) {
		fmt.Fprintf(w, "\n=== %s %s\n", caption, strings.Repeat("=", max(0, 72-len(caption))))
		fmt.Fprintln(w, m.View())
	}

	frame("on open: mine and in flight")

	for _, step := range strings.Split(script, ",") {
		step = strings.TrimSpace(step)
		if step == "" {
			continue
		}
		if ev, ok := strings.CutPrefix(step, "peer:"); ok {
			e, err := peerSample(o.Reader, ev)
			if err != nil {
				return err
			}
			model, _ := m.Update(peerMsg{e})
			m = model.(Model)
			frame("a peer event arrives (" + e.Kind + ")")
			continue
		}
		model, _ := m.Update(keyMsg(step))
		m = model.(Model)
		frame("key: " + step)
	}
	return nil
}

// peerSample pulls one event out of `peer-events.sh` by index, so a capture can show the
// feed reacting without waiting out the stream's interval.
func peerSample(rd *record.Reader, which string) (record.Event, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	evs, err := record.PeerOnce(ctx, rd)
	if err != nil {
		return record.Event{}, err
	}
	idx := 0
	fmt.Sscanf(which, "%d", &idx)
	if idx < 0 || idx >= len(evs) {
		return record.Event{}, fmt.Errorf("peer-events.sh has no event %d", idx)
	}
	return evs[idx], nil
}

func keyMsg(s string) tea.KeyMsg {
	switch s {
	case "tab":
		return tea.KeyMsg{Type: tea.KeyTab}
	case "shift+tab":
		return tea.KeyMsg{Type: tea.KeyShiftTab}
	case "enter":
		return tea.KeyMsg{Type: tea.KeyEnter}
	case "esc":
		return tea.KeyMsg{Type: tea.KeyEsc}
	case "down":
		return tea.KeyMsg{Type: tea.KeyDown}
	case "up":
		return tea.KeyMsg{Type: tea.KeyUp}
	case "ctrl+d":
		return tea.KeyMsg{Type: tea.KeyCtrlD}
	case "ctrl+u":
		return tea.KeyMsg{Type: tea.KeyCtrlU}
	default:
		return tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune(s)}
	}
}
