package ui

import (
	"fmt"
	"io"
	"regexp"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// Session runs the real Bubble Tea program against a scripted input stream and a plain
// writer, with no terminal.
//
// This exists because the machine that built this prototype has no pty: `script` cannot open
// one, and the program refuses to start on /dev/tty. Capture renders frames by calling Update
// and View directly, which proves the views but not the loop. Session proves the loop — the
// commands, the tickers, the peer subprocess and the key decoder all run — and is the honest
// answer to "did this ever actually run".
func Session(out io.Writer, o Options, keys string, width, height int, hold time.Duration) error {
	pr, pw := io.Pipe()
	var frames strings.Builder

	p := tea.NewProgram(New(o),
		tea.WithInput(pr),
		tea.WithOutput(&frames),
		tea.WithoutSignals(),
		tea.WithoutSignalHandler(),
	)

	go func() {
		// Bubble Tea learns the window size from the terminal, and there is no terminal.
		time.Sleep(200 * time.Millisecond)
		p.Send(tea.WindowSizeMsg{Width: width, Height: height})
		for _, k := range strings.Split(keys, ",") {
			time.Sleep(hold)
			_, _ = pw.Write([]byte(keyBytes(strings.TrimSpace(k))))
		}
		time.Sleep(hold)
		_, _ = pw.Write([]byte("q"))
		time.Sleep(time.Second)
		_ = pw.Close()
	}()

	if _, err := p.Run(); err != nil {
		return err
	}

	raw := frames.String()
	fmt.Fprintf(out, "the program ran for real: %d bytes of frames written, quit cleanly on q\n\n", len(raw))
	fmt.Fprintln(out, strings.TrimRight(lastFrame(raw), " \n"))
	return nil
}

// keyBytes is the wire form of the keys the script names.
func keyBytes(k string) string {
	switch k {
	case "tab":
		return "\t"
	case "enter":
		return "\r"
	case "esc":
		return "\x1b"
	case "down":
		return "\x1b[B"
	case "up":
		return "\x1b[A"
	default:
		return k
	}
}

var ansiRE = regexp.MustCompile(`\x1b\[[0-9;?]*[a-zA-Z]|\x1b[()][B0]|\x1b[=>]|\r`)

// lastFrame strips the escape sequences and returns the tail of the output, which for the
// standard renderer is the most recent full repaint. It is a best effort on purpose: the
// readable record of a session is the capture frames, and this is the proof of life.
func lastFrame(raw string) string {
	clean := ansiRE.ReplaceAllString(raw, "")
	lines := strings.Split(clean, "\n")
	// Find the last header line and take everything after it: that is one screen.
	for i := len(lines) - 1; i >= 0; i-- {
		if strings.Contains(lines[i], "BLIC ") {
			return strings.Join(lines[i:], "\n")
		}
	}
	return clean
}
